# frozen_string_literal: true

require_relative 'validators'

module El
  class Changeset
    extend Forwardable
    
    def_delegators 'self.class', :validators

    attr_reader :errors, :changes, :constraints, :validations, :action

    def self.from_entity(entity, changes = {})
      ch = from_entity_class(entity.class, entity, changes)
    end

    def self.from_entity_class(klass, data = {}, changes = {}, action: :create)
      ch = new(data, changes, action)

      required = []
      klass.attributes.each do |attr|
        required << attr.name if attr.required?
      end
      ch.validate(:required, required)

      ch
    end

    def initialize(data, changes, action)
      @action = action
      @data = data
      @changes = changes
      @errors = []
      @validations = []
    end

    def valid?
      errors.empty?
    end

    def add_error(key, message, info = EMPTY_HASH)
      errors << [key, message, info]
    end

    def each_error(&block)
      errors.each(&block)
    end

    def each_validation(&block)
      validations.each(&block)
    end

    def validate(validator, options)
      validations << validators.fetch(validator, validator).new(options)
      self
    end

    def apply_action(action); end

    def apply_action!(action); end

    def apply_changes(data)
      
    end

    def remove_change(key); end

    def get_change(key); end

    def get_change!(key); end

    # TODO: Add Entity#change
    def change(entity, changes = EMPTY_HASH); end
  end
end
