# frozen_string_literal: true
module El
  class Fragment
    include JavaScript

    attr_reader :id, :view

    def initialize(view, value, content)
      @view    = view
      @value   = value
      @id      = object_id
      @content = content
    end

    def html_id
      "fragment-#{id}"
    end

    def content
      return @content unless @content.respond_to?(:arity) && @content.respond_to?(:call)

      if @content.arity == 1
        @content.call(@value)
      else
        @content.call
      end
    end

    def render
      content = self.content
      case content
      when HTML::Element
        content.with_attributes(id: html_id).to_html
      else
        content = self.content
        content = content.respond_to?(:to_html) ? content.to_html : content.to_s 
        "<span id=\"#{html_id}\">#{content}</span>"
      end
    end
    alias to_html render

    def update(proc)
      @value = proc.call(@value)
    end

    def get(&block)
      document.querySelector("##{html_id}").then(block)
    end
  end
end