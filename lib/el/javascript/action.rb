module El
  class JavaScript
    class Action < El::Action
      def initialize(js, proc)
        super(proc)
        @js = js
      end

      def to_js
        "el.actions.call(#{id}, null, #{Utils.to_javascript(@js)})"
      end
    end
  end
end