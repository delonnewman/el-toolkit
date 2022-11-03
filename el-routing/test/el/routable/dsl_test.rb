require 'test_helper'

module El
  class RoutableTest < Minitest::Test
    def setup
      @routable = Class.new.include(El::Routable)
    end

    def test_namespace
      @routable.namespace('/test').get('/:id', ->{})

      assert !@routable.routes.fetch(:get, '/test/1').nil?
    end

    def test_namespace_scoping
      @routable.namespace '/scoped' do
        @routable.get('/:id', -> {})
      end

      assert !@routable.routes.fetch(:get, '/scoped/1').nil?
    end

    def test_media_type_aliases
      @routable.media_type :json, 'application/json'

      assert_equal :json, @routable.media_type_aliases['application/json']
      assert_equal :json, @routable.media_type_aliases[:json]
    end
  end
end
