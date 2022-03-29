# frozen_string_literal: true

module El
  # Represents an attribute of a domain entity. Drives dynamic checks and provides
  # meta objects for reflection.
  class Entity::Attribute < HashDelegator
    requires :name, :type
    optional :default

    def define_on!(entity_class)
      Entity::AttributeBuilder.new(self).call(entity_class)
      self
    end

    def required?
      try(:required) == true
    end

    def optional?
      !required?
    end

    def component?
      try(:component) == true
    end

    def many?
      try(:many) == true
    end

    # TODO: Define sematics around this
    def mutable?
      try(:mutable) == true
    end

    def boolean?
      type == :boolean
    end

    def serialize?
      try(:serialize) == true
    end

    def entity?
      klass = value_class
      klass && klass < Entity
    end

    def value_class
      type = try(:type)
      return type                    if type.is_a?(Class)
      return Utils.constantize(type) if type.is_a?(String)
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
        return ->(v) { klass.validator.call(v).empty? } if entity?

        Types::ClassType[klass]
      else
        type
      end
    end

    def valid_value?(value)
      type_predicate.call(value)
    end

    DEFAULT_DISPLAY_ORDER = 99

    def display_order
      display = try(:display)
      return DEFAULT_DISPLAY_ORDER unless display

      display.fetch(:order, DEFAULT_DISPLAY_ORDER)
    end

    def display_name
      display = try(:display)
      return StringUtils.titlecase(name) unless display

      display.fetch(:order, StringUtils.titlecase(name))
    end
  end
end
