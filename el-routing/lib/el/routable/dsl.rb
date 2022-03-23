# frozen_string_literal: true

module El
  module Routable
    # DSL for the El::Routable module
    module DSL
      # A "macro" method to specify Rack middleware that should be used by this application.
      #
      # @param klass [Class] Rack middleware
      # @param args [Array] arguments for initializing the middleware
      def use(klass, *args)
        middleware << [klass, args]
      end

      # Return an array of Rack middleware (used by this application) and their arguments.
      #
      # @return [Array<[Class, Array]>]
      def middleware
        @middleware ||= []
      end

      def media_type_aliases
        @media_type_aliases ||= Hash.new { |_, k| k }
      end
      alias content_type_aliases media_type_aliases

      def media_type(type_alias, *type_values)
        type_values.each do |value|
          media_type_aliases[media_type_aliases[value]] = type_alias
        end
      end
      alias content_type media_type

      # A "macro" method to specify a namespace or prefix for all the specified routers.
      # If no path is specified the namespace will be returned.
      #
      # @param path [String, nil] the namespace path
      #
      # @returns [String, nil] the namespace or nil
      def namespace(path = nil, **options, &block)
        return @namespace unless path

        @namespace = { path: path, options: options }
        return unless block_given?

        block.call
        @namespace = nil
      end

      # Valid methods for routes
      METHODS = %i[get post delete put head link unlink].to_set.freeze

      # Return the routing table for the class.
      #
      # @return [Routes]
      def routes
        @routes ||= Routes.new
      end

      # Make internal data structures immutable
      #
      # @return [Routable]
      def freeze
        routes.freeze
        middleware.freeze
        media_type_aliases.freeze
        self
      end

      # A "macro" method for defining a route for the application.
      #
      # @param method [:get, :post, :delete :put, :head, :link :unlink]
      def route(request_method, path, controller = nil, method = nil, **options, &block)
        raise "Invalid method: #{request_method.inspect}" unless METHODS.include?(request_method)

        action = block_given? ? block : resolve_action(controller, method)
        raise 'An action is required for a route' unless action

        path    = resolve_path(namespace, path)
        options = resolve_options(namespace, options)

        Route.new(request_method, path, action, options).tap do |r|
          routes << r
        end
      end

      METHODS.each do |method|
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
