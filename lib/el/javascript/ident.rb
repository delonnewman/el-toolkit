module El
  class JavaScript
    class Ident < Base
      def self.[](symbol)
        @cache ||= {}
        @cache[symbol.to_sym] ||= new(symbol)
      end

      def initialize(symbol)
        @symbol = symbol.to_sym
        @name   = symbol.to_s
      end

      def to_js
        @name
      end
    end
  end
end