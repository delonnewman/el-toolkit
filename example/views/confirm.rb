module Examples
  module Views
    class Confirm < El::View
      def render
        html.a(href: '/', on: { click: confirm("Are you sure you want to go back home?") }, content: "Click Me!")
      end
    end
  end
end