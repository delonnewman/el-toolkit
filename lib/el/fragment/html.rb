module El
  class Fragment
    module HTML
      class Base
        attr_reader :html

        def initialize(doctype = :HTML)
          @html = Markup[doctype]
        end
      end

      class Button < Fragment::Button
        include Markup::Elemental

        def render(label: nil)
          html.button(content: label)
        end
      end
    end
  end
end