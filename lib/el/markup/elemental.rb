module El
  class Markup
    module Elemental
      def +(element)
        if ElementList === element
          element.cons(self)
        else
          ElementList.new([self, element])
        end
      end
      alias << +
    end
  end
end