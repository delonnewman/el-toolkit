# lib/instance_methods.rb

module El
  module Routable
    module InstanceMethods
      extend Forwardable
      delegate %i[routes middleware media_type_aliases content_type_aliases] => 'self.class'

      # @!method routes
      #   Delegated to the Routable class
      #   @see El::Routable::API::ClassMethods#routes

      # @!method middleware
      #   Delegated to the Routable class
      #   @see El::Routable::API::ClassMethods#middleware

      # @!method media_type_aliases
      #   Delegated to the Routable class
      #   @see El::Routable::API::ClassMethods#media_type_aliases

      # Return a Rack application with any specified middleware mixed in.
      #
      # @return [#call]
      def rack
        routable = self
        Rack::Builder.new do
          middleware.each do |middle|
            klass, args = middle
            use klass, *args
          end
          run routable
        end
      end

      # Satisfy the Rack application interface
      #
      # @param env [Hash] the rack environment
      #
      # @todo add error and not_found to the DSL
      #
      # @return [Array(Integer, Hash{String, Object}, #each)]
      def call(env)
        RackCall.new(env, routes, suppress_errors: rack_env == :production).evaluate(self)
      end

      #
      # DSL Methods
      #

      # Throw a :halt symbol and pass the response as an argument.
      def halt(*response)
        response = response[0] if response.size == 1
        throw :halt, response
      end

      # Return the value of the RACK_ENV environment variable as a symbol.
      # If the environment variable is not set return :development.
      #
      # @return [Symbol]
      def rack_env
        ENV.fetch('RACK_ENV', :development).to_sym
      end

      # Return a not found response
      def not_found
        [404, RequestEvaluator::DEFAULT_HEADERS.dup, StringIO.new('Not Found')]
      end

      # Return an error response
      def error(_)
        [500, RequestEvaluator::DEFAULT_HEADERS.dup, StringIO.new('Server Error')]
      end
    end
  end
end
