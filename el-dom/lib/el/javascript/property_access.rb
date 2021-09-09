module El
  class JavaScript
    class PropertyAccess < Base
      attr_reader :object, :name

      def initialize(object, name)
        @object = object
        @name   = name
      end

      def to_js
        "#{Utils.to_javascript(object)}.#{Utils.to_javascript(name)}"
      end
    end

    class UninternedPropertyAccess < PropertyAccess
      def to_js
        "#{Utils.to_javascript(object)}[#{Utils.to_javascript(name)}]"
      end
    end
  end
end