module El
  module JavaScript
    class Document < Base
      include Singleton
      include Chainable

      def to_js
        'document'
      end
    end
  end
end