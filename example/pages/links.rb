class Links < El::Page
  title "#{Home.title} - Links"

  def render html
    html.ul do
      (1..10).map do |index|
        html.li do
          html.a href: "##{index}", on: { click: ->{ system "say \"Number #{index}\"" } } do
            html.strong { index }
          end
        end
      end
    end
  end
end