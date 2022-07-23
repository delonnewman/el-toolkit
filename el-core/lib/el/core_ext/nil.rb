class NilClass
  def if_nil(&block)
    block.call
    self
  end
  alias if_not if_nil
  alias if_false if_nil
  alias else if_nil

  def if_true(&_)
    self
  end
  alias if_then if_true

  def <<(other)
    [other]
  end
end
