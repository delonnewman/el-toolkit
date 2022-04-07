# frozen_string_literal: true

module El
  # Class methods for El::Entity
  module Entity::ClassMethods
    def define_attribute(name, type = :any, **options, &block)
      raise 'name should be a symbol' unless name.is_a?(Symbol)
      raise 'name should not include special characters' if name.name =~ /\W/

      meta = { name: name, namespace: self.name, type: type }
      meta.merge(definition: block) if block_given?

      attribute = Entity::Attribute.new(meta.merge(options)).define_on!(self)

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
      StringUtils.underscore(name.split('::').last)
    end

    def dereferencer
      @dereferencer ||= Entity::Dereferencer.new(self)
    end

    def validator
      @validator ||= Entity::Validator.new(self)
    end

    def errors(entity_data)
      validator.call(entity_data)
    end

    def valid?(entity_data)
      errors(entity_data).empty?
    end

    def validate!(entity_data)
      errs = errors(entity_data)
      return entity_data if errs.empty?

      raise errs.first[1]
    end

    def normalizer
      @normalizer ||= Entity::DataNomalizer.new(self)
    end

    def dehydrator
      @dehydrator ||= Entity::DataDehydrator.new(self)
    end
  end
end
