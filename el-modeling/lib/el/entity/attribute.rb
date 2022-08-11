# frozen_string_literal: true

module El
  # Represents an attribute of a domain entity. Drives dynamic checks and provides
  # meta objects for reflection.
  class Entity::Attribute < HashDelegator
    requires :name, :namespace, :type
    optional :default, :cardinality, :definition, :reference, :exclude_for_storage, :serialize, :deref

    def define_on!(entity_class)
      Entity::AttributeBuilder.new(self).call(entity_class)
      self
    end

    def required?
      self[:required] == true
    end

    def optional?
      !required?
    end

    def component?
      self[:cardinality] == :many_to_one
    end

    def deref?
      self[:deref] == true
    end

    def reference?
      self[:reference] == true
    end

    def exclude_for_storage?
      self[:exclude_for_storage] == true
    end

    # TODO: Define semantics around this
    def mutable?
      self[:mutable] == true
    end

    def boolean?
      type == :boolean
    end

    def serialize?
      self[:serialize] == true
    end

    def entity?
      klass = value_class
      klass && klass < Entity
    end

    def value_class
      type = self[:type]
      return type if type.is_a?(Class)

      StringUtils.constantize(type) if type.is_a?(String)
    end

    def reference_key
      "#{Inflection.singularize(name.name)}_id"
    end

    def type_predicate
      case type
      when Symbol then Types.aliases[type]
      when Regexp then Types::RegExpType[type]
      when Set    then Types::SetType[type]
      when Class, String
        klass = value_class
        return Types::ClassType[klass] unless entity?

        attribute = self
        ->(v) { klass.validator.call(v, attribute).empty? }
      else
        type
      end
    end

    def valid_value?(value)
      type_predicate.call(value)
    end

    DEFAULT_DISPLAY_ORDER = 99

    def display_order
      display = self[:display]
      return DEFAULT_DISPLAY_ORDER unless display

      display.fetch(:order, DEFAULT_DISPLAY_ORDER)
    end

    def display_name
      display = self[:display]
      return StringUtils.titlecase(name) unless display

      display.fetch(:order, StringUtils.titlecase(name))
    end
  end
end
