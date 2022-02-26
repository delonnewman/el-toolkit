# frozen_string_literal: true

require "rack"

require "el/string_utils"

module El
  class Application
    require_relative "application/package"
    require_relative "application/router"

    class << self
      def add_dependency!(name, object, init: true)
        @deps ||= {}
        @deps[name] = { object: object, init: init }
      end

      def find_dependency(name)
        @deps[name]
      end

      def Package
        @package_class ||= Application::Package.create(self)
      end

      def Router
        @router_class ||= Application::Router.create(self)
      end

      def routers
        @routers ||= []
      end
    end

    def initialize
      @deps = Hash.new do |name|
        dep = self.class.find_dependency(name)
        if dep && dep[:init]
          dep.new(app)
        elsif dep
          dep
        end
      end
    end

    def [](dep_name)
      @deps[dep_name]
    end

    def call(env); end
  end
end
