# frozen_string_literal: true

require_relative '../null'
require_relative 'nil'
require_relative 'boolean'

class Object
  def if_null(&_)
    self
  end
  alias if_nil if_null
  alias if_not if_null
  alias if_false if_null

  def else(&block)
    block.call(self)
    self
  end
  alias if_true else
  alias if_then else
end

module Kernel
  def null
    El::Null
  end
end
