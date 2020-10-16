require 'json'
require 'unparser'

module El
  class Action
    attr_reader :id

    class << self
      def deserialize(json)
        data = JSON.parse(json, symbolize_names: true)
        new(id: data[:id], source: data[:source])
      end
    end

    def initialize(id: nil, source: nil, parent: nil, &block)
      raise "block and source cannot both be nil" if block.nil? && source.nil?

      @proc  = block
      @source = source

      @parent = parent

      @id = id || object_id.to_s
    end

    def proc
      @proc ||= eval(source)
    end
    alias to_proc proc

    def call(*args)
      return proc.call(*args) if @parent.nil?

      result = @parent.call(*args)
      if proc.arity == 1
        proc.call(result)
      else
        proc.call
      end
    end

    def then(proc)
      self.class.new(proc, nil, self)
    end

    def source
      @source ||= serialize_proc
    end

    def serialize!
      source or raise "Failed to serialize action proc #{proc.inspect}"

      { id: id, source: source }.to_json
    end

    private

    def serialize_proc
      file, line = proc.source_location
      node = RubyVM::AbstractSyntaxTree.of(proc)
      ast  = Parser::CurrentRuby.parse(IO.read(file))

      source = nil
      find_node(ast, line, node.first_column - 2) { |x| source = x } # set's the last node that it finds
      return nil unless source

      Unparser.unparse(source)
    end

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
      node.type == :block && node.children[0].type == :send #&& CALLABLE_TYPES.include?(node.children[0].children[1])
    end
  end
end