module Examples
  module Views
    class Count < El::View
      def render
        define :count, 0
        link_to('Count', '#count', class: 'btn btn-primary mr-1', on: { click: count! }) +
          link_to('Reset!', '#count', class: 'btn btn-secondary mr-3', on: { click: reset_count! }) +
            get(:count)
      end

      private

      def count!
        ->{ update(:count) { |value| value + 1 } }
      end

      def reset_count!
        ->{ reset! :count, 0 }
      end
    end
  end
end