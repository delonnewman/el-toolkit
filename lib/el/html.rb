module El
  class HTML
    include Singleton

    def method_missing(tag, attributes = nil, &block)
      raise "Unknown HTML tag: #{tag}" unless Element::TAGS.include?(tag)

      if block
        Element.new(tag, attributes, block)
      else
        Element[tag, attributes]
      end
    end

    def respond_to?(method, include_all)
      return false unless Element::TAGS.include?(method)

      # this may benefit from caching
      methods(include_all).include?(method)
    end

    class Element
      attr_reader :tag, :attributes


      CONTENT_ELEMENTS = Set[:div, :p, :a, :script, :table, :tr, :td, :th, :strong, :li, :ul, :ol,
                             :h1, :h2, :h3, :h4, :h5, :h6, :span, :nav, :main, :header, :button,
                             :form, :code, :pre, :textarea, :submit, :select, :option, :thead, :tbody].freeze

      SINGLETON_ELEMENTS = Set[:br, :img, :link, :meta, :base, :area, :col, :hr, :input,
                               :param, :source, :track, :wbr, :keygen].freeze

      TAGS = (CONTENT_ELEMENTS + SINGLETON_ELEMENTS).freeze

      def self.cache
        @cache ||= {}
      end

      def self.[](tag, attributes)
        cache[[tag, attributes]] ||= new(tag, attributes)
      end

      def initialize(tag, attributes, proc = nil, content = nil)
        @tag = tag
        @attributes = attributes

        if attributes.key?(:content)
          @content = attributes.delete(:content)
        else
          @content = content
        end

        @proc = proc
      end

      def content
        @content ||= @proc&.call
      end

      def with_attributes(attributes)
        self.class.new(tag, self.attributes.merge(attributes), nil, content)
      end

      def has_attributes?
        !@attributes.nil? or !@attributes.empty?
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
      alias << +

      def to_html
        if has_attributes?
          "<#{tag} #{render_attributes}>#{render_content}</#{tag}>"
        elsif singleton?
          "<#{tag}>"
        else
          "<#{tag}>#{render_content}</#{tag}>"
        end
      end
      alias to_s to_html

      private

      def render_attributes
        attributes.map { |k, v| "#{k}='#{v}'" }.join(' ')
      end

      def render_content
        case content
        when Element, ElementList
          content.to_html
        when Array
          buffer = StringIO.new
          content.each do |element|
            if element.respond_to?(:to_html)
              buffer.puts element.to_html
            else
              buffer.puts element.to_s
            end
          end
          buffer.string
        else
          content.to_s
        end
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

      def +(other)
        case other
        when ElementList
          self.class.new(@elements + other.elements)
        else
          elems = @elements.dup
          self.class.new(elems << other)
        end
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