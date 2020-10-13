require 'sequel'

module Examples
  module Pages
    class Crud < Application
      title "#{Home.title} - CRUD"

      DB = Sequel.sqlite # in memory db
      DB.create_table?(:people) do
        String :name
        Integer :age
      end

      DB[:people].insert(name: 'Jackie', age: 38)
      DB[:people].insert(name: 'Delon', age: 57)

      def render
        view(:navbar) +
          html.div(class: 'container') {
            table + form
          }
      end

      private

      def table
        html.table(class: 'table') do
          [
            html.thead do
              html.th(content: 'Name') +
                html.th(content: 'Age')
            end,
            html.tbody do
              DB[:people].map do |person|
                row person
              end
            end
          ]
        end
      end

      def form
        html.form do
          html.input(id: 'crud-name', type: 'text') +
            html.input(id: 'crud-age', type: 'text') +
              html.button(type: 'button', class: 'btn btn-primary', on: { click: add_row! }, content: 'Add')
        end
      end

      def add_row!
        select('#crud-name').value.then(->(name) {
          select('#crud-age').value.then(->(age) {
            DB[:people].insert(name: name, age: age)
          })
        })
      end

      def row(person)
        html.tr do
          html.td(content: person[:name]) + html.td(content: person[:age])
        end
      end
    end # crud
  end # pages
end # examples