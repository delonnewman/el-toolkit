# frozen_string_literal: true

module El
  # A stateful resource to be injected into the application
  module Application
    class Service
      include Servicable
      include Dependency
      extend  Pluggable

      class << self
        attr_reader :loader, :unloader

        def start(&block)
          @loader = block
        end

        def stop(&block)
          @unloader = block
        end

        def canonical_name
          StringUtils.underscore(name.split('::').last).to_sym
        end

        def add_to!(app_class)
          super(app_class)

          name = canonical_name
          app_class.register_dependency(name, self)

          define_services_accessor!(app_class) unless app_class.public_method_defined?(:services)

          app_class.define_method(name) do
            services.fetch(name)
          end
        end

        def init_app!(app)
          app.instance_variable_set(:@services, {}) unless app.instance_variable_get(:@services)

          app.services[canonical_name] = super(app).load!
        end

        private

        def define_services_accessor!(app_class)
          app_class.define_method(:services) do
            @services or raise 'application services have not been initialized, perhaps call `app.init!`'
          end
        end
      end

      attr_reader :app

      def initialize(app)
        @app = app
      end

      def logger
        app.logger
      end

      def load!
        instance_exec(&self.class.loader) if self.class.loader
        loaded!
        freeze
      end

      def unload!
        instance_exec(&self.class.loader)
      end
    end
  end
end
