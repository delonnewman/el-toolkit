class FalseClass
  def if_false(&block)
    block.call
    self
  end
  alias else if_false

  def if_true(&_)
    self
  end
  alias if_then if_true
end
