# frozen_string_literal: true

require 'el/entity'

require 'el/entity/associations'
require 'el/entity/repositories'
require 'el/entity/email'
require 'el/entity/passwords'
require 'el/entity/timestamps'

module El
  module Application
    class Entity < El::Entity
      include Dependency
      extend  Pluggable

      # TODO: Make these into plugins
      extend Entity::Associations
      extend Entity::Repositories
      extend Entity::Email
      extend Entity::Passwords
      extend Entity::Timestamps

      class << self
        def add_to!(app_class)
          super(app_class)

          app_class.register_dependency(canonical_name, self, depends_on: :database)
          define_repository_accessor!(app_class, self)
          define_entity_accessor!(app_class, self)

          define_model_accessor!(app_class) unless app_class.public_method_defined?(:model)
        end

        def init_app!(app)
          app.instance_variable_set(:@model, El::Model.new(app)) unless app.instance_variable_defined?(:@model)

          app.model.register_entity(self)

          self
        end

        private

        def define_model_accessor!(app_class)
          app_class.define_method(:model) do
            @model or raise 'the application model has not been initialized, perhaps call `app.init!`'
          end
        end

        def define_repository_accessor!(app_class, entity_class)
          name = El::Modeling::Utils.repository_name(entity_class.name).to_sym
          app_class.define_method(name) do
            model.repository(name)
          end
        end

        def define_entity_accessor!(app_class, entity_class)
          entity_name = El::Modeling::Utils.entity_name(entity_class.name.split('::').last).to_sym
          app_class.define_method(entity_name) do
            model.entity_class(entity_name)
          end
        end
      end
    end
  end
end
