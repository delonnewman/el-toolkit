module Examples
  module Views
    class Alert < El::View
      def render
        link_to 'Click Me!', '#alert', on: { click: alert("Testing!") }
      end
    end
  end
end