require 'rouge'

module Examples
  module Pages
    class Home < Application
      title "El Examples"
      path "/"

      style Rouge::Themes::Github.render(scope: '.highlight')

      def render
        app.view(:navbar) +
          html.main(class: 'container') {
            views.map { |view|
              html.h2(name: view.name, content: view.name.capitalize) +
                html.div(class: 'example mb-3 border rounded bg-light p-3', content: view) +
                  html.pre(class: 'highlight p-2 border rounded', content: html.code(content: formatted_source(view)))
            }
          }
      end

      private

      def views
        views = app.views.reject { |v| v.is?(:navbar) || v.is?(:pagelist) }
      end

      def formatted_source(view)
        formatter = Rouge::Formatters::HTML.new
        lexer = Rouge::Lexers::Ruby.new
        formatter.format(lexer.lex(view.class.source))
      end
    end
  end
end