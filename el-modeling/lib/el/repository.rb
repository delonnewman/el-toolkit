# frozen_string_literal: true

# rubocop disable: Metrics/ClassLength

require_relative 'sql_utils'

module El
  # Represents the storage and retrival of a given entity class.
  class Repository
    include Enumerable

    extend Forwardable

    class << self
      def order_by(attribute_name)
        @order_by_attribute_name = attribute_name
      end

      attr_reader :order_by_attribute_name
    end

    attr_reader :entity_class, :model

    def initialize(model, entity_class)
      @model = model
      @entity_class = entity_class
    end

    def to_s
      "#<#{self.class} entity: #{entity_class}>"
    end
    alias inspect to_s

    private

    def_delegators 'self.class', :order_by_attribute_name
    def_delegators :entity_class, :component_attributes

    def dataset
      return @dataset if @dataset

      @dataset = table
      @dataset = @dataset.order(order_by_attribute_name) if order_by_attribute_name
      return @dataset if component_attributes.empty?

      @dataset = field_info.reduce(@dataset) { |ds, data| ds.join(data[:table], id: data[:ref]) }.select(*fields)
    end

    def field_info
      @field_info ||= SqlUtils.all_component_attribute_query_info(entity_class)
    end

    def db
      dataset.db
    end

    def fields
      return @fields if @fields

      @fields = entity_class.storable_attributes.map { |a| Sequel[table_name][a.name] }
      return @fields if component_attributes.empty?

      @fields += field_info.flat_map { |data| data[:fields] }
    end

    public

    def table_name
      model.table_name(entity_class.name).to_sym
    end

    def table
      database[table_name]
    end

    def table_exists?
      database.table_exists?(table_name)
    end

    def empty?
      table.empty?
    end

    def all(&block)
      tag = "app.#{table_name}.all"
      logger.info "SQL #{tag}: #{dataset.sql}"

      return to_a unless block

      to_a.each(&block)
    end

    def each(&block)
      return lazy unless block

      dataset.each do |row|
        block.call(entity(row))
      end

      self
    end

    def pluck(*columns)
      return table.select_map(columns[0]) if columns.size == 1

      table.select_map(columns)
    end

    def find_by(predicates)
      preds = SqlUtils.preprocess_predicates(predicates, table_name)
      logger.info "Query #{entity_class}.repository.find_by: #{preds.inspect}"
      record = dataset.first(preds)
      return nil unless record

      entity(record)
    end

    def find_by!(attributes)
      find_by(attributes) or raise "Could not find record with: #{attributes.inspect}"
    end

    def update!(id, updates)
      data = updates.each_with_object({}) do |(key, value), h|
        attr = entity_class.attribute(key)
        next if attr.nil? || (value.nil? && attr.optional?)

        raise TypeError, "For #{entity_class}##{key} #{value.inspect}:#{value.class} is not a valid #{attr[:type]}" unless attr.valid_value?(value)

        if attr.component?
          h[entity_class.attribute_reference_key(attr)] = value.fetch(:id)
          next
        end

        if attr.serialize?
          h.merge!(key => YAML.dump(value))
        else
          h.merge!(key => value)
        end
      end

      table.where(id: id).update(data)
    end

    def valid?(entity, &block)
      validate!(entity)
      block.call(entity_class.new(entity)) if block_given?
      true
    rescue TypeError
      false
    end

    # TODO: add database oriented validations like uniqness here
    def validate!(entity)
      entity_class.validate!(entity)
    end

    def create!(*records)
      if records.size == 1
        return create_each!(records[0]) if records[0].is_a?(Enumerable)

        return create_one!(records[0])
      end

      create_each!(records)
    end

    def create_one!(record)
      validate!(record)
      id = store_one!(entity(record))
      find_by!(id: id)
    end

    def create_each!(records)
      ids = records.map do |record|
        validate!(record)
        store_one!(entity(record))
      end

      where(Sequel[table_name][:id] => ids)
    end

    def store!(*records)
      if records.size == 1
        return store_each!(records[0]) if records[0].is_a?(Enumerable)

        return store_one!(records[0])
      end

      store_each!(records)
    end

    def store_one!(record)
      table.insert(SqlUtils.process_record(entity_class, resolve_entity(record)))
    end

    def store_each!(records)
      db.transaction do
        records.map(&method(:store_entity!))
      end
    end

    def store_all!(records)
      insert_data = records.map { |r| SqlUtils.process_record(entity_class, resolve_entity(r)) }
      table.multi_insert(insert_data)
    end

    def delete_where!(predicates)
      table.where(predicates).delete
    end

    def delete_all!
      table.delete
    end

    def fetch(id, *args, id_attribute: :id, &block)
      data = table.first(id_attribute => id)

      return entity(data) if data
      return block.call   if block_given?

      raise "couldn't find #{entity_class} with id #{id.inspect}" if args.empty?

      args.first
    end

    def get(id)
      fetch(id, nil)
    end
    alias [] get

    def get!(id)
      fetch(id)
    end

    def cast(value)
      return value if value.is_a?(entity_class)
      return entity(value) if value.is_a?(Hash)

      entity_class.reference_mapping.each do |type, ref|
        return fetch(value, id_attribute: ref) if type.call(value)
      end

      nil
    end

    def to_proc
      ->(value) { find(value) }
    end

    def cast!(value)
      cast(value) or raise TypeError, "#{value.inspect}:#{value.class} cannot be coerced into #{entity_class}"
    end

    protected

    def_delegators :model, :app, :database
    def_delegators :app, :logger

    def where(predicates)
      dataset.where(predicates).map(&method(:entity))
    end

    def entity(hash)
      SqlUtils.build_entity(entity_class, hash)
    end

    private

    def resolve_entity(entity)
      data = entity.to_h
      data = data.except(*entity.class.exclude_for_storage)

      return data if component_attributes.empty?

      resolve_component_attributes(entity, data)
    end

    def resolve_component_attributes(entity, data)
      component_attributes.reduce(data) do |h, comp|
        key = Modeling::Utils.reference_key(comp.name).to_sym
        val = model.repository(comp.value_class).cast!(entity[comp.name]).id
        h.merge!(key => val)
      end
    end
  end
end
