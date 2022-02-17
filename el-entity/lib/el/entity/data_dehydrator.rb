# frozen_string_literal: true

module El
  module Entity
    # Convert a entity into a normal hash
    class DataDehydrator
      def initialize(entity_class)
        @entity_class = entity_class
      end

      private

      attr_reader :entity_class

      def hydrate_default_values!(attrs, data, entity)
        attrs.reject { |a| a.default.nil? }.each { |attr| data[attr.name] = entity.value_for(attr.name) }
      end

      def remove_nil_values!(attrs, data, entity)
        attrs
          .select(&:optional?)
          .each { |attr| data.delete(attr.name) if entity.value_for(attr.name).nil? }
      end

      def remove_ignored_attributes(data)
        data.except(*entity_class.exclude_for_storage)
      end

      def hydrate_component_attributes!(data)
        if (comps = self.class.attributes.select(&:component?)).empty?
          data
        else
          comps.reduce(data) { |h, comp| h.merge!(comp.reference_key => send(comp.name).id) }
        end
      end

      public

      def call(data, entity)
        attrs = self.class.attributes

        hydrate_default_values!(attrs, data, entity)
        remove_nil_values!(attrs, data, entity)
        data = remove_ignored_attributes(data)

        hydrate_component_attributes!(data)
      end
    end
  end
end
