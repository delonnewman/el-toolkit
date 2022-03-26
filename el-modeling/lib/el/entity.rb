# frozen_string_literal: true

require 'forwardable'
require 'el/constants'
require 'el/hash_delegator'

require_relative 'types'

module El
  # Represents a domain entity that will be modeled. Provides dynamic checks and
  # meta objects for relfection which is used to drive productivity and inspection tools.
  class Entity < HashDelegator
    transform_keys(&:to_sym)

    require_relative 'entity/attribute_builder'
    require_relative 'entity/validator'
    require_relative 'entity/data_normalizer'
    require_relative 'entity/data_dehydrator'
    require_relative 'entity/class_methods'
    require_relative 'entity/attribute'

    extend Forwardable
    extend ClassMethods

    def_delegators 'self.class', :dehydrator, :normalizer, :attribute, :validate!
    def_delegators :to_h, :to_a

    def initialize(attributes = EMPTY_HASH)
      raise 'El::Entity should not be initialized directly' if instance_of?(El::Entity)

      record = normalizer.call(validate!(attributes), self)

      super(record.freeze)
    end

    def [](name)
      return super(name) if super(name)

      default = attribute(name).default
      default.is_a?(Proc) ? instance_exec(&default) : default
    end
    alias value_for []

    def to_proc
      ->(name) { value_for(name) }
    end

    def to_h
      dehydrator.call(__hash__.dup, self)
    end

    def ===(other)
      other.is_a?(self.class) && other.id == id
    end

    def to_s
      "#<#{self.class} #{to_h.inspect}>"
    end
    alias inspect to_s
  end
end
