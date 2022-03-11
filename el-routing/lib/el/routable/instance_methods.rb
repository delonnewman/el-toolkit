# frozen_string_literal: true

require 'el/http_utils'

module El
  module Routable
    # Instance methods for the El::Routable module
    module InstanceMethods
      attr_reader :env, :route, :route_params, :request

      # The default headers for responses
      DEFAULT_HEADERS = {
        'Content-Type' => 'text/html'
      }.freeze

      protected

      def options
        @route&.options || EMPTY_HASH
      end

      def escape_html(*args)
        CGI.escapeHTML(*args)
      end
      alias h escape_html

      def rack_env
        ENV.fetch('RACK_ENV', :development).to_sym
      end

      def not_found
        [404, DEFAULT_HEADERS.dup, StringIO.new('Not Found')]
      end

      def error(_)
        [500, DEFAULT_HEADERS.dup, StringIO.new('Server Error')]
      end

      def redirect_to(url)
        r = Rack::Response.new
        r.redirect(url)

        halt r.finish
      end

      def halt(*response)
        response = response[0] if response.size == 1
        throw :halt, response
      end

      public

      def url_for(path, params = EMPTY_HASH)
        raise 'a request is required to generate a complete url' if request.nil?

        path_for(URI.join(request.base_url, path), params)
      end

      def path_for(path, params = EMPTY_HASH)
        return path if params.empty?

        "#{path}?#{URI.encode_www_form(params)}"
      end

      %i[routes namespace middleware].each do |method|
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

      def response
        @response ||= Rack::Response.new
      end

      def body_params
        request&.body_params
      end

      def query_params
        request&.query_params
      end

      def params
        @params ||= route_params&.merge(body_params, query_params)
      end

      # TODO: add error and not_found to the DSL
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      def call(env)
        @route, @route_params = routes.match(env)
        @request = Request.new(env)

        return not_found unless @route

        res = catch(:halt) { @route.call_action(self) }

        if res.is_a?(Array) && res.size == 3 && res[0].is_a?(Integer)
          res
        elsif res.is_a?(Array) && res.size == 2 && res[0].is_a?(Integer)
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
      rescue StandardError => e
        raise e unless rack_env == :production

        env['rack.error'].write(e.message)
        error(e)
      end
    end
  end
end
