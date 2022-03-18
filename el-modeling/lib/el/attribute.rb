# frozen_string_literal: true

module El
  class Attribute < HashDelegator
    requires :entity_class, :name, :type

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

    def value_class
      type = try(:type)
      return type                 if type.is_a?(Class)
      return Utils.constantize(t) if type.is_a?(String)
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
