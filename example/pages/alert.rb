class Alert < El::Page
  title "#{Home.title} - Alert"

  def render html
    html.a(href: '#', on: { click: html.alert("Testing!") }, content: "Click Me!")
  end
end