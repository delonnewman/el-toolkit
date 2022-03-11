require 'test_helper'

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

    def test_media_type_aliases
      @routable.media_type :json, 'application/json'

      assert_equal :json, @routable.media_type_aliases['application/json']
      assert_equal :json, @routable.media_type_aliases[:json]
    end
  end
end
