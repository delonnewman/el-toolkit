class Examples::Views::Navbar < El::View
  def render
    html.nav class: 'navbar navbar-dark bg-dark mb-2', content: [
      html.a(href: "/", class: 'navbar-brand', content: "El Examples"),
      view(:pagelist)
    ]
  end
end