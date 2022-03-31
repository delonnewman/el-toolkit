require 'test_helper'

module El
  module Routable
    # Tests for El::Routable::InstanceMethods
    class InstanceMethodsTest < Minitest::Test
      def setup
        @routable = Class.new.include(El::Routable)
      end

      def test_match_simple_path
        test = nil
        @routable.get '/', -> { test = :called }
        @routable.new.call(Rack::MockRequest.env_for('/'))

        assert_equal :called, test
      end

      def test_match_named_path
        test = nil
        @routable.get '/:id', ->(r) { test = r.params[:id] }
        router = @routable.new

        examples = [{ path: '/123', value: '123' }, { path: '/abc123', value: 'abc123' }]

        examples.each do |example|
          router.call(Rack::MockRequest.env_for(example[:path]))

          assert_equal example[:value], test
        end
      end
    end
  end
end
