# frozen_string_literal: true

require 'forwardable'
require 'el/constants'
require 'el/hash_delegator'

require_relative 'types'

module El
  # Represents a domain entity that will be modeled. Provides dynamic checks and
  # meta objects for relfection which is used to drive productivity and inspection tools.
  # TODO: Untie this from HashDelegator, perhaps should be a MapDelegator?
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
    def_delegators :to_h, :to_a, :to_json, :to_query
    def_delegators :id, :to_param

    def initialize(attributes = EMPTY_HASH)
      raise 'El::Entity should not be initialized directly' if instance_of?(El::Entity)

      record = normalizer.call(validate!(dereferencer.call(attributes)), self).freeze

      super(record)
    end

    # TODO: remove
    alias value_for []

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
  end
end
