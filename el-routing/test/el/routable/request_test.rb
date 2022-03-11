require 'test_helper'

module El
  module Routable
    class RequestTest < Minitest::Test
      def setup
        @request = Request.new(Rack::MockRequest.env_for('/'))
      end

      def test_slice
        method, path = @request.values_at('REQUEST_METHOD', 'PATH_INFO')

        assert_equal method, 'GET'
        assert_equal path, '/'
      end
    end
  end
end
