class Alert < El::Page
  def render html
    html.a(href: '#', on: { click: html.alert("Testing!") }, content: "Click Me!")
  end
end