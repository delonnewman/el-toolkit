# frozen_string_literal: true

module El
  # Normalize data for entities
  class Entity::DataNomalizer
    def initialize(entity_class)
      @entity_class = entity_class
    end

    private

    attr_reader :entity_class

    def normalized_attribute_value(attr, value, instance)
      if value.nil? && attr.default && attr.required?
        return attr.default.is_a?(Proc) ? instance.instance_exec(&attr.default) : default
      end

      if attr.entity? && !value.nil?
        attr.value_class[value]
      else
        value
      end
    end

    public

    # @note this will mutate the entity_data
    def call(entity_data, instance)
      entity_class.attributes.each do |attr|
        value = entity_data[attr.name]
        entity_data[attr.name] = normalized_attribute_value(attr, value, instance)
      end

      entity_data
    end
  end
end
