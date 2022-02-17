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

        def validate!(entity_data)
          @validator ||= Validator.new(self)
          @validator.call(entity_data)
        end

        def normalizer
          @normalizer ||= DataNomalizer.new(self)
        end

        def dehydrator
          @dehydrator ||= DataDehydrator.new(self)
        end
      end

      def initialize(attributes = EMPTY_HASH)
        record = self.class.normalizer.call(self.class.validate!(attributes), self)

        super(record.freeze)
      end

      def value_for(name)
        return self[name] if self[name]

        default = self.class.attribute(name).default

        # FIXME: Remove all muation of @hash
        @hash[name] ||= default.is_a?(Proc) ? instance_exec(&default) : default
      end

      def to_h
        self.class.dehydrator.call(super(), self)
      end
    end
  end
end
