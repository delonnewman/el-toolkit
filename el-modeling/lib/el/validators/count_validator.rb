# frozen_string_literal: true

require_relative 'base'

module El
  module Validators
    class CountValidator < Base
      message 'must be less than ${a}'
      rule :less_than do |a, b|
        a < b
      end

      message 'must be greater than ${a}'
      rule :greater_than do |a, b|
        a > b
      end

      message 'must be less than or equal to ${a}'
      rule :less_than_or_equal_to do |a, b|
        a <= b
      end

      message 'must be greater than or equal to ${a}'
      rule :greater_than_or_equal_to do |a, b|
        a >= b
      end

      message 'must be equal to ${a}'
      rule :equal_to do |a, b|
        a == b
      end

      message 'must be not equal to ${a}'
      rule :not_equal_to do |a, b|
        a != b
      end
    end
    
    Changeset.register_validator :count, CountValidator
  end
end
