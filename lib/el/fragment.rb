# frozen_string_literal: true
module El
  class Fragment
    include JavaScript
    include Elemental

    attr_reader :id, :view

    def initialize(view, value, content)
      @view    = view
      @value   = value
      @id      = object_id
      @content = content || value
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

    def update(proc)
      reset!(proc.call(@value))
    end

    def reset!(value)
      @value = value
      document.querySelector("##{html_id}").innerHTML!(@value)
    end

    def get(proc)
      document.querySelector("##{html_id}").then(proc)
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
  end
end