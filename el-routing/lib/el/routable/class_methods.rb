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

      def namespace(path = nil)
        return @namespace unless path

        @namespace = path
      end

      # Return an array of Rack middleware (used by this application) and their arguments.
      #
      # @return [Array<[Class, Array]>]
      def middleware
        @middleware ||= []
      end

      # Rack interface
      #
      # @param env [Hash]
      # @returns Array<Integer, Hash, #each>
      def call(env)
        new(env).call
      end

      # Rack application
      def rack
        routable = self
        Rack::Builder.new do
          middleware.each do |middle|
            use middle
          end
          run routable
        end
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
        controller = controller.is_a?(Class) ? controller.new : controller
        return controller.method(method) if method

        controller
      end
    end
  end
end
