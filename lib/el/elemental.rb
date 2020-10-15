module El
  module Elemental
    def +(element)
      if HTML::ElementList === element
        element.cons(self)
      else
        HTML::ElementList.new([self, element])
      end
    end
    alias << +
  end
end