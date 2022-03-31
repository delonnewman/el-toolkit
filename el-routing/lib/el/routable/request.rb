# frozen_string_literal: true

module El
  module Routable
    class Request
      include Enumerable
      include Rack::Request::Helpers

      attr_reader :route_params, :route

      def initialize(env, route = nil, route_params: nil, params: nil)
        @env = env.dup # take a snapshot of the rack request
        @route = route
        @route_params = route_params
        @params = params
      end

      def with_params(new_params)
        self.class.new(@env, route, params: new_params)
      end

      def include_params(other_params)
        with_params(params.merge(other_params))
      end

      JSON_MEDIA_TYPES = Set[
        'application/json',
        'application/vnd.api+json',
        'application/ld+json',
        'text/json'
      ].freeze

      def json_body(symbolize_names: true, force: false)
        return @json_body if @json_body
        return EMPTY_HASH unless force || request_method == 'POST' && JSON_MEDIA_TYPES.include?(media_type)

        @json_body = JSON.parse(body.read, symbolize_names: symbolize_names).tap do
          body.rewind
        end
      end
      alias json json_body

      def params
        @params ||= route_params.merge(body_params, query_params, json_body)
      end

      def query_params
        @query_params ||= DataUtils.parse_form_encoded_data(@env['QUERY_STRING'])
      end

      # The set of form-data media-types. Requests that do not indicate
      # one of the media types present in this list will not be eligible
      # for form-data / param parsing.
      FORM_DATA_MEDIA_TYPES = Set[
        'application/x-www-form-urlencoded',
        'multipart/form-data'
      ].freeze

      def body_params
        return @body_params if @body_params
        return EMPTY_HASH unless request_method == 'POST' && FORM_DATA_MEDIA_TYPES.include?(media_type)

        body.tap do |body|
          @body_params = DataUtils.parse_form_encoded_data(body.read)
          body.rewind
        end

        @body_params
      end

      def []=(_, _)
        raise 'Mutating parameters is not supported'
      end

      def delete_param(_)
        raise 'Mutating parameters is not supported'
      end

      def update_param(_, _)
        raise 'Mutating parameters is not supported'
      end

      def path_info=(_)
        raise 'Mutating parameters is not supported'
      end

      def to_h
        @env
      end

      def options
        route.options
      end

      def headers
        @env.keys
      end
      alias keys headers

      def each_header(&block)
        to_h.each(&block)
        self
      end
      alias each each_header

      def request_method
        @env['REQUEST_METHOD']
      end

      def session
        @env['rack.session']
      end

      def hijack?
        @env['rack.hijack?']
      end

      def hijack
        @env['rack.hijack']
      end

      def hijack_io
        @env['rack.hijack_io']
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

      def errors
        @env['rack.errors']
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
        get_header(key)
      end

      def get_header(header)
        @env[header]
      end

      def values_at(*keys)
        keys = keys.map! { |k| k.is_a?(Symbol) ? k.name.upcase : k }
        @env.values_at(*keys)
      end

      def get_headers(*headers)
        @env.values_at(*headers)
      end

      def media_params
        Rack::MediaType.params(content_type)
      end

      def media_type
        Rack::MediaType.type(content_type)
      end

      def url_for(path)
        URI.join(base_url, path)
      end
    end
  end
end
