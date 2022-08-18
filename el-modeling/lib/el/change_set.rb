# frozen_string_literal: true

require_relative 'validators'

module El
  class ChangeSet
    extend Forwardable

    def_delegators 'self.class', :validator

    require_relative 'change_set/change'

    def initialize
      @validations = []
      @changes = []
    end

    # @param entity [Hash, El::Entity]
    #
    # @return [Hash{Symbol, String}] error messages on attributes
    def errors(entity)
      errors = {}

      validations.each do |v|
        errors.merge!(v.call(entity))
      end

      errors
    end

    class ValidationError < RuntimeError; end

    def validate!(entity)
      errs = errors(entity)
      return if errs.empty?

      raise ValidationError, "#{errs.first[0]} #{errs.first[1]}"
    end

    # @param entity [Hash, El::Entity]
    def valid?(entity)
      errors(entity).empty?
    end

    # @param entity [Hash, El::Entity]
    def errors?(entity)
      !valid?(entity)
    end

    # @param entity_class [Class]
    def add_all_validations(entity_class)
      required = entity_class.attributes.filter_map { |a| a.name if a.required? }
      add_validation(:required, fields: required)
    end

    # @param name [Symbol]
    #
    # @return [ChangeSet]
    def add_validation(name, **options)
      validations << validator(name).new(options)
      self
    end

    # TODO: take change instances of various kinds each will implement the apply method
    # i.e. AddAttributeChange, RemoveAttributeChange, BulkChange
    # @param change [#run, #apply]
    #
    # @return [ChangeSet]
    def add_change(change)
      changes << change
      self
    end

    # TODO: apply changes to model
    # @param model [El::Model]
    #
    # @return [ChangeSet]
    def apply(model)
      valid = []
      errs  = []
      changes.map do |ch|
        changed = ch.run(model)
        err     = errors(changed)

        errs << err      unless err.empty?
        valid << changed if     err.empty?
      end

      self
    end

    def applied?
      @applied == true
    end

    private

    attr_reader :validations, :changes

    attr_writer :applied
  end
end
