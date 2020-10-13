# frozen_string_literal: true
module El
  class View < Base
    include JavaScript

    class << self
      def symbol
        name.to_sym
      end

      def name
        @name ||= to_s.split('::').last.downcase
      end

      def is?(name)
        symbol == name.to_sym
      end
    end

    attr_reader :id, :page

    def initialize(page)
      @page = page
      @id   = object_id
    end

    def html
      @html ||= HTML.new
    end

    def view(name)
      page.view(name)
    end

    def app
      page.app
    end

    def symbol
      self.class.symbol
    end
    alias to_sym symbol

    def name
      symbol.to_s
    end

    def +(other)
      raise TypeError, "cannot concatenate a view with #{other}:#{other.class}" unless other.respond_to?(:to_html)

      HTML::ElementList.new([self, other])
    end

    def content
      value = render

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