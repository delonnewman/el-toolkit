# frozen_string_literal: true

module El
  module Routable
    class Request < Hash
      def initialize(env, match_params)
        super()

        read_env!(env, match_params)

        freeze
      end

      def media_params
        Rack::MediaType.params(content_type)
      end

      def media_type
        Rack::MediaType.type(content_type)
      end

      %i[method path params content_type body script_name server_name server_port].each do |method|
        define_method method do
          fetch(method, nil)
        end
      end

      private

      def read_env!(env, match_params)
        store(:method, env["REQUEST_METHOD"].downcase.to_sym)
        store(:path, env["PATH_INFO"])
        store(:params, parse_params(env, match_params))
        store(:content_type, env["CONTENT_TYPE"])
        store(:body, env["rack.input"])
        store(:script_name, env["SCRIPT_NAME"])
        store(:server_name, env["SERVER_NAME"])
        store(:server_port, env["SERVER_PORT"])
      end

      def parse_params(env, match_params)
        params = HTTPUtils.parse_form_encoded_data(@env["QUERY_STRING"])

        if env["REQUEST_METHOD"] == "POST" && FORM_DATA_MEDIA_TYPES.include?(media_type)
          env["rack.input"].tap do |body|
            params.merge!(HTTPUtils.parse_form_encoded_data(body.read))
            body.rewind
          end
        end

        params.merge!(match_params) if @match_params

        params.freeze
      end
    end
  end
end
