require_relative 'sequential'

module El
  def self.LazyList(&block)
    LazyList.new(block)
  end

  class LazyList
    include Enumerable
    include Sequential

    # @param thunk [#call]
    def initialize(thunk)
      raise TypeError, 'lazy proc should respond to :call' unless thunk.respond_to?(:call)

      @thunk = thunk
      @mutex = Mutex.new
    end

    def this
      return if empty?

      to_list.this
    end

    def other
      to_list.other
    end

    def empty?
      to_list.empty?
    end

    def empty
      El::List.empty
    end

    def <<(value)
      to_list << value
    end

    def to_list
      return @list if @list
      return empty if val.nil?

      list = val
      @val = nil
      list = list.send(:val) while list.is_a?(LazyList)
      @list = list
    end

    def inspect
      "El::LazyList(#{take(3).map(&:inspect).join(", ")}, ...)"
    end
    alias to_s inspect

    def each(&block)
      to_list.each(&block)
    end

    private

    def val
      return @val if @val || thunk.nil?

      mutex.synchronize do
        @val = thunk.call
        @thunk = nil
        @val
      end
    end

    attr_reader :thunk, :mutex
  end
end