# frozen_string_literal: true

require 'set'
require 'cgi'
require 'rack'
require 'stringio'
require 'forwardable'

require 'el/constants'

require_relative 'route'
require_relative 'routes'
require_relative 'request'
require_relative 'request_evaluator'

module El
  # Provides a light-weight DSL for routing over Rack, and instances implement
  # the Rack application interface.
  #
  # @example
  #   class MyApp
  #     include El::Routable
  #
  #     # compose Rack middleware
  #     use Rack::Session
  #
  #     # block routes
  #     get '/hello' do
  #       'Hello'
  #     end
  #
  #     # 'callable' objects also work
  #     get '/hola', ->{ 'Hola' }
  #
  #     class Greeter
  #       def call
  #         'Miredita'
  #       end
  #     end
  #
  #     get '/miredita', Greeter
  #
  #     # dispatch based on headers
  #     get '/hello', content_type: :json do
  #       'Hello JSON'
  #     end
  #
  #     # nested routes
  #     on '/user/:id' do |user_id|
  #       @user = User.find(user_id)
  #
  #       get render: 'user/show'
  #       post do
  #         @user.update(params.slice(:username, :email))
  #       end
  #
  #       get '/settings', render: 'user/settings'
  #       post '/settings do
  #         @user.settings.update(params.slice(:settings))
  #       end
  #     end
  #
  #     # mount Rack apps
  #     mount '/admin', AdminApp
  #   end
  module Routable
    # Valid methods for routes
    HTTP_METHODS = %i[get post delete put head link unlink].to_set.freeze

    require_relative 'routable/api'
    require_relative 'routable/dsl'

    def self.included(base)
      base.extend(DSL::ClassMethods)
      base.extend(API::ClassMethods)
      base.include(DSL::InstanceMethods)
      base.include(API::InstanceMethods)
    end
  end
end
