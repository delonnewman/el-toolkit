module Examples
  module Views
    class Eval < El::View
      def render html
        [
          html.textarea(id: "eval-code", placeholder: "Enter Ruby Code"),
          html.br,
          html.button(type: 'button', class: 'btn btn-primary', on: { click: eval_code(html) }, content: 'eval'),
          html.code(id: "eval-output")
        ]
      end

      private

      def eval_code(html)
        html.select('#eval-code').value
            .then(->(code){ html.select('#eval-output').text!(eval(code).to_json) })
      end
    end
  end
end