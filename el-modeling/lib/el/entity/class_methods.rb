# frozen_string_literal: true

module El
  # Class methods for El::Entity
  module Entity::ClassMethods
    def define_attribute(name, type = :any, **options, &block)
      meta = { name: name, type: type, required: !block, proc: block }
      attribute = Entity::Attribute.new(meta.merge(options)).define_on!(self)

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
      @validator ||= Entity::Validator.new(self)
      @validator.call(entity_data)
    end

    def normalizer
      @normalizer ||= Entity::DataNomalizer.new(self)
    end

    def dehydrator
      @dehydrator ||= Entity::DataDehydrator.new(self)
    end
  end
end
