# frozen_string_literal: true

module El
  # Convert a entity into a normal hash
  class Entity::DataDehydrator
    def initialize(entity_class)
      @entity_class = entity_class
    end

    private

    attr_reader :entity_class

    def hydrate_default_values!(attrs, data, entity)
      attrs.select(&:default).each_with_object(data) do |attr, values|
        values.merge!(attr.name => entity[attr.name] || eval_default(entity, attr))
      end
    end

    def eval_default(entity, attr)
      return attr.default unless attr.default.is_a?(Proc)

      entity.instance_exec(&attr.default)
    end

    def remove_nil_values!(attrs, data)
      attrs.select(&:optional?).each do |attr|
        data.delete(attr.name) if data[attr.name].nil?
      end
    end

    def remove_ignored_attributes(data)
      data.except(*entity_class.exclude_for_storage)
    end

    def hydrate_component_attributes!(data, entity)
      return data if (comps = entity_class.attributes.select(&:component?)).empty?

      comps.reduce(data) { |h, comp| h.merge!(comp.reference_key => entity.public_send(comp.name).id) }
    end

    public

    def call(data, entity)
      attrs = entity.class.attributes

      data = hydrate_default_values!(attrs, data.dup, entity)
      remove_nil_values!(attrs, data)
      # data = remove_ignored_attributes(data)
      # hydrate_component_attributes!(data, entity)

      data
    end
  end
end
