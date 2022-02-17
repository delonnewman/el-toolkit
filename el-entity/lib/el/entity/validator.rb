# frozen_string_literal: true

module El
  module Entity
    # Validate an data for an entity class
    class Validator
      def initialize(entity_class)
        @entity_class = entity_class
      end

      private

      attr_reader :entity_class

      def validate_required_attributes!
        attributes.each do |attr|
          if entity[attr.name].nil? && attr.required? && !attr.default
            raise TypeError, "#{self}##{attr.name} is required"
          end
        end
      end

      def validate_attribute_type!(attr, value)
        return if attr.valid_value?(value)

        raise TypeError, "For #{self}##{attr.name} #{value.inspect}:#{value.class} is not a valid #{attr[:type]}"
      end

      public

      def call(entity_data)
        validate_required_attributes!

        entity_data.each_with_object({}) do |(name, value), h|
          h[name] = value # pass along extra attributes with no checks
          next unless attribute?(name)

          attribute = attribute(name)
          next if (attribute.optional? && value.nil?) || !attribute.default.nil?

          validate_attribute_type!(attribute, value)
        end
      end
    end
  end
end
