module Examples
  module Views
    class Eval < El::View
      def render html
        [
          html.input(type: 'text', id: "eval-code", placeholder: "3 + 4"),
          html.button(type: 'button', on: { click: html.select('body').text!(html.select('#eval-code').value) }, content: 'eval')
        ]
      end
    end
  end
end