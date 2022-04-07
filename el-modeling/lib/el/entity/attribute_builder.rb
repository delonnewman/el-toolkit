# frozen_string_literal: true

module El
  # Define appropriate attribute methods for the entity class
  class Entity::AttributeBuilder
    extend Forwardable

    def initialize(attribute)
      @attribute = attribute
    end

    private

    attr_reader :attribute

    def_delegators :attribute, :name, :value_class

    def mapping
      value_class.respond_to?(:reference_mapping) ? value_class.reference_mapping : EMPTY_HASH
    end

    def define_predicate_method!(entity_class)
      entity_class.class_eval "def #{name}?; !!value_for(#{name.inspect}) end", __FILE__, __LINE__
    end

    def validate_attribute_name!
      # type check the attribute name and mapping for security (see class_eval below)
      return if name.is_a?(Symbol) && name.name =~ /\A\w+\z/

      raise TypeError, "Attribute names should be symbols without special characters: #{name.inspect}:#{name.class}"
    end

    def validate_entity_mapping!
      mapping.each do |key, value|
        raise TypeError, "#{value_class} keys in value mappings should be callable objects: #{key.inspect}:#{key.class}" unless key.respond_to?(:call)

        unless value.is_a?(Symbol) && value.name =~ /\A\w+\z/
          raise TypeError, "Values in mappings should be symbols without special characters got instead: #{value.inspect}:#{value.class}"
        end
      end
    end

    def define_custom_method!(entity_class)
      entity_class.exclude_for_storage << name
      entity_class.class_eval <<~CODE, __FILE__, __LINE__ + 1
        def #{name}
          proc = attribute(#{name.inspect}).definition
          instance_exec(value_for(name), &proc)
        end
      CODE
    end

    def define_reading_method!(entity_class)
      entity_class.class_eval "def #{name}; value_for(#{name.inspect}) end", __FILE__, __LINE__
    end

    def define_method_with_default!(entity_class)
      entity_class.class_eval <<~CODE, __FILE__, __LINE__ + 1
        def #{name}
          value = value_for(#{name.inspect})
          return value if value

          default = attribute(#{name.inspect}).default
          default.is_a?(Proc) ? instance_exec(&default) : default
        end
      CODE
    end

    public

    def call(entity_class)
      define_predicate_method!(entity_class) if attribute.boolean?

      if attribute.definition
        define_custom_method!(entity_class)
      elsif attribute.default
        define_method_with_default!(entity_class)
      else
        define_reading_method!(entity_class)
      end
    end
  end
end
