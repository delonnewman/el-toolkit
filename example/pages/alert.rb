class Alert < ApplicationPage
  title "#{Home.title} - Alert"

  def render html
    html.div class: 'container' do
      html.a(href: '#', on: { click: html.alert("Testing!") }, content: "Click Me!")
    end
  end
end