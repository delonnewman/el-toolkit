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
            html.table(class: 'table') {
              [
                html.thead {
                  [ html.th(content: 'Name'),
                    html.th(content: 'Age') ]
                },
                html.tbody {
                  DB[:people].map { |person|
                    html.tr {
                      [ html.td(content: person[:name]),
                        html.td(content: person[:age]) ]
                    }
                  }
                }
              ]
            }
          }
      end

      private


    end
  end
end