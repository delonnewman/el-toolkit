# frozen_string_literal: true

require 'singleton'
require_relative 'constants'
require_relative 'list'

module El
  # Like nil except it will answer any message with itself, and a few other differences.
  class NullClass
    include Singleton
    include Enumerable
    include Sequential

    def method_missing(method, *)
      name = method.respond_to?(:name) ? method.name : method.to_s
      return if name.end_with?('?')

      self
    end

    def respond_to_missing?(*)
      true
    end

    def each(&_)
      self
    end

    def last
      nil
    end
    alias this last

    def other
      nil
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

    def <<(other)
      to_list << other
    end

    def if_null(&block)
      block.call
      self
    end
    alias if_nil if_null
    alias if_not if_null
    alias if_false if_null
    alias else if_null

    def if_true(&_)
      self
    end
    alias if_then if_true

    def to_s
      EMPTY_STRING
    end

    def inspect
      'null'
    end

    def to_a
      EMPTY_ARRAY
    end

    def to_h
      EMPTY_HASH
    end
    alias to_hash to_h

    def to_list
      List.empty
    end
    alias more to_list
    alias rest to_list
  end

  Null = NullClass.instance
end
