module El
  class PredicateString
    def initialize(string)
      @string = string
    end

    def method_missing(method)
      raise NoMethodError, "undefined method `#{method}' for #{self}:#{self.class}" unless respond_to?(method)

      s = method.to_s
      s.slice(0, s.length - 1) == @string
    end

    def respond_to?(method)
      method.to_s.end_with?('?')
    end

    def to_s
      @string
    end

    def inspect
      @string.inspect
    end
  end
end