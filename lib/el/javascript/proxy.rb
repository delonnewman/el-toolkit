module El
  class JavaScript
    class Proxy < Base
      include Chainable

      def initialize(expression)
        @expression = expression
      end

      def to_js
        Utils.to_javascript(@expression)
      end
    end
  end
end