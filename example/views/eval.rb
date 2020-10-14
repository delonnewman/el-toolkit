module Examples
  module Views
    class Eval < El::View
      def render
        html.textarea(id: "eval-code", class: 'form-control', placeholder: "Enter Ruby Code") +
          link_to('eval', '#', class: 'btn btn-primary mt-2', on: { click: eval_code! }) +
            html.br +
              html.code(id: "eval-output", class: 'mt-2')
      end

      private

      def eval_code!
        -> { document.querySelector('#eval-code').value
              .then(->(code){ document.querySelector('#eval-output').innerText!(eval(code).to_json) }) }
      end
    end
  end
end