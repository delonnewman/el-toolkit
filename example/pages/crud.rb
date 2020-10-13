require 'sequel'

module Examples
  module Pages
    class Crud < Application
      DB = Sequel.sqlite # in memory db

      DB.create_table?(:people) do
        String :name
        Integer :age
      end

      DB[:people].insert(name: 'Jackie', age: 38)
      DB[:people].insert(name: 'Delon', age: 57)

      def render html
        app.view(:navbar) +
          html.div(class: 'container') {
            table(html) + form(html)
          }
      end

      private

      def table(html)
        html.table(class: 'table') do
          [
            html.thead do
              [ html.th(content: 'Name'),
                html.th(content: 'Age') ]
            end,
            html.tbody do
              DB[:people].map do |person|
                row(html, person)
              end
            end
          ]
        end
      end

      def form(html)
        html.form do
          [ html.input(id: 'crud-name', type: 'text'),
            html.input(id: 'crud-age', type: 'text'),
            html.button(type: 'button', on: { click: add_row(html) }, content: 'Add')
          ]
        end
      end

      def add_row(html)
        #lambda do
          html.select('#crud-name').value.then(->(name) {
            html.select('#crud-age').value.then(->(age) {
              DB[:people].insert(name: name, age: age)
            })
          })
        #end
      end

      def row(html, person)
        html.tr do
          html.td(content: person[:name]) + html.td(content: person[:age])
        end
      end
    end # crud
  end # pages
end # examples