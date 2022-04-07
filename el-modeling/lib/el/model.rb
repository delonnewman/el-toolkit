# frozen_string_literal: true

require 'el/utils'
require 'el/modeling/utils'

module El
  class Model
    include Modeling::Utils

    attr_reader :database, :app

    def initialize(database, app = nil)
      @entities = {}
      @repositories = {}
      @database = database
      @app = app
    end

    def register_entity(entity_class)
      @entities[entity_name(entity_class.name).to_sym] = entity_class
      self
    end
    alias << register_entity

    def entity_class(name)
      name = name.is_a?(Symbol) || name.is_a?(Class) ? name.name : name
      @entities.fetch(entity_name(name).to_sym)
    end

    def entity_classes
      @entities.values
    end

    def repository_class(name)
      entity_class(name).repository_class
    end

    def repository(name)
      entity = entity_class(name)
      @repositories[entity] ||= entity.repository_class.new(self, entity)
    end

    def schema
      @entities.values.flat_map(&:attributes)
    end

    # TODO: Add diffs
    def schema_version
      schema.reduce(hash) do |hash, a|
        El::Utils.hash_combine(hash, a.hash)
      end.to_s(36)
    end
  end
end
