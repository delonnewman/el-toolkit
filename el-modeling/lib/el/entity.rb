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
    require_relative 'entity/dereferencer'

    extend Forwardable
    extend ClassMethods

    def_delegators 'self.class', :dehydrator, :normalizer, :attribute, :validate!, :dereferencer
    def_delegators :to_h, :to_a

    def initialize(attributes = EMPTY_HASH)
      raise 'El::Entity should not be initialized directly' if instance_of?(El::Entity)

      record = normalizer.call(validate!(dereferencer.call(attributes)), self).freeze

      super(record)
    end

    def value_for(name)
      __hash__[name]
    end
    alias [] value_for

    def to_proc
      ->(name) { public_send(name) }
    end

    def to_h
      dehydrator.call(__hash__, self)
    end

    def ===(other)
      other.is_a?(self.class) && other.id == id
    end

    def inspect
      "#<#{self.class} #{to_h.inspect}>"
    end
    alias to_s inspect

    def to_ruby
      "#{self.class}[#{to_h.inspect}]"
    end

    def to_json(*args)
      to_h.to_json(*args)
    end

    def to_query(namespace = nil)
      to_h.to_query(namespace)
    end

    def to_param
      id.to_s
    end
  end
end
