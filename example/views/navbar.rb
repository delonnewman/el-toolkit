class Navbar < El::View
  def render html
    html.nav class: 'navbar navbar-dark bg-dark mb-2' do
      html.a href: "/", class: 'navbar-brand', content: "El"
    end
  end
end