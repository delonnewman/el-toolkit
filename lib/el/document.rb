require_relative 'document/buffer'
require_relative 'document/utils'
require_relative 'document/schemas'
require_relative 'document/elemental'
require_relative 'document/element'
require_relative 'document/element_list'

module El
  class Document
    class << self
      def [](schema_name, &block)
        markup = from(Schemas.const_get(schema_name.to_sym))

        if block
          buffer = Buffer.new(markup)
          buffer.instance_exec(buffer, &block)
          buffer
        else
          markup
        end
      end

      def from(schema)
        @cache ||= {}
        @cache[schema.hash] ||= new(schema)
      end
    end

    attr_reader :tags

    def initialize(schema = nil)
      if schema
        @schema = schema
        @tags   = schema[:content_elements] + schema[:singleton_elements]
        @xml    = schema[:xml]
      else
        @xml = true
      end
    end

    def xml?
      @xml == true
    end

    def doctype
      @schema && @schema[:doctype]
    end

    def mime_type
      @schema && @schema[:mime_type]
    end

    def singleton?(tag)
      @schema[:singleton_elements].include?(tag)
    end

    def valid_tag?(tag)
      tags.empty? or tags.include?(tag)
    end

    def from_json(string)
      from_data(JSON.parse(string, symbolize_names: true))
    end

    def from_data(data)
      return nil if data.nil?

      case data
      when Hash
        h       = data.dup
        tag     = h.delete(:tag)&.to_sym
        content = h.delete(:content)
        Element.new(tag, h, content: from_data(content), xml: xml?, singleton: singleton?(tag))
      when Array
        ElementList.new(data.map(&method(:from_data)))
      else
        data
      end
    end

    def method_missing(tag, attributes = nil, &block)
      raise "Invalid tag: #{tag}" unless valid_tag?(tag)
      
      Element.new(tag, attributes, content: block, xml: xml?, singleton: singleton?(tag))
    end

    def respond_to?(method, include_all = false)
      return false unless valid_tag?(method)

      # this may benefit from caching
      methods(include_all).include?(method)
    end
  end
end
