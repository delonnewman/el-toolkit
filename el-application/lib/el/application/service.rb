# frozen_string_literal: true

module El
  # A stateful resource to be injected into the application
  module Application
    class Service
      include Servicable
      include Dependency

      class << self
        attr_reader :loader, :unloader

        def start(&block)
          @loader = block
        end

        def stop(&block)
          @unloader = block
        end

        def add_to!(app_class)
          super(app_class)

          name = StringUtils.underscore(self.name.split('::').last).to_sym
          app_class.add_dependency!(name, self, kind: :services)

          app_class.define_method(name) do
            services.fetch(name)
          end
        end

        def init_app!(app, service_class)
          super(app, service_class).load!
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
