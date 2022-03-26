module El
  module Entity
    # Higher-Order Types
    ClassType  = ->(klass) { ->(v) { v.is_a?(klass) } }
    RegExpType = ->(regex) { ->(v) { v.is_a?(String) && regex =~ v } }
    SetType = ->(set) { ->(v) { set.include?(v) } }

    DEFAULT_TYPE = ClassType[Object]
    UUID_REGEXP  = /\A[0-9A-Fa-f]{8,8}-[0-9A-Fa-f]{4,4}-[0-9A-Fa-f]{4,4}-[0-9A-Fa-f]{4,4}-[0-9A-Fa-f]{12,12}\z/.freeze
    EMAIL_REGEXP = %r{\A[a-zA-Z0-9!#$%&'*+/=?\^_`{|}~\-]+(?:\.[a-zA-Z0-9!#$%&'*+/=?\^_`{|}~\-]+)*@(?:[a-zA-Z0-9](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?\.)+[a-zA-Z0-9](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?$\z}.freeze

    SPECIAL_TYPES = {
      boolean:  ->(v) { v.is_a?(FalseClass) || v.is_a?(TrueClass) },
      string:   ClassType[String],
      any:      ClassType[BasicObject],
      uuid:     RegExpType[UUID_REGEXP],
      email:    RegExpType[EMAIL_REGEXP],
      # TODO: add more checks here
      password: ->(v) { v.is_a?(String) && v.length > 10 || v.is_a?(BCrypt::Password) }
    }.freeze

    # Represents an attribute of a domain entity. Drives dynamic checks and provides
    # meta objects for reflection.
    class Attribute < HashDelegator
      required :entity, :name, :required, :type

      def define!
        AttributeBuilder.new(self).call

        self
      end

      def entity_class
        self[:entity]
      end

      def required?
        self[:required] == true
      end

      DEFAULT_DISPLAY_ORDER = 99

      def display_order
        d = self[:display]
        return DEFAULT_DISPLAY_ORDER if d == true
        return DEFAULT_DISPLAY_ORDER unless d

        d.fetch(:order) { DEFAULT_DISPLAY_ORDER }
      end

      def display_name
        d = self[:display]
        return Utils.titlecase(name) if d == true
        return Utils.titlecase(name) unless d

        d.fetch(:name) { Utils.titlecase(name.capitalize) }
      end

      def time?
        self[:type].is_a?(Class) && (self[:type] == Time || self[:type] < Time)
      end

      def password?
        self[:type] == :password
      end

      def email?
        self[:type] == :email
      end

      def optional?
        !required?
      end

      def default
        self[:default]
      end

      def type
        t = self[:type]

        return ClassType[t]           if t.is_a?(Class)
        return t                      if t.respond_to?(:call)
        return ClassType[value_class] if t.is_a?(String)
        return RegExpType[t]          if t.is_a?(Regexp)
        return SetType[t]             if t.is_a?(Set)

        SPECIAL_TYPES[t]
      end

      def value_class
        t = self[:type]
        return t if t.is_a?(Class)
        return Utils.constantize(t) if t.is_a?(String)
      end

      def boolean?
        self[:type] == :boolean || self[:type] == FalseClass || self[:type] == TrueClass
      end

      def reference_key
        Utils.reference_key(name.name).to_sym
      end

      def serialize?
        self[:serialize] == true
      end

      def component?
        self[:component] == true
      end

      def many?
        self[:many] == true
      end

      def mutable?
        self[:mutable] == true
      end

      # FIXME: reference mapping should be reviewed
      def resolver
        value_class&.reference_mapping
      end

      def valid_reference?(value)
        return false unless entity?
        return true if value.is_a?(Hash) # TODO: use the value class to validate

        mapping = value_class.reference_mapping
        mapping.keys.any? { |k| k.call(value) }
      end

      def entity?
        klass = value_class
        klass && klass < Entity
      end

      def valid_value?(value)
        type.call(value) || valid_reference?(value)
      end
    end
  end
end
