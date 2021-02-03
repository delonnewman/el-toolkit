module El
  class Document
    module Elemental
      def +(element)
        if ElementList === element
          element.cons(self)
        else
          ElementList.new([self, element])
        end
      end
      alias << +

      def to_markup
        raise 'not implemented'
      end
    end
  end
end
