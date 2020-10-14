module Examples
  module Views
    class Greet < El::View
      def render
        html.form(class: 'form-inline', action: '#greet', method: 'get') do
          html.input(id: 'greet-name', class: 'form-control', type: 'text', name: 'name') +
            link_to('Say Hi!', '#greet', class: 'btn btn-primary ml-2', on: { click: get_name_and_say_hi! })
        end
      end

      private

      def get_name_and_say_hi!
        document.querySelector('#greet-name').value
                .then(->(name){ system("say \"Hi #{name}\"") })
      end
    end
  end
end