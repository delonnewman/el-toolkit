# frozen_string_literal: true

module El
  module Routable
    # Class methods for the Rack::Routable module
    module ClassMethods
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

      # A "macro" method to specify a namespace or prefix for all the specified routers.
      # If no path is specified the namespace will be returned.
      #
      # @param path [String, nil] the namespace path
      #
      # @returns [String, nil] the namespace or nil
      def namespace(path = nil)
        return @namespace unless path

        @namespace = path
      end

      # Valid methods for routes
      METHODS = %i[get post delete put head link unlink].to_set.freeze

      # Return the routing table for the class.
      #
      # @return [Routes]
      def routes
        @routes ||= Routes.new
      end

      # A "macro" method for defining a route for the application.
      #
      # @param method [:get, :post, :delete :put, :head, :link :unlink]
      def route(request_method, path, controller = nil, method = nil, **options, &block)
        raise "Invalid method: #{request_method.inspect}" unless METHODS.include?(request_method)

        action = block_given? ? block : resolve_action(controller, method)
        raise 'An action is required for a route' unless action

        path = namespace ? File.join(namespace, path) : path
        routes << Route.new(request_method, path, action, options)
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
    end
  end
end
