# frozen_string_literal: true

require "el/http_utils"

module El
  module Routable
    # Instance methods for El::Routable module
    module InstanceMethods
      attr_reader :env, :route, :route_params, :request

      # The default headers for responses
      DEFAULT_HEADERS = {
        "Content-Type" => "text/html"
      }.freeze

      # The set of form-data media-types. Requests that do not indicate
      # one of the media types present in this list will not be eligible
      # for form-data / param parsing.
      FORM_DATA_MEDIA_TYPES = [
        "application/x-www-form-urlencoded",
        "multipart/form-data"
      ].freeze

      def initialize(env)
        @route, @route_params = self.class.routes.match(env)
        @request = Request.new(env, match_params)
      end

      def body_params
        request.body_params
      end

      def query_params
        request.query_params
      end

      def params
        @params ||= route_params.merge(body_params, query_params)
      end

      protected

      # These methods must be used or overridden by the subclass

      def response
        @response ||= Rack::Response.new
      end

      def options
        match[:options] || EMPTY_HASH
      end

      def routes
        self.class.routes
      end

      def escape_html(*args)
        CGI.escapeHTML(*args)
      end
      alias h escape_html

      def rack_env
        ENV.fetch("RACK_ENV", :development).to_sym
      end

      # rubocop:disable Metrics/AbcSize
      def not_found
        io = StringIO.new
        io.puts "<h1>Not Found</h1>"
        io.puts "#{request[:method]} - #{request[:path]}"

        unless rack_env == :production
          io.puts '<div class="routes"><h2>Valid Routes</h2>'
          io.puts "<table>"
          io.puts "<thead><tr><th>Method</th><th>Path</th><th>Router</th></thead>"
          io.puts "<tbody>"
          self.class.routes.each do |route|
            io.puts "<tr><td>#{h route.method}</td><td>#{h route.path}</td><td>#{h route.router.to_s}</td></tr>"
          end
          io.puts "</tbody></table></div>"

          io.puts '<div class="environment"><h2>Environment</h2>'
          io.puts "<table><tbody>"
          env.each do |key, value|
            io.puts "<tr><th>#{h key}</th><td><pre>#{h value.pretty_inspect}</pre></td>"
          end
          io.puts "</tbody></table></div>"
        end

        [404, DEFAULT_HEADERS.dup, [NOT_FOUND_TMPL.sub("%BODY%", io.string)]]
      end

      def error(_)
        [500, DEFAULT_HEADERS.dup, StringIO.new("Server Error")]
      end

      def redirect_to(url)
        Rack::Response.new.tap do |r|
          r.redirect(url)
        end.finish
      end

      public

      # TODO: add error and not_found to the DSL
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def call
        return not_found unless @route

        res = @route.call_action(self)

        if res.is_a?(Array) && res.size == 3 && res[0].is_a?(Integer)
          res
        elsif res.is_a?(Rack::Response)
          res.finish
        elsif res.is_a?(Hash) && res.key?(:status)
          [res[:status], res.fetch(:headers) { DEFAULT_HEADERS.dup }, res.fetch(:body) { EMPTY_ARRAY }]
        elsif res.respond_to?(:each)
          [200, DEFAULT_HEADERS.dup, res]
        else
          [200, DEFAULT_HEADERS.dup, StringIO.new(res.to_s)]
        end
      rescue StandardError => e
        raise e unless rack_env == :production

        env["rack.error"].write(e.message)
        error(e)
      end
    end
  end
end
