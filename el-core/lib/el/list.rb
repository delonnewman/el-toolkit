require_relative 'lazy_list'
require_relative 'null'
require_relative 'sequential'

module El
  def self.List(*args)
    return List.empty if args.empty?
    return List.from_array(args) if args.length > 1

    case args[0]
    when nil, Null
      List.empty
    when List
      args[0]
    when Array
      List.from_array(args[0])
    when Range
      List.from_range(args[0])
    when Hash
      List.from_hash(args[0])
    else
      List.empty.cons(args[0])
    end
  end

  class List
    include Enumerable
    include Sequential

    # @return [El::LazyList]
    def self.concat(*lists)
      LazyList do
        non_empty = lists.reject { |x| x.nil? || x.empty? }
        if non_empty.empty?
          nil
        else
          head = non_empty[0]
          tail = non_empty.slice(1, non_empty.length)
          concat(head.rest, *tail) << head.first
        end
      end
    end

    # @return [El::LazyList]
    def self.map(callable, *lists)
      LazyList do
        if lists.all? { |l| l.next.nil? }
          nil
        else
          map(callable, *lists.map(&:rest)) << callable.call(*lists.map(&:first))
        end
      end
    end

    # @return [El::LazyList]
    def self.filter(callable, list)
      LazyList do
        if list.next.nil?
          nil
        elsif block.call(list.first)
          filter(callable, list.rest) << list.first
        else
          filter(callable, list.rest)
        end
      end
    end

    def self.empty
      @empty ||= new(nil, nil, 0)
    end

    def self.from_array(array)
      list = empty
      array.reverse_each do |val|
        list = list << val
      end
      list
    end

    def self.from_range(range)
      list = empty
      x = range.exclude_end? ? range.last.pred : range.last
      until x == range.first.pred
        list = list << x
        x = x.pred
      end
      list
    end

    def self.from_hash(hash)
      from_array(hash.to_a)
    end

    def self.from_string(string)
      list = empty
      string.each_codepoint do |pt|
        list = list << pt
      end
      list
    end

    attr_reader :this, :other, :length

    alias size length

    alias first this
    alias car this
    alias peek this

    alias next other
    alias cdr other
    alias pop other

    def initialize(this, other, length)
      @this  = this
      @other = other
      @length = length
    end

    def empty?
      length.zero?
    end

    # @return [El::List]
    def empty
      self.class.empty
    end

    # @return [El::List]
    def <<(value)
      self.class.new(value, self, length + 1)
    end
    alias cons <<
    alias push <<

    # @return [El::LazyList]
    def +(other)
      self.class.concat(self, other)
    end

    # @return [El::LazyList]
    def map(&block)
      self.class.map(block, self)
    end

    # @return [El::LazyList]
    def filter(&block)
      self.class.filter(block, self)
    end
    alias select filter

    # @return [El::List]
    def each(&block)
      return self if empty?

      val  = first
      list = other

      until list.nil?
        block.call(val)
        val = list.first
        list = list.next
      end

      self
    end

    # @param index [Integer]
    #
    # @return [Object, nil]
    def [](index)
      raise TypeError, "no implicit conversion of #{index.class} to Integer" unless index.is_a?(Integer)
      return first if index.zero?
      return if index >= length

      index = length + index if index.negative?

      val  = first
      list = other

      i = 0
      until i == index
        val = list.first
        list = list.other
        i += 1
      end

      val
    end

    # @return [El::List]
    def to_list
      self
    end

    def inspect
      "El::List(#{to_a.map!(&:inspect).join(", ")})"
    end
    alias to_s inspect
  end
end