# frozen_string_literal: true

require_relative 'validators'

module El
  class Changeset
    extend Forwardable

    def_delegators 'self.class', :validator

    require_relative 'changeset/change'

    # @param model [El::Model]
    def initialize(model)
      @model = model
      @validations = []
      @changes = []
    end

    # @param entity [Hash, El::Entity]
    def errors(entity)
      errors = {}

      validations.each do |v|
        errors.merge!(v.call(entity))
      end

      errors
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
    # @return [Changeset]
    def add_validation(name, **options)
      validations << validator(name).new(options)
      self
    end

    # TODO: take change instances of various kinds each will implement the apply method
    # i.e. AddAttributeChange, RemoveAttributeChange, BulkChange
    # @param change [:add, :remove]
    # @param attribute [Symbol]
    # @param options [Hash]
    #
    # @return [Changeset]
    def add_changes(change, attribute, value = nil, **options)
      changes << Change.new(change, attribute, value, options)
      self
    end

    # TODO: apply changesets to model
    # @param entity_class [Class < El::Entity]
    # @param entities [Array<El::Entity>]
    #
    # @return [false, Array<El::Entity>]
    def apply(entity_class, *entities)
      return entities if changes.empty?

      changed = entities.map do |entity|
        changes.reduce(entity.to_h) { |h, ch| ch.apply!(h) }
      end

      return false unless changed.all?(&method(:valid?))

      changed.map(&entity_class.method(:new))
    end

    private

    attr_reader :model, :entity_class, :validations, :changes
  end
end
