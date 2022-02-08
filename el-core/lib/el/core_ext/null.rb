require_relative '../null'

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

  def null
    El::Null
  end
end