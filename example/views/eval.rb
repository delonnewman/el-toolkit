module Examples
  module Views
    class Eval < El::View
      def render
        html.textarea(id: "eval-code", class: 'form-control', placeholder: "Enter Ruby Code") +
          html.button(type: 'button', class: 'btn btn-primary mt-2', on: { click: eval_code! }, content: 'eval') +
            html.br +
              html.code(id: "eval-output", class: 'mt-2')
      end

      private

      def eval_code!
        document.querySelector('#eval-code').value
            .then(->(code){ document.querySelector('#eval-output').innerText!(eval(code).to_json) })
      end
    end
  end
end