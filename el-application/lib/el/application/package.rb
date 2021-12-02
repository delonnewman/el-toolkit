# frozen_string_literal: true

require_relative "dependency"

module El
  class Application
    class Package
      include Dependency

      def self.add_to!(app_class, name: StringUtils.underscore(name.split('::').last))
        super

        app_class.add_dependency!(name, pkg)

        pkg = self
        app_class.define_method name do
          @packages[name] ||= pkg.new(self)
        end
      end

      attr_reader :app

      def initialize(app)
        @app = app
      end
    end
  end
end
