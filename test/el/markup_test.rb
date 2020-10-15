require_relative '../helpers'

module El
  class MarkupTest < Minitest::Test
    def setup
      @html  = Markup[:HTML5]
      @xhtml = Markup[:XHTML]

      @examples = [
        { test: ->(markup) { markup.br.to_markup },
          html: '<br>',
          xhtml: '<br/>' },
        { test: ->(markup) { markup.link(rel: 'stylesheet', href: '/styles/app.css').to_markup },
          html: "<link rel='stylesheet' href='/styles/app.css'>",
          xhtml: '<link rel="stylesheet" href="/styles/app.css"/>' },
        { test: ->(markup) { markup.a(href: '#', required: true, class: %w[ btn btn-primary ]).to_markup },
          html: "<a href='#' required class='btn btn-primary'></a>",
          xhtml: '<a href="#" required="required" class="btn btn-primary"></a>' }
      ]
    end

    def test_is_xml
      assert !@html.xml?, "html is not xml"
      assert @xhtml.xml?, "xhtml is xml"

      assert !@html.br.xml?, "html elements are not xml"
      assert @xhtml.br.xml?, "xhtml elements are xml"

      assert_equal '<br>', @html.br.to_markup
      assert_equal '<br/>', @xhtml.br.to_markup
    end

    def test_examples
      @examples.each do |example|
        assert_equal example[:html], example[:test][@html]
        assert_equal example[:xhtml], example[:test][@xhtml]
      end
    end
  end
end