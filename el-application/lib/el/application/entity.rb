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

      extend Entity::Associations
      extend Entity::Repositories
      extend Entity::Email
      extend Entity::Passwords
      extend Entity::Timestamps

      class << self
        def add_to!(app_class)
          super(app_class)

          name = self.name.split('::').last.to_sym
          app_class.add_dependency!(name, self, kind: :entities)

          app_class.attr_reader :model
        end

        def init_app!(app, entity_class)
          app.instance_variable_set(:@model, El::Model.new(app.database, app)) unless app.instance_variable_defined?(:@model)

          app.model.register_entity(entity_class)
          define_repository_accessor!(app, entity_class)
          define_entity_accessor!(app, entity_class)

          entity_class
        end

        private

        def define_repository_accessor!(app, entity_class)
          name = El::Modeling::Utils.repository_name(entity_class.name).to_sym
          app.define_singleton_method name do
            model.repository(name)
          end
        end

        def define_entity_accessor!(app, entity_class)
          entity_name = El::Modeling::Utils.entity_name(entity_class.name.split('::').last).to_sym
          app.define_singleton_method entity_name do
            model.entity_class(entity_name)
          end
        end
      end
    end
  end
end
