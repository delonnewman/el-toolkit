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
      entity_class.define_method :"#{name}?" do
        self[name] == true
      end
    end

    # TODO: Define semantics around this
    def define_mutation_method!(entity_class)
      entity_class.define_method :"#{name}=" do |value|
        unless attribute.type.call(value)
          raise TypeError, "#{value.inspect}:#{value.class} is not a valid #{attribute[:type]}"
        end

        self[name] = value
      end
    end

    def validate_attribute_name!
      # type check the attribute name and mapping for security (see class_eval below)
      return if name.is_a?(Symbol) && name.name =~ /\A\w+\z/

      raise TypeError,
            "Attribute names should be symbols without special characters: #{name.inspect}:#{name.class}"
    end

    def validate_entity_resolution!
      mapping.each do |key, value|
        unless key.respond_to?(:call)
          raise TypeError,
                "#{value_class} keys in value mappings should be callable objects: #{key.inspect}:#{key.class}"
        end

        unless value.is_a?(Symbol) && value.name =~ /\A\w+\z/
          raise TypeError,
                "Values in mappings should be symbols without special characters got instead: #{value.inspect}:#{value.class}"
        end
      end
    end

    def define_component_method!(entity_class)
      validate_entity_resolution!

      entity_class.define_method name do
        value = value_for(name)
        klass = attribute(name).value_class

        return value if value.is_a?(klass)

        klass[value]
      end
    end

    def define_custom_method!(entity_class)
      entity_class.exclude_for_storage << name
      entity_class.define_method name do
        instance_exec(self[name], &attribute.proc)
      end
    end

    def define_reading_method!(entity_class)
      entity_class.define_method name do
        value_for(name)
      end
    end

    public

    def call(entity_class)
      define_predicate_method!(entity_class) if attribute.boolean?
      define_mutation_method!(entity_class)  if attribute.mutable?
      define_component_method!(entity_class) if attribute.component? && mapping.is_a?(Hash)
      define_custom_method!(entity_class)    if attribute.proc

      define_reading_method!(entity_class)
    end
  end
end
