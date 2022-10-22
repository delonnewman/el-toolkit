# frozen_string_literal: true

require 'el/constants'

module El
  module Modeling
    module Utils
      extend self

      # @param [String, #name] string
      # @param [Boolean] namespace
      #
      # @return [String]
      def entity_name(string, namespace: false)
        string = string.name if string.respond_to?(:name) # works for classes or symbols
        string = string.split('::').last unless namespace

        Inflection.singular(StringUtils.camelcase(string))
      end

      # @param [String, #name] string
      # @param [Boolean] namespace
      #
      # @return [String]
      def table_name(string, namespace: false)
        string = string.name if string.respond_to?(:name) # works for classes or symbols
        string = string.split('::').last unless namespace

        Inflection.plural(StringUtils.underscore(string))
      end
      alias repository_name table_name

      def join_table_name(entity_class, other_class)
        "#{table_name(entity_class.name)}_#{table_name(other_class.name)}"
      end

      def component_table_name(attribute)
        table_name(attribute.value_class.name)
      end

      def reference_key(string)
        string = string.name if string.is_a?(Symbol)

        "#{Inflection.singular(string)}_id"
      end

      def resolve_entity(model, entity)
        data = entity.to_h
        data = data.except(*entity.class.exclude_for_storage)

        return data if entity.class.component_attributes.empty?

        resolve_component_attributes(model, entity, data)
      end

      # @param [Model] model
      # @param [Entity] entity
      # @param [Hash] data
      #
      # @return [Hash]
      def resolve_component_attributes(model, entity, data)
        entity.class.component_attributes.reduce(data) do |h, comp|
          key = reference_key(comp.name).to_sym
          val = model.cast!(comp.value_class, entity[comp.name]).id
          h.merge!(key => val)
        end
      end

      # @param [Class<Entity>] entity_class
      # @param [Hash] data
      #
      # @return [Entity]
      def build_entity(model, entity_class, data)
        reconstituted = SqlUtils.reconstitute_record(entity_class, data)
        parsed = DataUtils.parse_nested_hash_keys(reconstituted)

        entity_class.new(parsed)
      end

      def database_fields(entity_class, table_name, field_info = EMPTY_ARRAY)
        entity_class.storable_attributes.map { |a| Sequel.qualify(table_name, a.name) } +
          field_info.flat_map { |info| info[:fields] }
      end

      # @param [Class<Entity>] entity_class
      # @param [Symbol, String] table_name
      # @param [Sequel::Dataset] table
      # @param [Symbol] order_by
      def dataset(entity_class, table_name, table, order_by: nil)
        set = table
        set = set.order(order_by) if order_by
        return set if entity_class.component_attributes.empty?

        field_info = SqlUtils.all_component_attribute_query_info(entity_class)
        fields = database_fields(entity_class, table_name, field_info)

        field_info.reduce(set) { |ds, data| ds.join(data[:table], id: data[:ref]) }.select(*fields)
      end
    end
  end
end
