# frozen_string_literal: true

module El
  module Entity
    # Represents a domain entity that will be modeled. Provides dynamic checks and
    # meta objects for relfection which is used to drive productivity and inspection tools.
    class Base < HashDelegator
      transform_keys(&:to_sym)

      extend Forwardable
      extend Validation
      extend Types

      class << self
        def define_attribute(name, type = Object, **options, &block)
          meta = { entity: self, name: name, type: type, required: !block, proc: block }
          attribute = Attribute.new(meta.merge(options)).define!

          @required_attributes ||= []
          @required_attributes << name if attribute.required?

          @attributes ||= {}
          @attributes[name] = attribute

          name
        end
        alias has define_attribute

        def attributes(regular: true)
          attrs = @attributes&.values || EMPTY_ARRAY

          if regular && superclass.respond_to?(:attributes)
            (superclass.attributes + attrs).sort_by(&:name)
          else
            attrs
          end
        end

        def attribute(name)
          @attributes.fetch(name)
        end

        def attribute?(name)
          @attributes.key?(name)
        end

        def ensure!(value)
          case value
          when self
            value
          when Hash
            new(value)
          else
            raise TypeError, "#{value.inspect}:#{value.class} cannot be coerced into #{self}"
          end
        end
        alias call ensure!
        alias [] ensure!

        def to_proc
          ->(attributes) { call(attributes) }
        end

        def canonical_name
          Utils.snakecase(name.split("::").last)
        end

        def validate!(entity)
          attributes.each do |attr|
            if entity[attr.name].nil? && attr.required? && !attr.default
              raise TypeError, "#{self}##{attr.name} is required"
            end
          end

          entity.each_with_object({}) do |(name, value), h|
            h[name] = value # pass along extra attributes with no checks
            next unless attribute?(name)

            attribute = attribute(name)
            next if (attribute.optional? && value.nil?) || !attribute.default.nil?

            unless attribute.valid_value?(value)
              raise TypeError,
                    "For #{self}##{attribute.name} #{value.inspect}:#{value.class} is not a valid #{attribute[:type]}"
            end
          end
        end
      end

      def initialize(attributes = EMPTY_HASH)
        record = self.class.validate!(attributes)

        self.class.attributes.each do |attr|
          value = record[attr.name]
          if value.nil? && attr.default && attr.required?
            record[attr.name] = attr.default.is_a?(Proc) ? instance_exec(&attr.default) : default
          end

          record[attr.name] = attr.value_class[value] if attr.entity? && !value.nil?
        end

        super(record.freeze)
      end

      def value_for(name)
        return self[name] if self[name]

        default = self.class.attribute(name).default

        @hash[name] ||= default.is_a?(Proc) ? instance_exec(&default) : default
      end

      def to_h
        data = super

        attrs = self.class.attributes
        attrs.reject { |a| a.default.nil? }.each { |attr| data[attr.name] = value_for(attr.name) }

        data = data.except(*self.class.exclude_for_storage)
        attrs
          .select(&:optional?)
          .each { |attr| data.delete(attr.name) if value_for(attr.name).nil? }

        if (comps = self.class.attributes.select(&:component?)).empty?
          data
        else
          comps.reduce(data) { |h, comp| h.merge!(comp.reference_key => send(comp.name).id) }
        end
      end
    end
  end
end
