# frozen_string_literal: true

require 'el/data_utils'

module El
  module Routable
    # Instance methods for the El::Routable module
    module InstanceMethods
      # The default headers for responses
      DEFAULT_HEADERS = {
        'Content-Type' => 'text/html'
      }.freeze

      protected

      def rack_env
        ENV.fetch('RACK_ENV', :development).to_sym
      end

      def not_found
        [404, DEFAULT_HEADERS.dup, StringIO.new('Not Found')]
      end

      def error(_)
        [500, DEFAULT_HEADERS.dup, StringIO.new('Server Error')]
      end

      public

      def halt(*response)
        response = response[0] if response.size == 1
        throw :halt, response
      end

      %i[routes namespace middleware media_type_aliases content_type_aliases].each do |method|
        define_method method do
          self.class.public_send(method)
        end
      end

      def rack
        routable = self
        Rack::Builder.new do
          middleware.each do |middle|
            use middle
          end
          run routable
        end
      end

      # TODO: add error and not_found to the DSL
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      def call(env)
        request = routes.match(env)

        return not_found unless request

        eval_request(request)
      rescue StandardError => e
        request.errors.write(e.message)
        error(e)

        raise e unless rack_env == :production
      end

      def eval_request(request)
        res = catch(:halt) { request.route.call_action(self, request) }

        if (is_array_res = res.is_a?(Array) && res[0].is_a?(Integer)) && res.size == 3
          res
        elsif is_array_res && res.size == 2
          [res[0], DEFAULT_HEADERS.dup, res[2]]
        elsif res.is_a?(Integer)
          [res, DEFAULT_HEADERS.dup, EMPTY_ARRAY]
        elsif res.is_a?(Rack::Response)
          res.finish
        elsif res.is_a?(Hash) && res.key?(:status)
          [res[:status], res.fetch(:headers, DEFAULT_HEADERS.dup), res.fetch(:body, EMPTY_ARRAY)]
        elsif res.respond_to?(:each)
          [200, DEFAULT_HEADERS.dup, res]
        else
          [200, DEFAULT_HEADERS.dup, StringIO.new(res.to_s)]
        end
      end
    end
  end
end
