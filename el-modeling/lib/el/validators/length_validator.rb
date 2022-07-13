# frozen_string_literal: true

require_relative 'base'

module El
  module Validators
    class LengthValidator < Base
      message do |value|
        case value
        when String
          'should be ${length} characters'
        else
          'should be ${length} items'
        end
      end

      rule :is do |length, value|
        length == value.length
      end

      message do |value|
        case value
        when String
          'should be at least ${length} characters'
        else
          'should be at least ${length} items'
        end
      end

      rule :min do |length, value|
        value.length >= length
      end

      message do |value|
        case value
        when String
          'should be at most ${length} characters'
        else
          'should be at most ${length} items'
        end
      end

      rule :max do |length, value|
        value.length <= length
      end
    end

    Changeset.register_validator :length, LengthValidator
  end
end
