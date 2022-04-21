require_relative 'validators/length_validator'

module El
  class Changeset
    class << self
      def validations
        @validations ||= {}
      end

      def register_validation(name, validator)
        validations[name] = validator
      end

      register_validation :length, Validators::LengthValidator

      validations.each do |name, validator|
        define_method :"validate_#{name}" do |field, opts|
          validators << [field, validator.new(opts)]
        end
      end
    end

    attr_reader :errors, :changes, :constraints, :validations

    def initialize(changes)
      @changes = changes
      @errors = []
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

    def apply_action(action); end

    def apply_action!(action); end

    def apply_changes(data); end

    def remove_change(key); end

    def get_change(key); end

    def get_change!(key); end

    # TODO: Add Entity#change
    def change(entity, changes = EMPTY_HASH); end
  end
end
