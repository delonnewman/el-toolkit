# lib/class_methods.rb

module El
  module Routable
    module ClassMethods
      # Return an array of Rack middleware (used by this application) and their arguments.
      #
      # @return [Array<[Class, Array]>]
      def middleware
        @middleware ||= []
      end

      # Return a hash of media type aliases.
      #
      # @return [Hash{Symbol, String}]
      def media_type_aliases
        @media_type_aliases ||= Hash.new { |_, k| k }
      end
      alias content_type_aliases media_type_aliases

      # Return the routing table for the class.
      #
      # @return [Routes]
      def routes
        @routes ||= Routes.new
      end

      # Make internal data structures immutable
      #
      # @return [ClassMethods]
      def freeze
        routes.freeze
        middleware.freeze
        media_type_aliases.freeze
        self
      end

      #
      # DSL Methods
      #

      # A macro method to specify Rack middleware that should be used by this application.
      #
      # @param klass [Class] Rack middleware
      # @param args [Array] arguments for initializing the middleware
      #
      # @return [ClassMethods]
      def use(klass, *args)
        middleware << [klass, args]
        self
      end

      # A macro method to define a media type aliases
      #
      # @param type_alias [Symbol]
      # @param type_values [Array<String>]
      #
      # @return [ClassMethods]
      def media_type(type_alias, *type_values)
        type_values.each do |value|
          media_type_aliases[media_type_aliases[value]] = type_alias
        end
        self
      end
      alias content_type media_type

      # A macro method to specify a namespace or prefix for all the specified routers.
      #
      # @param path [String, nil] the namespace path
      # @param options [Hash] options that will be added to all routes defined within this namespace
      #
      # @return [ClassMethods]
      def namespace(path = nil, **options, &block)
        self.current_namespace = { path: path, options: options }
        return self unless block_given?

        block.call
        self.current_namespace = nil

        self
      end

      private

      attr_accessor :current_namespace

      public

      # @!macro routing_macro
      #   A macro method for defining a route for the application.
      #
      #   @param path [String]
      #   @param controller [#call, Array(Class<#call>, Symbol), nil]
      #   @param method [Symbol]
      #   @param options [Hash]
      #
      #   @yieldparam request [Request] the request that has been made to the server
      #
      #   @return [ClassMethods]

      # @!macro routing_macro
      # @param request_method [:get, :post, :delete :put, :head, :link :unlink]
      def route(request_method, path, controller = nil, method = :call, **options, &block)
        raise "Invalid method: #{request_method.inspect}" unless HTTP_METHODS.include?(request_method)

        action = block_given? ? block : resolve_action(controller, method)
        raise 'An action is required for a route' unless action

        path    = resolve_path(current_namespace, path)
        options = resolve_options(current_namespace, options)

        RouteData.new(request_method, path, action, options).tap do |r|
          routes << r
        end

        self
      end

      # @!method get(path, controller = nil, method = :call, **options, &block)
      #   @!macro routing_macro
      #   Defines a route that responds to "GET" requests

      # @!method post(path, controller = nil, method = :call, **options, &block)
      #   @!macro routing_macro
      #   Defines a route that responds to "POST" requests

      # @!method put(path, controller = nil, method = :call, **options, &block)
      #   @!macro routing_macro
      #   Defines a route that responds to "PUT" requests

      # @!method delete(path, controller = nil, method = :call, **options, &block)
      #   @!macro routing_macro
      #   Defines a route that responds to "DELETE" requests

      # @!method head(path, controller = nil, method = :call, **options, &block)
      #   @!macro routing_macro
      #   Defines a route that responds to "HEAD" requests

      # @!method link(path, controller = nil, method = :call, **options, &block)
      #   @!macro routing_macro
      #   Defines a route that responds to "LINK" requests

      # @!method unlink(path, controller = nil, method = :call, **options, &block)
      #   @!macro routing_macro
      #   Defines a route that responds to "UNLINK" requests

      HTTP_METHODS.each do |method|
        define_method method do |*args, **options, &block|
          route(method, *args, **options, &block)
        end
      end

      private

      def resolve_action(controller, method)
        controller.is_a?(Class) ? [controller, method] : controller
      end

      def resolve_path(namespace, path)
        namespace ? File.join(namespace[:path], path) : path
      end

      def resolve_options(namespace, options)
        namespace ? namespace[:options].merge(options) : options
      end
    end
  end
end
