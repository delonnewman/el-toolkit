module El
  class Changeset
    class << self
      def validators
        @validators ||= {}
      end

      def validator(name)
        validators.fetch(name) do
          raise "unknown validator `#{name}`"
        end
      end

      def register_validator(name, validator)
        validators[name] = validator
      end
    end
  end
end

# TODO: add type validator
require_relative 'validators/required_validator'
require_relative 'validators/length_validator'
require_relative 'validators/count_validator'
