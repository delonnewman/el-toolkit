module El
  class Changeset
    class << self
      def validators
        @validators ||= {}
      end

      def register_validator(name, validator)
        validators[name] = validator
      end
    end
  end
end

require_relative 'validators/required_validator'
require_relative 'validators/length_validator'
require_relative 'validators/count_validator'
