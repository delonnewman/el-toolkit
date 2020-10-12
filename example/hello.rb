require 'el'

class Hello < El::Page
  def render html
    html.a href: "#", on: { click: ->{ system "say TESTING!!!" } } do
      html.strong { "TESTING!!!" }
    end
  end
end