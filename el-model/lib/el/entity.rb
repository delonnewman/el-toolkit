# frozen_string_literal: true

module El
  require_relative 'entity/attribute'
  require_relative 'entity/associations'
  require_relative 'entity/repositories'
  require_relative 'entity/validation'
  require_relative 'entity/types'

  # Represents a domain entity that will be modeled. Provides dynamic checks and
  # meta objects for relfection which is used to drive productivity and inspection tools.
  class Entity < HashDelegator
    transform_keys(&:to_sym)

    extend Core
    include Core
    extend Forwardable
    extend Associations
    extend Repositories
    extend Validation
    extend Types

    class << self
      def has(name, type = Object, **options, &block)
        attribute = Attribute.new({ entity: self, name: name, type: type, required: !block }.merge(options))
        @required_attributes ||= []
        @required_attributes << name if attribute.required?

        if attribute.boolean?
          define_method :"#{name}?" do
            self[name] == true
          end
        end

        if attribute.mutable?
          define_method :"#{name}=" do |value|
            unless attribute.type.call(value)
              raise TypeError, "#{value.inspect}:#{value.class} is not a valid #{attribute[:type]}"
            end

            self[name] = value
          end
        end

        if attribute.component? && (mapping = attribute.resolver).is_a?(Hash)
          # type check the attribute name and mapping for security (see class_eval below)
          unless name.is_a?(Symbol) && name.name =~ /\A\w+\z/
            raise TypeError, "Attribute names should be symbols without special characters: #{name.inspect}:#{name.class}"
          end

          mapping.each do |key, value|
            unless key.respond_to?(:call)
              raise TypeError, "Keys in value mappings should be callable objects: #{key.inspect}:#{key.class}"
            end

            unless value.is_a?(Symbol) && value.name =~ /\A\w+\z/
              raise TypeError, "Values in value mappings should symbols without special characters: #{value.inspect}:#{value.class}"
            end
          end

          define_method name do
            value = @hash[name]
            type = self.class.attribute(name).value_class
            if value.is_a?(type)
              value
            else
              @hash[name.inspect] = type.ensure!(value)
            end
          end
        elsif block
          exclude_for_storage << name
          define_method name do
            instance_exec(self[name], &block)
          end
        elsif attribute.default
          define_method name do
            value_for(name)
          end
        else
          define_method name do
            self[name]
          end
        end

        @attributes ||= {}
        @attributes[name] = attribute

        name
      end

      def attributes(regular = true)
        attrs = @attributes && @attributes.values || EMPTY_ARRAY
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

      def [](init_value)
        ensure!(init_value)
      end
      alias call []

      def to_proc
        ->(attributes) { call(attributes) }
      end

      def canonical_name
        Utils.snakecase(name.split('::').last)
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
            raise TypeError, "For #{self}##{attribute.name} #{value.inspect}:#{value.class} is not a valid #{attribute[:type]}"
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
