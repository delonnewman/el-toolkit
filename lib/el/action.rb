module El
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
end