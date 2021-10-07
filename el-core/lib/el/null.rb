# frozen_string_literal: true

module El
  class NullClass
    def method_missing(*)
      self
    end

    def to_s
      'El::Null'
    end
    alias inspect to_s
  end

  Null = NullClass.new
end
