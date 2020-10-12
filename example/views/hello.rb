module Examples
  module Views
    class Hello < El::View
      def render html
        html.a href: "#", on: { click: ->{ system "say TESTING!!!" } } do
          html.strong { "TESTING!!!" }
        end
      end
    end
  end
end