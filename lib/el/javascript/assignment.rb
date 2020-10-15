module El
  module JavaScript
    class Assignment < Base
      def initialize(expression, value)
        @expression = expression
        @value = value
      end

      def to_js
        "#{Utils.to_javascript(@expression)} = #{Utils.to_javascript(@value)}"
      end
    end
  end
end