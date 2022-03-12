# frozen_string_literal: true

module El
  module Routable
    # A routing table--collects routes, and matches them against a given Rack environment.
    #
    # @api private
    # @todo Add header matching
    class Routes
      include Enumerable

      def initialize
        @table = {}
        @routes = []
      end

      def freeze
        @table.freeze
        @routes.freeze
        self
      end

      def size
        @routes.size
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

      # Return the names of the route helper methods that are genterated as routes are added.
      #
      # @return [Array<Symbol>]
      def route_helper_methods
        @route_helper_methods ||= []
      end

      # Add a route to the table.
      #
      # @param Route [Route]
      #
      # @return [Routes] this object
      def <<(route)
        # TODO: Add Symbol#name for older versions of Ruby
        method = route.method.name.upcase
        @table[method] ||= []

        @table[method] << route
        @routes << route

        define_path_method!(route)
        define_url_method!(route)

        self
      end

      private

      def define_path_method!(route)
        define_singleton_method route.path_method_name do |*args|
          route.route_path(*args)
        end

        route_helper_methods << route.path_method_name.to_sym
      end

      def define_url_method!(route)
        define_singleton_method route.url_method_name do |*args|
          route.route_url(*args)
        end

        route_helper_methods << route.url_method_name.to_sym
      end

      public

      # Match a route in the table to the given Rack environment.
      #
      # @param request [El::Routable::Request]
      # @param media_type_aliases [Hash]
      #
      # @see El::Routable::DSL.media_type_aliases
      #
      # @return [[Route, Hash]] the route and it's params or an empty array
      # @api private
      def match(request)
        method, path = request.values_at('REQUEST_METHOD', 'PATH_INFO')
        path  = path.start_with?('/') ? path[1, path.size] : path
        parts = path.split(%r{/+})

        return EMPTY_ARRAY unless (routes = @table[method])

        routes.each do |route|
          next unless (params = match_path(parts, route.parsed_path))

          return [route, params]
        end

        EMPTY_ARRAY
      end

      private

      def path_start_with?(path, prefix)
        return true  if path == prefix
        return false if path.size < prefix.size

        res = false
        path.each_with_index do |part, i|
          res = true   if prefix[i] == part
          break        if prefix[i].nil?
          return false if prefix[i] != part
        end

        res
      end

      # rubocop:disable Metrics/MethodLength
      def match_path(path, route)
        return false if path.size != route[:path].size

        pattern = route[:path]
        names   = route[:names]
        params  = {}

        path.each_with_index do |part, i|
          return false unless pattern[i] === part

          if (name = names[i])
            params[name] = part
          end
        end

        params
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
