class Home < ApplicationPage
  title "El Examples"
  path "/"

  def render html
    html.div class: 'container-fluid' do
      [
        app.view(:navbar),
        html.ul(content: app.pages.map { |page|
          html.li(content: html.a(href: page.path, content: page.name.capitalize))
        })
      ]
    end
  end
end