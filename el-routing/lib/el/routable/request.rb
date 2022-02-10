# frozen_string_literal: true

module El
  module Routable
    # Subclass of Rack::Request
    class Request < Rack::Request
      def request_method
        params.fetch('routable.http.method') do
          super()
        end.upcase
      end
    end
  end
end
