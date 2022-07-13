# frozen_string_literal: true

require 'el/utils'
require 'el/modeling/utils'

module El
  class Model
    include Modeling::Utils
    extend  Forwardable

    attr_reader :app

    def_delegators :app, :database

    def initialize(app)
      @app = app
      @entities = {}
    end

    private

    attr_reader :entities

    public

    def register_entity(entity_class)
      entities[entity_name(entity_class.name).to_sym] = entity_class
      entity_class.model = self
    end
    alias << register_entity

    def entity_class(name)
      entities.fetch(entity_name(name).to_sym)
    end

    def repository_class(name)
      entity_class(name).repository_class
    end

    def repository(name)
      entity_class(name).repository
    end

    def entity_table_name(name)
      table_name(entity_class(name))
    end

    def entity_table(name)
      database[entity_table_name(name).to_sym]
    end

    def entity_classes
      entities.values
    end

    def schema
      entities.values.flat_map(&:attributes)
    end

    # TODO: Add diffs
    def schema_version
      schema.reduce(hash) do |hash, a|
        El::Utils.hash_combine(hash, a.hash)
      end.to_s(36).upcase!
    end
  end
end
