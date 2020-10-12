module Examples
  module Pages
    class Home < Application
      title "El Examples"
      path "/"

      def render html
        app.view(:navbar) +
          html.main(class: 'container') {
            views.map { |view|
              html.h2(content: view.name.capitalize) +
                html.div(class: 'example mb-3 border rounded bg-light p-3', content: view)
            }
          }
      end

      private

      def views
        views = app.views.reject { |v| v.is?(:navbar) || v.is?(:pagelist) }
      end
    end
  end
end