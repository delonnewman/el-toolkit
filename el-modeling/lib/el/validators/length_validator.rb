# frozen_string_literal: true

require_relative 'base'

module El
  module Validators
    class LengthValidator < Base
      default_message 'length is not valid'

      rule :is do |length, value|
        length == value.length
      end

      rule :min do |length, value|
        value.length >= length
      end

      rule :max do |length, value|
        value.length <= length
      end
    end
  end
end
