# frozen_string_literal: true

require 'el/utils'
require 'el/publisher'
require 'el/modeling/utils'

module El
  class Model
    include Modeling::Utils
    extend  Forwardable

    attr_reader :app

    def_delegators :app, :database

    EVENTS = %i[create bulk_create update bulk_update].freeze

    def initialize(app)
      @app = app
      @entities = {}
      @publisher = Publisher.new(EVENTS)
    end

    private

    attr_reader :entities, :publisher

    public

    def register_entity(entity_class)
      entities[Modeling::Utils.entity_name(entity_class.name).to_sym] = entity_class
      entity_class.model = self
    end
    alias << register_entity

    def on(event, subscriber)
      publisher.add_subscriber(subscriber, event_name: event)

      self
    end

    def entity_class(name)
      entities.fetch(Modeling::Utils.entity_name(name).to_sym)
    end

    def repository_class(name)
      entity_class(name).repository_class
    end

    def repository(name)
      entity_class(name).repository
    end
    alias [] repository

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

    # @param [Class<Entity>] entity_class
    # @param [Hash, Enumerable] data
    #
    # @return [Entity, Array<Entity>]
    def create(entity_class, data)
      case data
      when Hash
        create_one(entity_class, data)
      when Enumerable
        create_all(entity_class, data)
      else
        raise 'only hash or enumerable data are permitted'
      end
    end

    def create_one(entity_class, data)
      klass       = self.entity_class(entity_class)
      entity      = Modeling::Utils.build_entity(self, klass, data)
      insert_data = SqlUtils.process_record(klass, Modeling::Utils.resolve_entity(self, entity))
      id          = entity_table(klass).insert(insert_data)

      publisher.publish_event(:create, { entity: entity })

      entity.merge(id: id)
    end

    def create_all(entity_class, data)
      klass       = self.entity_class(entity_class)
      entities    = data.map { |attrs| Modeling::Utils.build_entity(self, klass, attrs) }
      insert_data = entities.map! { |e| SqlUtils.process_record(klass, Modeling::Utils.resolve_entity(self, e)) }
      ids         = entity_table(klass).multi_insert(insert_data)

      publisher.publish_event(:bulk_create, { entities: entities })
      entities.each do |entity|
        publisher.publish_event(:create, { entity: entity })
      end

      entities.with_index.map { |e, i| e.merge(id: ids[i]) }
    end

    def update(entity_class, id, updates)
      klass = self.entity_class(entity_class)

      data = updates.each_with_object({}) do |(key, value), h|
        attr = klass.attribute(key)
        next if attr.nil? || (value.nil? && attr.optional?)

        raise TypeError, "for #{klass}##{key} #{value.inspect}:#{value.class} is not a valid #{attr[:type]}" unless attr.valid_value?(value)

        if attr.component?
          h.merge!(klass.attribute_reference_key(attr) => value.fetch(:id))
          next
        end

        if attr.serialize?
          h.merge!(key => YAML.dump(value))
        else
          h.merge!(key => value)
        end
      end

      entity_table(klass).where(id: id).update(data)
      publisher.publish_event(:update, { entity_id: id, entity_class: klass, updates: updates })

      id
    end

    def default_id_attribute(entity_class)
      Sequel.qualify(entity_table_name(entity_class), :id)
    end

    def fetch(entity_class, id, *args, id_attribute: default_id_attribute(entity_class), &block)
      klass      = self.entity_class(entity_class)
      table      = entity_table(entity_class)
      table_name = entity_table_name(entity_class)
      data       = Modeling::Utils.dataset(klass, table_name, table).first(id_attribute => id)

      return Modeling::Utils.build_entity(self, klass, data) if data
      return block.call if block_given?

      raise "couldn't find #{entity_class} with id #{id.inspect}" if args.empty?

      args.first
    end

    def get(entity_class, id)
      fetch(entity_class, id, nil)
    end

    def get!(entity_class, id)
      fetch(entity_class, id)
    end

    def cast(entity_class, entity_or_data)
      return entity_or_data if entity_or_data.is_a?(entity_class)

      data = entity_or_data
      return Modeling::Utils.build_entity(self, entity_class, data) if data.is_a?(Hash)

      ident = entity_or_data
      entity_class.reference_mapping.each do |type, ref|
        return fetch(entity_class, ident, id_attribute: ref) if type.call(ident)
      end

      nil
    end

    def cast!(entity_class, entity_or_data)
      cast(entity_class, entity_or_data) or
        raise TypeError, "#{entity_or_data.inspect}:#{entity_or_data.class} cannot be coerced into #{entity_class}"
    end
  end
end
