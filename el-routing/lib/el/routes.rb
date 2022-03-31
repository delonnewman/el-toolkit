# frozen_string_literal: true

require 'el/core_ext/hash'
require_relative 'request_not_found'

module El
  # A routing table--collects routes, and matches them against a given Rack environment.
  #
  # @api private
  # @todo Add header matching
  class Routes
    include Enumerable

    def self.[](map)
      new do |r|
        map.each_pair do |(method, path, options), action|
          r << Route.new(method, path, action, options || EMPTY_HASH)
        end
      end
    end

    def initialize(&block)
      @table = {}
      @routes = []
      @helpers = {}
      block.call(self) if block_given?
    end

    def freeze
      @table.freeze
      @table.each_value(&:freeze)
      @routes.freeze
      @routes.each(&:freeze)
      @helpers.freeze
      self
    end

    def size
      @routes.size
    end

    def to_a
      @routes.dup
    end

    def [](index, path = nil)
      if path
        fetch(index, path)
      elsif index.is_a?(String)
        raise NotImplementedError, 'will support listing all routes matching the given path'
      else
        @routes[index]
      end
    end

    # Iterate over each route in the routes table passing it's information along
    # to the given block.
    #
    # @yield [Route]
    #
    # @return [Routes] this object
    def each_route(&block)
      @routes.each(&block)
      self
    end
    alias each each_route

    # Merge routing tables into one
    def merge!(other)
      @routes += other.instance_variable_get(:@routes)
      @table.deep_merge!(other.instance_variable_get(:@table))
      @helpers.merge!(other.instance_variable_get(:@helpers))

      self
    end

    def merge(other)
      dup.merge!(other)
    end

    # Add a route to the table.
    #
    # @param Route [Route]
    #
    # @return [Routes] this object
    def <<(route)
      # TODO: Add Symbol#name for older versions of Ruby
      method = route.method.name.upcase
      scope = route.parsed_path[:path].reduce(@table) do |tree, part|
        tree[part] ||= {}
      end

      scope[method] = route
      @routes << route

      define_path_helper!(route)
      define_url_helper!(route)

      self
    end

    def define_helper(name, &block)
      @helpers[name] = block
      name
    end

    def helper?(name)
      @helpers.key?(name)
    end

    def helper!(name)
      @helpers.fetch(name) do
        raise "unknown helper `#{name}`, valid helpers: #{helpers.keys.join(", ")}"
      end
    end

    def helper(name, alt = nil)
      @helpers.fetch(name, alt)
    end

    def helpers
      @helpers.keys
    end

    private

    def define_path_helper!(route)
      define_helper route.path_method_name.to_sym do |*args|
        route.route_path(*args)
      end
    end

    def define_url_helper!(route)
      define_helper route.url_method_name.to_sym do |*args|
        route.route_url(*args)
      end
    end

    public

    def fetch(method, path)
      match(Rack::MockRequest.env_for(path, method: method))
    end

    # Match a route in the table to the given Rack environment.
    #
    # @param env [Hash]
    #
    # @return [[Route, Hash]] the route and it's params or an empty array
    # @api private

    # rubocop: disable Metrics/CyclomaticComplexity
    # rubocop: disable Metrics/AbcSize
    # rubocop: disable Metrics/PerceivedComplexity
    def match(env)
      method, path = env.values_at('REQUEST_METHOD', 'PATH_INFO')
      path  = path.start_with?('/') ? path[1, path.size] : path
      parts = path.split(%r{/+}) << method

      scope  = @table
      prev   = nil
      values = []

      i = 0
      until scope.nil?
        if scope.is_a?(Route)
          params = {}
          scope.parsed_path[:names].each_with_index do |name, j|
            next unless name

            params[name] = values[j]
          end

          return Request.new(env, scope, route_params: params)
        end

        part = parts[i]
        prev  = scope
        scope = scope[part]

        i += 1
        next unless scope.nil?

        prev.each_key do |pattern|
          next if pattern.is_a?(String)

          if pattern === part
            scope = prev[pattern]
            values[i - 1] = part
          end
        end
      end

      RequestNotFound.new(env)
    end
  end
end
