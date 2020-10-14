module Examples
  module Views
    class Confirm < El::View
      def render
        link_to 'Click Me!', '/', on: { click: confirm("Are you sure you want to go back home?") }
      end
    end
  end
end