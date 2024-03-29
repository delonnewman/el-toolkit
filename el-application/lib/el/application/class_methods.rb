# frozen_string_literal: true

module El
  module Application
    # Macro and meta methods for application configuration
    module ClassMethods
      def environment
        ENV.fetch('APP_ENV', ENV.fetch('RACK_ENV', 'development')).to_sym
      end

      def configure(env, &block)
        instance_exec(&block) if environment == env
      end

      def settings
        return @settings if @settings

        @settings =
          if superclass.respond_to?(:settings)
            superclass.settings.dup
          else
            {}
          end
      end

      def set(key, value)
        settings[key] = value
      end

      def enable(key)
        set(key, true)
      end

      def disable(key)
        set(key, false)
      end

      def env_vars(*keys)
        keys.each do |key|
          settings_from_environment[key] = key.to_s.upcase
        end
      end

      def settings_from_environment
        @settings_from_environment ||= {}
      end

      def root_path(path = nil)
        return @root_path unless path

        @root_path = path
      end

      def app_module
        parts = name.split('::')
        parts[0, parts.length - 1].reduce(Kernel) do |mod, part|
          mod.const_get(part)
        end
      end

      def resolve_class_symbol(symbol)
        app_module.const_get(StringUtils.camelcase(symbol.name))
      end

      def middleware
        @middleware ||= []
      end

      def use(app, options = {})
        middleware << [app, options]
      end

      def Service
        @resource_class ||= Application::Service.create(self)
      end

      def Router
        @router_class ||= Application::Router.create(self)
      end

      def Entity
        @entity_class ||= Application::Entity.create(self)
      end

      def dependencies
        @dependencies ||= {}
      end

      def dependency_graph
        dependencies.each_with_object({}) do |(name, dep), h|
          h[dep[:depends_on]] ||= []
          h[dep[:depends_on]] << name
        end
      end

      def register_dependency(name, object, init: true, depends_on: nil)
        dependencies[name] = { object: object, init: init, depends_on: depends_on }
      end

      def dependency(name)
        dependencies[name]
      end

      def dependency!(name)
        dependencies.fetch(name)
      end
    end
  end
end
