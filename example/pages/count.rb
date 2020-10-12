class Count < El::Page
  def render html
    @count = 0
    [
      html.a(href: '#', on: { click: ->{ html.select('#count').text!(@count += 1) } }, content: "Count!"),
      html.span(id: "count", content: @count)
    ]
  end
end