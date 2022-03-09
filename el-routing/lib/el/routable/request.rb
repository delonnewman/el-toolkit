# frozen_string_literal: true

module El
  module Routable
    class Request
      def initialize(env)
        @env = env
      end

      def request_method
        @env['REQUEST_METHOD'].downcase.to_sym
      end

      def path
        @env['PATH_INFO']
      end

      def content_type
        @env['CONTENT_TYPE']
      end

      def body
        @env['rack.input']
      end

      def script_name
        @env['SCRIPT_NAME']
      end

      def server_name
        @env['SERVER_NAME']
      end

      def server_port
        @env['SERVER_PORT']
      end

      def [](key)
        key = key.name.upcase if key.is_a?(Symbol)
        @env[key]
      end

      def to_h
        @env.dup.freeze
      end

      def media_params
        Rack::MediaType.params(content_type)
      end

      def media_type
        Rack::MediaType.type(content_type)
      end

      def query_params
        @query_params ||= HTTPUtils.parse_form_encoded_data(@env['QUERY_STRING'])
      end

      def body_params
        return @body_params if @body_params

        return EMPTY_HASH unless env['REQUEST_METHOD'] == 'POST' && FORM_DATA_MEDIA_TYPES.include?(media_type)

        body.tap do |body|
          @body_params = HTTPUtils.parse_form_encoded_data(body.read)
          body.rewind
        end

        @body_params
      end
    end
  end
end
