module El
  class JavaScript
    class Return < Base
      attr_reader :expression

      def initialize(expression)
        @expression = expression
      end

      def to_js
        "return #{Utils.to_javascript(expression)}"
      end

      def then(_)
        raise "Actions can only be chained after expressions"
      end
    end
  end
end