# frozen_string_literal: true

require 'set'
require 'cgi'
require 'rack'
require 'stringio'
require 'forwardable'

require_relative 'constants'

require_relative 'route_data'
require_relative 'routes'
require_relative 'request'
require_relative 'rack_call'

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

    require_relative 'routable/instance_methods'
    require_relative 'routable/class_methods'

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
    end
  end
end
