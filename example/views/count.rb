module Examples
  module Views
    class Count < El::View
      def render
        @count = 0
        html.a(class: 'btn btn-primary mr-1', href: '#count', on: { click: count! }, content: "Count!") +
          html.a(class: 'btn btn-secondary mr-3', href: '#count', on: { click: reset! }, content: 'Reset') +
            html.span(id: "count-value", content: @count)
      end

      private

      def count!
        ->{ document.querySelector('#count-value').innerText!(@count += 1) }
      end

      def reset!
        ->{ document.querySelector('#count-value').innerText!(@count = 0) }
      end
    end
  end
end