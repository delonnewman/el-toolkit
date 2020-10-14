module Examples
  module Views
    class Eval < El::View
      def render
        define :code do
          html.textarea(class: 'form-control', placeholder: 'Enter Ruby Code')
        end

        define :output do |value|
          html.code(class: 'mt-2', content: value)
        end

        get(:code) +
          link_to('eval', '#eval', class: 'btn btn-primary mt-2', on: { click: eval_code! }) +
            html.br +
              get(:output)
      end

      private

      def eval_code!
        get(:code) do |element|
          if element.content.nil?
            reset! :output, "Please enter Ruby code above"
          else
            reset! :output, eval(element.content).to_json
          end
        end
      end
    end
  end
end