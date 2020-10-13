module Examples
  module Views
    class Greet < El::View
      def render html
        html.form(action: '/home', method: 'get') do
          html.input(id: 'greet-name', type: 'text', name: 'name') +
          html.button(type: 'button', class: 'btn btn-primary', on: { click: get_name_and_say_hi(html) }, content: 'Say Hi!')
        end
      end

      private

      def get_name_and_say_hi(html)
        html.select('#greet-name').value
            .then(->(name){ system("say \"Hi #{name}\"") })
      end
    end
  end
end