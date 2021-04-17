module El
  module Http
    module Helpers
      # Build a response object to return to Rack handler.
      #
      # @param body [Object]
      # @param status [Numeric, Symbol]
      # @param headers [Hash]
      #
      # @return [Rack::Response]
      def response(body, status: 200, headers: EMPTY_HASH)
        Rack::Response.new(body, status, headers)
      end
      alias R response
    end
  end
end
