require_relative '../../lib/el/routable'
require 'minitest/autorun'

module El
  class RoutableTest < Minitest::Test
    def setup
      @routable = Class.new.include(El::Routable)
    end

    def test_namespace
      @routable.namespace '/test'
      route = @routable.get '/:id', -> {}

      assert_equal route.path, '/test/:id'
      assert_equal @routable.namespace[:path], '/test'
    end

    def test_namespace_scoping
      route = nil
      @routable.namespace '/scoped' do
        route = @routable.get '/:id', -> {}
      end

      assert_equal route.path, '/scoped/:id'
      assert_nil @routable.namespace
    end
  end
end
