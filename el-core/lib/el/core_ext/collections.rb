require_relative '../list'
require_relative '../lazy_list'
require_relative '../pair'

class Object
  # @param other [#<<]
  def >>(other)
    other << self
  end
end

class Hash
  # @param pair [#first, #last]
  #
  # @return [Hash]
  def <<(pair)
    unless pair.respond_to?(:first) && pair.respond_to?(:last)
      raise TypeError, 'pair must respond to :first and :last'
    end

    store(pair.first, pair.last)

    self
  end

  # @return [El::list]
  def to_list
    El::List.from_hash(self)
  end
end

class Array
  # @return [El::list]
  def to_list
    El::List.from_array(self)
  end
end

class Range
  # @return [El::list]
  def to_list
    El::List.from_range(self)
  end
end

module Kernel
  # @return [El::List]
  def List(*args)
    El::List(*args)
  end

  # @return [El::LazyList]
  def LazyList(&block)
    El::LazyList.new(block)
  end

  # @return [El::Pair]
  def Pair(a, b)
    El::Pair.new(a, b)
  end
end