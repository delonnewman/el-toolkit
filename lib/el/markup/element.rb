# frozen_string_literal: true
module El
  class Markup
    class Element
      include Elemental

      attr_reader :tag, :attributes

      def initialize(tag, attributes, singleton: false, xml: false, content: nil)
        @tag        = tag
        @attributes = attributes
        @singleton  = singleton
        @xml        = xml

        if attributes && attributes.key?(:content)
          @content = attributes.delete(:content)
        else
          @content = content
        end
      end

      def xml?
        @xml == true
      end

      def content
        @content.respond_to?(:call) ? @content.call : @content
      end

      def with_attributes(attributes)
        self.class.new(tag, self.attributes.merge(attributes), nil, content)
      end

      def has_attributes?
        !@attributes.nil? && !@attributes.empty?
      end

      def singleton?
        @singleton == true
      end

      def >>(list)
        case list
        when ElementList
          list.cons(self)
        when Array
          ElementList.new([self] + list)
        else
          raise "invalid operation for #{list.inspect}:#{list.class}"
        end
      end

      def to_markup
        close = xml? ? XCLOSE : CLOSE
        if has_attributes? && singleton?
          "<#{tag} #{render_attributes}#{close}"
        elsif singleton?
          "<#{tag}#{close}"
        elsif has_attributes?
          "<#{tag} #{render_attributes}>#{render_content}</#{tag}>"
        else
          "<#{tag}>#{render_content}</#{tag}>"
        end
      end

      private

      CLOSE  = '>'
      XCLOSE = '/>'

      def render_attributes
        attributes.map(&method(:render_attribute)).join(' ')
      end

      def render_attribute(attribute)
        return render_xml_attribute(attribute) if xml?
        name, value = attribute

        if value == true or value == false
          name.to_s
        elsif value.is_a?(Enumerable)
          "#{name}='#{value.map { |v| CGI.escapeHTML(v.to_s) }.join(' ')}'"
        else
          "#{name}='#{CGI.escapeHTML(value.to_s)}'"
        end
      end

      def render_xml_attribute(attribute)
        name, value = attribute

        if value == true or value == false
          "#{name}=\"#{name}\""
        elsif value.is_a?(Enumerable)
          "#{name}=\"#{value.map { |v| CGI.escapeHTML(v.to_s) }.join(' ')}\""
        else
          "#{name}=\"#{CGI.escapeHTML(value.to_s)}\""
        end
      end

      def render_content
        if content.respond_to?(:to_markup)
          content.to_markup
        elsif content.respond_to?(:each)
          buffer = StringIO.new
          content.each do |element|
            if element.respond_to?(:to_markup)
              buffer.puts element.to_markup
            else
              buffer.puts CGI.escapeHTML(element.to_s)
            end
          end
          buffer.string
        else
          CGI.escapeHTML(content.to_s)
        end
      end
    end
  end
end