# frozen_string_literal: true

require "singleton"
require_relative "constants"

module El
  # Like nil except it will answer any message with itself, and a few other differences.
  class NullClass
    include Singleton

    def method_missing(*)
      self
    end

    def &(_other)
      false
    end

    def ^(other)
      return false if other.nil? || other == true

      true
    end
    alias | ^

    def !
      true
    end

    def nil?
      false
    end

    def null?
      true
    end

    def if_null(&block)
      block.call
      self
    end

    def not_null(&_)
      self
    end

    def to_s
      EMPTY_STRING
    end

    def inspect
      "El::Null"
    end

    def to_a
      EMPTY_ARRAY
    end
  end

  Null = NullClass.instance
end

class Object
  def if_null(&_)
    self
  end

  def not_null(&block)
    block.call(self)
    self
  end

  def null?
    false
  end
end
