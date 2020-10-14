module Examples
  module Views
    class Hello < El::View
      def render
        link_to "#hello", on: { click: ->{ system "say TESTING!!!" } } do
          html.strong { "TESTING!!!" }
        end
      end
    end
  end
end