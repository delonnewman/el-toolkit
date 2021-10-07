# frozen_string_literal: true

require 'el/base'
require 'el/constants'

require_relative 'sql_utils'

module El
  # Represents the storage and retrival of a given entity class.
  class Repository < Base
    include Enumerable

    class << self
      def order_by(attribute_name)
        @order_by_attribute_name = attribute_name
      end

      def order_by_attribute_name
        @order_by_attribute_name
      end
    end

    attr_assign_once :logger
    attr_reader :dataset, :fields, :db, :logger, :component_attributes

    def initialize(entity_class, dataset, logger: nil)
      @entity_class = entity_class
      @db = dataset.db
      @logger = logger

      @component_attributes = @entity_class.component_attributes

      @fields = entity_class.attributes
                            .reject { |a| entity_class.exclude_for_storage.include?(a.name) }
                            .map { |a| Sequel[table_name][a.name] }

      @dataset = dataset
      @simple_dataset = dataset

      unless @component_attributes.empty?
        data = SqlUtils.component_attribute_query_info(entity_class)
        @fields += data.flat_map { |x| x[:fields] }

        @dataset = data.reduce(@dataset) { |ds, data| ds.join(data[:table], id: data[:ref]) }
                       .select(*fields)
      end

      @fields.freeze

      @dataset = @dataset.order(self.class.order_by_attribute_name) if self.class.order_by_attribute_name
    end

    def table_name
      Utils.table_name(entity_class.canonical_name).to_sym
    end

    def table
      db[table_name]
    end

    def empty?
      first.nil?
    end

    def all(&block)
      tag = "#{entity_class}.repository.all"
      logger.info "SQL #{tag}: #{dataset.sql}"

      dataset.each do |row|
        entity = SqlUtils.build_entity(entity_class, row)
        block&.call(entity)
      end
    end
    alias each all

    def find_by(predicates)
      record = dataset.first(SqlUtils.preprocess_predicates(predicates, table_name))
      return nil unless record

      SqlUtils.build_entity(entity_class, record)
    end

    def find_by!(attributes)
      find_by(attributes) or raise "Could not find record with: #{attributes.inspect}"
    end

    def update!(id, updates)
      data = updates.each_with_object({}) do |(key, value), h|
        attr = entity_class.attribute(key)
        next if attr.nil? || (value.nil? && attr.optional?)

        unless attr.valid_value?(value)
          raise TypeError, "For #{entity_class}##{key} #{value.inspect}:#{value.class} is not a valid #{attr[:type]}"
        end

        if attr.component?
          h[attr.reference_key] = value.fetch(:id)
          next
        end

        h[key] =
          if attr.serialize?
            YAML.dump(value)
          else
            value
          end
      end

      logger.info "UPDATE: #{data.inspect}"

      @simple_dataset.where(id: id).update(data)
    end

    def create!(record)
      id = store!(record)
      find_by!(id: id)
    end

    def store!(record)
      table.insert(SqlUtils.process_record(entity_class, record))
    end

    def store_all!(records)
      table.multi_insert(records.map(&SqlUtils.method(:process_record).curry[entity_class]))
    end

    def delete_where!(predicates)
      @simple_dataset.where(predicates).delete
    end

    def delete_all!
      table.delete
    end

    protected

    def where(predicates)
      dataset.where(predicates).map do |row|
        SqlUtils.build_entity(entity_class, row)
      end
    end

    def build_entity(hash)
      SqlUtils.build_entity(entity_class, hash)
    end
  end
end
