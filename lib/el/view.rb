# frozen_string_literal: true
module El
  class View
    attr_reader :app

    def initialize(app)
      @app = app
    end

    def name
      @name ||= self.class.to_s.split('::').last.downcase
    end

    def +(other)
      raise TypeError, "cannot concatenate a view with #{other}:#{other.class}" unless other.respond_to?(:to_html)

      HTML::ElementList.new([self, other])
    end

    def is?(name)
      app.view(name) == self
    end

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