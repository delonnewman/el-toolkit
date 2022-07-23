module El
  module Sequential
    def this
      raise NotImplementedError, "this is not implemented in #{self.class}"
    end

    def first
      this
    end

    def car
      this
    end

    def other
      raise NotImplementedError, "this is not implemented in #{self.class}"
    end

    def next
      other
    end

    def cdr
      other
    end

    def more
      return empty if other.nil?

      other
    end
    alias rest more

    def <<(_value)
      raise NotImplementedError, "cons is not implemented in #{self.class}"
    end

    def cons(value)
      self << value
    end
  end
end