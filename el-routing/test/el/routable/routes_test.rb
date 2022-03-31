# frozen_string_literal: true

require 'test_helper'

module El
  module Routable
    class RoutesTest < Minitest::Test
      def setup
        @routes = Routes[
          [:get,    '/']          => -> {},
          [:get,    '/users']     => -> {},
          [:post,   '/users']     => -> {},
          [:get,    '/users/:id'] => -> {},
          [:post,   '/users/:id'] => -> {},
          [:delete, '/users/:id'] => -> {},
        ]

        @examples = {
          '/'          => [[:get, '/']],
          '/users/:id' => [
            [:get,    '/users/123'],
            [:post,   '/users/abc123'],
            [:delete, '/users/1-2-3'],
            [:get,    '/users/A_B_C']
          ]
        }
      end

      def test_match
        assert_matches @examples, @routes
      end

      def test_merge
        other = Routes[
          [:get,  '/:id']          => -> {},
          [:link, '/users']        => -> {},
          [:link, '/users/:id']    => -> {},
          [:get,  '/sessions']     => -> {},
          [:get,  '/sessions/:id'] => -> {}
        ]

        new_routes = @routes.merge(other)

        assert_equal @routes.size + other.size, new_routes.size
        assert_matches @examples, new_routes
      end

      def assert_matches(examples, routes)
        examples.each_pair do |expected_path, paths|
          paths.each do |(method, path)|
            request = routes.match(Rack::MockRequest.env_for(path, method: method))

            assert !request.not_found?
            assert_equal expected_path, request.route.path
            assert_equal method, request.route.method
          end
        end
      end
    end
  end
end
