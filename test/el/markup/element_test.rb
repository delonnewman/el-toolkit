require_relative '../../helpers'

module El
  class Document
    class ElementTest < Minitest::Test
      def test_xml_element_generates_xml
        @element = Element.new(:br, nil, xml: true, singleton: true)

        assert_equal '<br/>', @element.to_markup
      end
    end
  end
end
