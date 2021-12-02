# frozen_string_literal: true

require "rack"
require "rack/routable"

require_relative "dependency"

module El
  class Application
    class Router
      include Dependency
      include Rack::Routable

      def self.add_to!(app_class)
        super
        app_class.routers << self
      end

      attr_reader :app, :env

      def initialize(app, env)
        @app = app
        super(env)
      end
    end
  end
end
