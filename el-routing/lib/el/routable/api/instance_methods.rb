# frozen_string_literal: true

module El
  module Routable
    module API
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
              use middle
            end
            run routable
          end
        end

        def request_evaluator
          @request_evaluator ||= RequestEvaluator.new(self)
        end

        # Satisfy the Rack application interface
        #
        # @param env [Hash] the rack environment
        #
        # @todo add error and not_found to the DSL
        #
        # @return [Array(Integer, Hash{String, Object}, #each)]
        def call(env)
          request = routes.match(env)

          return not_found unless request

          request_evaluator.evaluate(request)
        rescue StandardError => e
          request.errors.write(e.message)
          error(e)

          raise e unless rack_env == :production
        end
      end
    end
  end
end
