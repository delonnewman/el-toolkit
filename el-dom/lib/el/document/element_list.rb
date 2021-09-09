module El
  class Document
    class ElementList
      include Elemental

      attr_reader :elements

      def initialize(elements)
        @elements = elements.freeze
      end

      def cons(element)
        elems = @elements.dup
        elems.shift element

        self.class.new(elems)
      end

      def <<(element)
        elems = @elements.dup
        elems.push(element)

        self.class.new(elems)
      end

      def +(other)
        case other
        when ElementList
          self.class.new(@elements + other.elements)
        else
          elems = @elements.dup
          self.class.new(elems << other)
        end
      end

      def to_markup
        @elements.map(&Utils.method(:to_markup)).join('')
      end
    end
  end
end
