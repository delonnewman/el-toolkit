# frozen_string_literal: true
module El
  class Element
    include Elemental

    attr_reader :tag, :attributes

    def self.from_data(data)
      return nil if data.nil?

      case data
      when Hash
        h       = data.dup
        tag     = h.delete(:tag)
        content = h.delete(:content)
        new(tag, h, nil, from_data(content))
      when Array
        ElementList.new(data.map(&method(:from_data)))
      else
        data
      end
    end

    def self.cache
      @cache ||= {}
    end

    def self.[](tag, attributes)
      cache[[tag, attributes]] ||= new(tag, attributes)
    end

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
      @xml = true
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

    def to_html
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
      attributes.map { |k, v| "#{k}='#{v}'" }.join(' ')
    end

    def render_content
      if content.respond_to?(:to_html)
        content.to_html
      elsif content.respond_to?(:each)
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
end