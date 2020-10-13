module Examples
  module Views
    class Alert < El::View
      def render
        html.a(href: '#alert', on: { click: alert("Testing!") }, content: "Click Me!")
      end
    end
  end
end