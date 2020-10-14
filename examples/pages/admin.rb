module Examples
  module Pages
    class Admin < Application
      def render
        view(:navbar) +
          html.main(class: 'container') {
            html.h1(content: 'Actions') +
            html.table(class: 'table table-striped') {
              html.thead {
                html.tr {
                  html.th(content: 'ID') +
                    html.th(content: 'Source')
                }
              } +
              html.tbody {
                app.action_registry.actions.map do |action|
                  html.tr do
                    html.td { action.id } +
                      html.td { action.source }
                  end
                end
              }
            }
          }
      end
    end
  end
end