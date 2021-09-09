module El
  class JavaScript
    class Document < Base
      include Chainable

      def to_js
        'document'
      end
    end
  end
end
