# frozen_string_literal: true

require 'el/core_ext/hash'
require 'el/constants'

require_relative 'request_not_found'
require_relative 'route'

module El
  # A routing table--collects routes, and matches them against a given Rack environment.
  #
  # @api private
  # @todo Add header matching
  class Routes
    include Enumerable

    # Build routes declaratively from a hash.
    #
    # @example
    #   Routes[
    #     [:get,    '/']          => [MainController,  :index],
    #     [:get,    '/users']     => [UsersController, :index],
    #     [:post,   '/users']     => [UsersController, :create],
    #     [:get,    '/users/:id'] => [UsersController, :show],
    #     [:post,   '/users/:id'] => [UsersController, :update],
    #     [:delete, '/users/:id'] => [UsersController, :remove]
    #   ]
    #
    # @return [Routes]
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
      @aliases = {}
      block.call(self) if block_given?
    end

    def freeze
      @table.freeze
      @table.each_value(&:freeze)
      @routes.freeze
      @routes.each(&:freeze)
      @aliases.freeze
      self
    end

    def size
      @routes.size
    end

    def to_a
      @routes.dup
    end

    # Find routes by method, path, alias or numerical index
    #
    # @param first [String, Integer, Symbol] a path, method, alias or number
    # @param second [String, nil] a path if a method is specified
    #
    # @return [Route, Array<Route>]
    def [](first, second = nil)
      if first.is_a?(Integer)
        @routes[first]
      elsif second
        fetch(first, second)
      elsif first.is_a?(Symbol)
        route(first)
      else
        match_path(first.to_s)
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
      @aliases.merge!(other.instance_variable_get(:@aliases))

      self
    end

    def merge(other)
      dup.merge!(other)
    end

    def list
      map { |r| [r.method, r.path, r.route_alias] }
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
      @aliases[route.route_alias] = route

      self
    end

    def alias?(name)
      @alias.key?(name)
    end

    def alias!(name)
      @aliases.fetch(name) do
        raise "unknown alias `#{name}`, valid aliases: #{aliases.keys.join(", ")}"
      end
    end

    def route(name, alt = nil)
      @aliases.fetch(name, alt)
    end

    def aliases
      @aliases.keys
    end

    def fetch(method, path)
      _match(parsed_request(Rack::MockRequest.env_for(path, method: method)))
    end

    def match_path(path)
      scope = _match(parsed_path(path), splat_methods: true)
      return EMPTY_ARRAY unless scope

      flatten_nested_routes(scope)
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
      _match(parsed_request(env), env)
    end

    private

    def flatten_nested_routes(scope)
      scope.values.flat_map do |value|
        if value.is_a?(Route)
          value
        else
          flatten_nested_routes(value)
        end
      end
    end

    def parsed_request(env)
      method, path = env.values_at('REQUEST_METHOD', 'PATH_INFO')
      parsed_path(path) << method
    end

    def parsed_path(path)
      path = path.start_with?('/') ? path[1, path.size] : path
      path.split(%r{/+})
    end

    def _match(parts, env = nil, splat_methods: false)
      scope  = @table
      prev   = nil
      values = []

      i = 0
      loop do
        break if scope.nil?

        part  = parts[i]
        prev  = scope
        scope = scope[part]

        i += 1

        if scope.is_a?(Route)
          params = {}
          scope.parsed_path[:names].each_with_index do |name, j|
            next unless name

            params[name] = values[j]
          end

          return scope unless env

          return Request.new(env, scope, route_params: params)
        end

        next unless scope.nil?

        prev.each_key do |pattern|
          next if pattern.is_a?(String)

          if pattern === part
            scope = prev[pattern]
            values[i - 1] = part
          end
        end
      end

      return prev if splat_methods
      return unless env

      RequestNotFound.new(env)
    end
  end
end