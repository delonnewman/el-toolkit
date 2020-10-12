require 'set'
require 'stringio'
require 'parser/current'
require 'unparser'

module El
  ACTIONS = {}

  def self.call_action(id, params = {})
    action = ACTIONS[id]
    if action
      action.call
    end
  end

  def self.register_action(action)
    ACTIONS[action.id] = action
  end

  class Application
    def call(env)

    end
  end

  class Action
    attr_reader :id

    class << self
      def deserialize(string)
        new(nil, string)
      end
    end

    def initialize(proc, source = nil)
      raise "proc and source cannot both be nil" if proc.nil? && source.nil?

      @proc   = proc
      @source = source

      @id = object_id.to_s
    end

    def to_proc
      proc
    end

    def proc
      @proc ||= eval(source)
    end

    def source
      @source ||= serialize
    end

    def serialize
      file, line = proc.source_location
      node = RubyVM::AbstractSyntaxTree.of(proc)
      ast  = Parser::CurrentRuby.parse(IO.read(file))

      source = nil
      find_node(ast, line, node.first_column - 2) { |x| source = x } # set's the last node that it finds
      raise "Failed to serialize action #{proc.inspect}" unless source

      Unparser.unparse(source)
    end

    def call(*args)
      proc.call(*args)
    end

    private

    # NOTE: with this approach we're limited to one callback per line (if they start on the same line they collide)
    def find_node(ast, line, column, tries = 0, &block)
      if ast.nil? || !(AST::Node === ast) || ast.children.empty? || tries > 1000
        nil
      elsif ast.loc.first_line == line && ast.loc.column == column && callable_node?(ast)
        yield ast
      else
        ast.children.map { |node| find_node(node, line, column, tries + 1, &block) }
      end
    end

    CALLABLE_TYPES = Set[:lambda, :proc].freeze

    def callable_node?(node)
      node.type == :block && node.children[0].type == :send && CALLABLE_TYPES.include?(node.children[0].children[1])
    end
  end

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

html = El::HTML.new
(html.script(src: 'runtime.js') +
    html.a(href: "#", on: { click: ->{ system "say TESTING!!!" }, load:  ->{ system "say LOADING!!!" } }) { html.strong { "TESTING!!!" } }).to_html