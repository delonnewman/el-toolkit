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

        def [](attributes)
          new(attributes)
        end
        alias call []

        def to_proc
          ->(attributes) { call(attributes) }
        end

        def canonical_name
          Utils.snakecase(name.split('::').last)
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

      def [](name)
        return super(name) if super(name)

        default = self.class.attribute(name).default

        # FIXME: Remove all muation of @hash
        @hash[name] ||= default.is_a?(Proc) ? instance_exec(&default) : default
      end
      alias value_for []

      def to_proc
        ->(name) { value_for(name) }
      end

      def to_h
        self.class.dehydrator.call(super(), self)
      end

      def ===(other)
        other.is_a?(self.class) && other.id == id
      end
    end
  end
end