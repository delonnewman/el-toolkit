module El
  class Markup
    attr_reader :tags

    def initialize(schema)
      @schema = schema
      @tags   = schema[:content_elements] + schema[:singleton_elements]
      @xml    = schema[:xml]
    end

    def xml?
      @xml == true
    end

    def singleton?(tag)
      @schema[:singleton_elements].include?(tag)
    end

    def method_missing(tag, attributes = nil, &block)
      raise "Unknown HTML tag: #{tag}" unless tags.include?(tag)

      Element.new(tag, attributes, content: block, xml: xml?, singleton: singleton?(tag))
    end

    def respond_to?(method, include_all = false)
      return false unless tags.include?(method)

      # this may benefit from caching
      methods(include_all).include?(method)
    end
  end
end