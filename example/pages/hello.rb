class Hello < ApplicationPage
  title "#{Home.title} - Hello"

  def render html
    html.a href: "#", on: { click: ->{ system "say TESTING!!!" } } do
      html.strong { "TESTING!!!" }
    end
  end
end