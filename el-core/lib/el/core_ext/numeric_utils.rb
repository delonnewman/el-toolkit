require_relative '../money'

class Numeric
  def dollars
    El::Money[self, '$']
  end
  alias dollar dollars

  def cents
    El::Money[self, :cents]
  end
end
