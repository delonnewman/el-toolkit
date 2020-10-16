module El
  class Markup
    module Utils
      module_function

      def to_markup(element)
        if element.respond_to?(:to_markup)
          element.to_markup
        elsif element.respond_to?(:to_js)
          "<script>#{element.to_js}</script>"
        else
          element.to_s
        end
      end
    end
  end
end