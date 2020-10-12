module Examples
  module Views
    class Alert < El::View
      def render html
        html.a(href: '#', on: { click: html.alert("Testing!") }, content: "Click Me!")
      end
    end
  end
end