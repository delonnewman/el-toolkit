module Examples
  module Views
    class Links < El::View
      def render
        html.ul(class: 'list-group') do
          (1..10).map do |index|
            html.li(class: 'list-group-item') do
              html.a href: "#links?n=#{index}", on: { click: ->{ system "say \"Number #{index}\"" } } do
                html.strong { "Number #{index}" }
              end
            end
          end
        end
      end # render
    end # links
  end # pages
end # examples