require_relative '../helpers'

module El
  class MarkupTest < Minitest::Test
    def setup
      @html = Markup[:HTML5]
      @xhtml = Markup[:XHTML]
    end

    def test_is_xml
      assert !@html.xml?, "html is not xml"
      assert @xhtml.xml?, "xhtml is xml"

      assert !@html.br.xml?, "html elements are not xml"
      assert @xhtml.br.xml?, "xhtml elements are xml"

      assert_equal '<br>', @html.br.to_markup
      assert_equal '<br/>', @xhtml.br.to_markup
    end
  end
end