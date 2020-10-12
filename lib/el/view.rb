# frozen_string_literal: true
module El
  class View
    def content
      value = render(El::HTML.new)

      if value.respond_to?(:to_html)
        value.to_html
      elsif value.respond_to?(:each)
        buffer = StringIO.new
        value.each do |element|
          if element.respond_to?(:to_html)
            buffer.puts element.to_html
          else
            buffer.puts element.to_s
          end
        end
        buffer.string
      else
        value.to_s
      end
    end
    alias to_html content
  end
end