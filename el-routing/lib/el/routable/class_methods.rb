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

      # A "macro" method for specifying the root_path of the application.
      # If called as a class method it will return the value that will be used
      # when instantiating.
      #
      # @param dir [String]
      # @return [String, nil]
      def root_path(dir = nil)
        @root_path = dir unless dir.nil?
        @root_path || Dir.pwd
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
      def route(method, path, proc = nil, **options, &block)
        raise "Invalid method: #{method.inspect}" unless METHODS.include?(method)

        routes.add!(method, path, proc || block, options)
      end

      METHODS.each do |method|
        define_method method do |path, proc = nil, **options, &block|
          route(method, path, proc, **options, &block)
        end
      end
    end
  end
end
