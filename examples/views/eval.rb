module Examples
  module Views
    class Eval < El::View
      def render
        define :output
        define :code do |value|
          html.textarea(class: 'form-control', placeholder: 'Enter Ruby Code', content: value)
        end

        get(:code) +
          link_to('eval', '#eval', class: 'btn btn-primary mt-2', on: { click: eval_code! }) +
            html.br +
              html.code(class: 'mt-2', content: get(:output))
      end

      private

      def eval_code!
        # document
        #   .querySelector('#eval-code')
        #   .value
        #   .then(->(code) { document.querySelector('#eval-output').innerText!(eval(code).to_json) })
        get(:code) do |value|
          update(:output) { value }
        end
      end
    end
  end
end