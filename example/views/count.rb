module Examples
  module Views
    class Count < El::View
      def render html
        @count = 0
        [
          html.a(class: 'btn btn-primary mr-1', href: '#', on: { click: ->{ html.select('#count').text!(@count += 1) } }, content: "Count!"),
          html.a(class: 'btn btn-secondary mr-3', href: '#', on: { click: ->{ html.select('#count').text!(@count = 0) } }, content: 'Reset'),
          html.span(id: "count", content: @count)
        ]
      end
    end
  end
end