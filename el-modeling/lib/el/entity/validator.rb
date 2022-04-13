# frozen_string_literal: true

module El
  # Validate an data for an entity class
  class Entity::Validator
    extend Forwardable

    def initialize(entity_class)
      @entity_class = entity_class
    end

    private

    attr_reader :entity_class

    def_delegators :entity_class, :attributes

    def mapping(attr)
      entity_class.respond_to?(:reference_mapping) ? attr.value_class.reference_mapping : EMPTY_HASH
    end

    def validate_required_attributes!(errors, entity_data)
      attributes.each_with_object(errors) do |attr, e|
        e[attr.name] = "#{attr.name} is required" if !entity_data.key?(attr.name) && attr.required? && !attr.default
      end
    end

    def valid_reference?(attr, value)
      return false unless attr.entity?
      return true if value.is_a?(Hash) # TODO: use the value class to validate

      mapping(attr).keys.any? { |k| k.call(value) }
    end

    def validate_attribute_type!(errors, attr, value)
      return if valid_reference?(attr, value)
      return if attr.valid_value?(value)

      errors[attr.name] = "#{value.inspect} is not a valid #{attr.name}"
    end

    public

    def call(entity_data, attribute = nil)
      errors = {}
      return errors if attribute && valid_reference?(attribute, entity_data)

      validate_required_attributes!(errors, entity_data)

      entity_data.each_with_object(errors) do |(name, value), e|
        next unless entity_class.attribute?(name)

        attribute = entity_class.attribute(name)
        next if (attribute.optional? && value.nil?) || !attribute.default.nil?

        validate_attribute_type!(e, attribute, value)
      end
    end
  end
end
