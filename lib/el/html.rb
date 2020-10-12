module El
  class HTML
    include JavaScript

    def method_missing(tag, attributes = nil, &block)
      raise "Unknown HTML tag: #{tag}" unless Element::TAGS.include?(tag)

      if block
        Element.new(tag, attributes, block)
      else
        Element.new(tag, attributes, nil)
      end
    end

    def respond_to?(method, include_all)
      return false unless Element::TAGS.include?(method)

      # this may benefit from caching
      methods(include_all).include?(method)
    end

    class Element
      attr_reader :tag, :attributes, :content


      CONTENT_ELEMENTS = Set[:div, :p, :a, :script, :table, :tr, :td, :th, :strong, :li, :ul, :ol,
                             :h1, :h2, :h3, :h4, :h5, :h6, :span, :nav, :main, :header, :button].freeze

      SINGLETON_ELEMENTS = Set[:br, :img, :link, :meta, :base, :area, :col, :hr, :input,
                               :param, :source, :track, :wbr, :keygen].freeze

      TAGS = (CONTENT_ELEMENTS + SINGLETON_ELEMENTS).freeze

      def initialize(tag, attributes, content_proc)
        @tag = tag
        @attributes = attributes

        if content_proc.nil?
          @content = attributes.delete(:content)
        else
          @content = content_proc.call
        end

        if @content.respond_to?(:to_html) # not sure why this is needed
          @content = @content.to_html
        end

        if attributes
          @callbacks = attributes.delete(:on) || {}
          @callbacks.each do |name, cb|
            if Proc === cb
              action = Action.new(cb)
              attributes[:"on#{name}"] = "el.actions.call(#{action.id}, this)"
              El.register_action(action)
            elsif cb.respond_to?(:to_js)
              attributes[:"on#{name}"] = cb.to_js
            end
          end
        end
      end

      def content
        case @content
        when Element, ElementList
          @content.to_html
        when Array
          buffer = StringIO.new
          @content.each do |element|
            if element.respond_to?(:to_html)
              buffer.puts element.to_html
            else
              buffer.puts element.to_s
            end
          end
          buffer.string
        else
          @content.to_s
        end
      end

      def has_attributes?
        !@attributes.nil?
      end

      def singleton?
        SINGLETON_ELEMENTS.include?(tag)
      end

      def >>(list)
        list.cons(self)
      end

      def +(element)
        if ElementList === element
          element.cons(self)
        else
          ElementList.new([self, element])
        end
      end

      def to_html
        if has_attributes?
          "<#{tag} #{render_attributes}>#{content}</#{tag}>"
        elsif singleton?
          "<#{tag}>"
        else
          "<#{tag}>#{content}</#{tag}>"
        end
      end
      alias to_s to_html

      private

      def render_attributes
        attributes.map { |k, v| "#{k}='#{v}'" }.join(' ')
      end
    end

    class ElementList
      attr_reader :elements

      def initialize(elements)
        @elements = elements.freeze
      end

      def cons(element)
        elems = @elements.dup
        elems.shift element

        self.class.new(elems)
      end

      def <<(element)
        elems = @elements.dup
        elems.push(element)

        self.class.new(elems)
      end

      def +(list)
        self.class.new(@elements + list.elements)
      end

      def to_html
        @elements.map do |element|
          if element.respond_to?(:to_html)
            element.to_html
          else
            element.to_s
          end
        end.join('')
      end
      alias to_s to_html
    end
  end
end