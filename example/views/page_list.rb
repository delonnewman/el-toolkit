class Examples::Views::PageList < El::View
  def render html
    html.ul(class: 'navbar nav', content: app.pages.map { |page|
      html.li(class: 'nav-item', content:
        html.a(class: 'nav-link', href: page.path, content: page.name.capitalize))
    })
  end
end