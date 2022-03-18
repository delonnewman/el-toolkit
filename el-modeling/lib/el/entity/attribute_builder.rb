module El
  module Entity
    # Define appropriate attribute methods for the entity class
    class AttributeBuilder
      def initialize(attribute)
        @attribute = attribute
        @entity_class = attribute.entity_class
        @mapping = attribute.value_reference_mapping
      end

      private

      attr_reader :attribute, :entity_class, :mapping

      def name
        attribute.name
      end

      def define_predicate_method!
        entity_class.define_method :"#{name}?" do
          self[name] == true
        end
      end

      def define_mutation_method!
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
            raise TypeError, "Keys in value mappings should be callable objects: #{key.inspect}:#{key.class}"
          end

          unless value.is_a?(Symbol) && value.name =~ /\A\w+\z/
            raise TypeError,
                  "Values in value mappings should symbols without special characters: #{value.inspect}:#{value.class}"
          end
        end
      end

      def define_component_method!
        validate_entity_resolution!

        entity_class.define_method name do
          value = self[name]
          type = self.class.attribute(name).value_class
          if value.is_a?(type)
            value
          else
            type.ensure!(value)
          end
        end
      end

      def define_custom_method!
        entity_class.exclude_for_storage << name
        entity_class.define_method name do
          instance_exec(self[name], &attribute.proc)
        end
      end

      def define_reading_method!
        if attribute.default
          entity_class.define_method name do
            value_for(name)
          end
        else
          entity_class.define_method name do
            self[name]
          end
        end
      end

      public

      def call
        define_predicate_method! if attribute.boolean?
        define_mutation_method!  if attribute.mutable?
        define_component_method! if attribute.component? && mapping.is_a?(Hash)
        define_custom_method!    if attribute.proc

        define_reading_method!
      end
    end
  end
end
