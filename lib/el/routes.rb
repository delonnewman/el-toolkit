# frozen_string_literal: true

require_relative 'core_ext/hash'
require_relative 'core_ext/symbol'
require_relative 'constants'

require_relative 'route_helpers'
require_relative 'route_data'

module El
  # A routing table--collects routes, and matches them against a given Rack environment.
  #
  # @todo Add header matching
  class Routes
    include Enumerable

    # Build routes declaratively from a hash.
    #
    # @param map [Hash{Array<(Symbol, String, Hash)>, Array<(Symbol, String)> => Array<(Class<#call>, Symbol)>, #call}]
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
          r << RouteData.new(method, path, action, options || EMPTY_HASH)
        end
      end
    end

    def initialize
      @table = {}
      @routes = []
      @aliases = {}
      yield self if block_given?
    end

    def freeze
      @table.freeze
      @table.each_value(&:freeze)
      @routes.freeze
      @routes.each(&:freeze)
      @aliases.freeze
      self
    end

    # @return [RouteHelpers]
    def helpers
      @helpers ||= RouteHelpers.new(self)
    end

    def include_helpers!(base_url)
      helpers.generate_methods!(base_url)
      extend(helpers)
    end

    def size
      @routes.size
    end

    def to_a
      @routes.dup
    end

    def to_h
      @routes.reduce({}) do |h, r|
        h.merge!([r.method, r.path] => r.action)
      end
    end

    def inspect
      "El::Routes[#{to_h.inspect}]"
    end

    # Find routes by method, path, alias or numerical index
    #
    # @param first [String, Integer, Symbol] a path, method, alias or number
    # @param second [String, nil] a path if a method is specified
    #
    # @example
    #   routes[1] # returns second route
    #   # returns all routes that match
    #   routes[:get]
    #   routes[:post]
    #   routes[:get, '/users/1']
    #   routes[:get, '/users/1']
    #   routes['/users/1']
    #
    # @return [RouteData, Array<RouteData>]
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
    # @yield [RouteData]
    #
    # @return [Routes] this object
    def each_route(&block)
      @routes.each(&block)
      self
    end
    alias each each_route

    # Merge routing tables into one
    def merge!(other)
      raise TypeError, "no implicit conversion of #{other.class} to #{self.class}" unless other.is_a?(self.class)

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
    # @param route [RouteData]
    #
    # @return [Routes] this object
    def <<(route)
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
    # @return [Request, Array<Request>, nil]
    def match(env)
      _match(parsed_request(env), env)
    end

    private

    def flatten_nested_routes(scope)
      scope.values.flat_map do |value|
        if value.is_a?(RouteData)
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

    # @param parts [Array<String>]
    # @param env [Hash, nil]
    # @param splat_methods [Boolean]
    #
    # @return [Request, Array<RouteData>, nil]
    def _match(parts, env = nil, splat_methods: false)
      scope  = @table
      prev   = nil
      values = []

      i = 0
      loop do
        break if scope.nil?

        part  = parts[i]
        prev  = scope

        i += 1

        if scope.is_a?(RouteData)
          params = {}
          scope.parsed_path[:names].each_with_index do |name, j|
            next unless name

            params[name] = URI.decode_www_form_component(values[j])
          end

          return scope unless env

          return Request.new(env, scope, route_params: params)
        else
          scope = scope[part]
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

      nil
    end
  end
end
