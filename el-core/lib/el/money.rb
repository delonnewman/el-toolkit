# frozen_string_literal: true

module El
  require_relative 'rate'
  require_relative 'duration'

  # Represent a money value and it's currency
  class Money < Numeric
    class << self
      def [](magnitude, currency)
        new(magnitude, currency)
      end
    end

    attr_reader :magnitude, :currency

    def initialize(magnitude, currency)
      super()

      @magnitude = magnitude
      @currency = currency
    end

    def per(unit)
      Rate[self, Duration.resolve_unit(unit.to_sym)]
    end

    def *(other)
      Money[other * magnitude, currency]
    end
    
    def +(other)
      Money[other + magnitude, currency]
    end

    def -(other)
      Money[other - magnitude, currency]
    end

    def zero?
      magnitude.zero?
    end

    def to_s
      "#{currency}#{format "%.2f", magnitude}"
    end
  end
end
