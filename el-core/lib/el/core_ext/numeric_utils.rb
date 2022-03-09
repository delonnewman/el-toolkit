require_relative '../money'

class Numeric
  def dollars
    El::Money[self, '$']
  end
  alias dollar dollars
end
