require 'minitest/autorun'
require_relative '../../lib/el'

module El
  class MarkupTest < Minitest::Test
    def setup
      @html = Markup.new(Markup::Schemas::HTML5)
      @xhtml = Markup.new(Markup::Schemas::XHTML)
    end

    def test_is_xml
      assert !@html.xml?, "html is not xml"
      assert @xhtml.xml?, "xhtml is xml"

      assert !@html.br.xml?, "html elements are not xml"
      assert @xhtml.br.xml?, "xhtml elements are xml"

      assert_equal '<br>', @html.br.to_html
      assert_equal '<br/>', @xhtml.br.to_html
    end
  end
end