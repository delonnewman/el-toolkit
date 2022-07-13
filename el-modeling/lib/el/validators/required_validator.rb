# frozen_string_literal: true

require_relative 'base'

module El
  module Validators
    class RequiredValidator < Base
      default_message 'cannot be blank'

      option :fields

      def call(value)
        errors = {}

        fields.each do |field|
          return errors[field] = default_message if value[field].nil?
        end

        errors
      end
    end
   
    Changeset.register_validator :required, RequiredValidator
  end
end
