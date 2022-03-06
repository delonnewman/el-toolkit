# frozen_string_literal: true

module El
  class Application
    module Dependency
      def self.included(klass)
        klass.extend(ClassMethods)
        klass.include(InstanceMethods)
      end

      module ClassMethods
        attr_reader :app_class

        def app_class=(klass)
          if app_class?
            warn "A package's app_class can only be set once"
          else
            @app_class = klass
          end
        end

        def app_class?
          !!@app_class
        end

        def create(app_class)
          Class.new(self).tap do |klass|
            klass.app_class = app_class
          end
        end

        def add_to!(app_class)
          self.app_class = app_class
        end

        def inherited(pkg_class)
          super
          return unless app_class?

          pkg_class.add_to!(app_class)
        end
      end

      module InstanceMethods
        def app
          raise 'An `app` method must be defined for Dependency classes'
        end
      end
    end
  end
end
