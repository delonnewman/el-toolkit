module Examples
  module Views
    class Count < El::View
      def render
        @count = 0
        link_to('Count!', '#count', class: 'btn btn-primary mr-1', on: { click: count! }) +
          link_to('Reset!', '#count', class: 'btn btn-secondary mr-3', on: { click: reset! }) +
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