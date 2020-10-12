class Home < El::Page
  title "El Examples"
  path "/"

  def render html
    [
      html.h1(content: "El Examples"),
      html.ul(content: app.pages.map { |page|
        html.li(content: html.a(href: page.path, content: page.name.capitalize))
      })
    ]
  end
end