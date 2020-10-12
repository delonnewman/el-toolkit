module El
  class HTML
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


      CONTENT_ELEMENTS = Set[:a, :script, :table, :tr, :td, :th, :strong].freeze

      SINGLETON_ELEMENTS = Set[:br, :img, :link, :meta, :base, :area, :col, :hr, :input,
                               :param, :source, :track, :wbr, :keygen].freeze

      TAGS = (CONTENT_ELEMENTS + SINGLETON_ELEMENTS).freeze

      def initialize(tag, attributes, content_proc)
        @tag = tag
        @attributes = attributes

        if content_proc
          @content = content_proc.call
        end

        if attributes
          @callbacks = attributes.delete(:on) || {}
          @callbacks.each do |name, cb|
            action = Action.new(cb)
            attributes[:"on#{name}"] = "el.actions.call(#{action.id}, this)"
            El.register_action(action)
          end
        end
      end

      def content
        case @content
        when Element, ElementList
          @content.to_html
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
        attributes.map { |k, v| "#{k}=\"#{v}\"" }.join(' ')
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
        @elements.join('')
      end
      alias to_s to_html
    end
  end
end