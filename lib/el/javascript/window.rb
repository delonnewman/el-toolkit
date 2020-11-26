module El
  class JavaScript
    class Window < Base
      include Chainable

      def document
        Document.instance
      end

      def alert(message)
        FunctionCall.new(Ident[:alert], [message])
      end

      def confirm(message)
        FunctionCall.new(Ident[:confirm], [message])
      end

      def prompt(*args)
        FunctionCall.new(Ident[:prompt], args)
      end

      def to_js
        'window'
      end
    end
  end
end