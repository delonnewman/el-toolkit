require 'sequel'

module Examples
  module Pages
    class Contacts < Application
      title "#{Home.title} - Contacts"

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
            html.h1(content: 'Contacts') + table + form
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
        html.form(class: 'form-inline') do
          html.input(id: 'crud-name', class: 'form-control ml-2', type: 'text') +
            html.input(id: 'crud-age', class: 'form-control ml-2', type: 'text') +
              link_to('Add', '#', type: 'button', class: 'btn btn-primary ml-2', on: { click: add_row! })
        end
      end

      def add_row!
        document.querySelector('#crud-name').value.then(->(name) {
          document.querySelector('#crud-age').value.then(->(age) {
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