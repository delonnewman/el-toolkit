# frozen_string_literal: true

require "set"

module El
  EMPTY_STRING = ""
  EMPTY_ARRAY = [].freeze
  EMPTY_HASH = {}.freeze
  EMPTY_SET = Set.new.freeze
end
