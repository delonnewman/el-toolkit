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
      name = attribute.name
      entity_class.define_method :"#{name}?" do
        self[name] == true
      end
    end

    # TODO: Define semantics around this
    def define_mutation_method!(entity_class)
      name = attribute.name
      type = attribute.type
      pred = attribute.type_predicate
      entity_class.define_method :"#{name}=" do |value|
        raise TypeError, "#{value.inspect}:#{value.class} is not a valid #{type}" unless pred.call(value)

        self[name] = value
      end
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

    def define_component_method!(entity_class)
      validate_entity_mapping!

      name = attribute.name
      entity_class.define_method name do
        value = value_for(name)
        klass = attribute(name).value_class

        return value if value.is_a?(klass)

        klass[value]
      end
    end

    def define_custom_method!(entity_class)
      name = attribute.name
      proc = attribute.proc
      entity_class.exclude_for_storage << name
      entity_class.define_method name do
        instance_exec(value_for(name), &proc)
      end
    end

    def define_reading_method!(entity_class)
      attr_name = name
      entity_class.define_method name do
        value_for(attr_name)
      end
    end

    def define_component_method?
      attribute.component? && mapping.is_a?(Hash)
    end

    public

    def call(entity_class)
      define_predicate_method!(entity_class) if attribute.boolean?
      define_mutation_method!(entity_class)  if attribute.mutable?
      define_custom_method!(entity_class)    if attribute.proc

      if define_component_method?
        define_component_method!(entity_class)
      else
        define_reading_method!(entity_class)
      end
    end
  end
end
