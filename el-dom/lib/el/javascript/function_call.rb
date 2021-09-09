module El
  class JavaScript
    class FunctionCall < Base
      attr_reader :function, :arguments

      def initialize(function, arguments)
        @function  = function
        @arguments = arguments
      end

      def to_js
        "#{Utils.to_javascript(function)}(#{arguments.map(&Utils.method(:to_javascript)).join(', ')})"
      end
    end
  end
end