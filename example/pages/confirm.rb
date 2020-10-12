class Confirm < ApplicationPage
  title "#{Home.title} - Confirm"

  def render html
    html.a(href: '/', on: { click: html.confirm("Are you sure you want to go back home?") }, content: "Click Me!")
  end
end