module Examples
  module Views
    class Greet < El::View
      def render
        html.form(class: 'form-inline', action: '#greet', method: 'get') do
          html.input(id: 'greet-name', class: 'form-control', type: 'text', name: 'name') +
            html.button(type: 'button', class: 'btn btn-primary ml-2', on: { click: get_name_and_say_hi! }, content: 'Say Hi!')
        end
      end

      private

      def get_name_and_say_hi!
        select('#greet-name').value
            .then(->(name){ system("say \"Hi #{name}\"") })
      end
    end
  end
end