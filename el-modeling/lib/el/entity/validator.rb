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

    def validate_required_attributes!(entity_data)
      attributes.each do |attr|
        if !entity_data.key?(attr.name) && attr.required? && !attr.default
          raise TypeError, "#{entity_class}##{attr.name} is required"
        end
      end
    end

    def validate_attribute_type!(attr, value)
      return if attr.valid_value?(value)

      raise TypeError, "For #{self}##{attr.name} #{value.inspect}:#{value.class} is not a valid #{attr[:type]}"
    end

    public

    def call(entity_data)
      validate_required_attributes!(entity_data)

      entity_data.each_with_object({}) do |(name, value), h|
        h[name] = value # pass along extra attributes with no checks
        next unless entity_class.attribute?(name)

        attribute = entity_class.attribute(name)
        next if (attribute.optional? && value.nil?) || !attribute.default.nil?

        validate_attribute_type!(attribute, value)
      end
    end
  end
end
