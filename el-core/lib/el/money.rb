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

    SYMBOLS = {
      dollars: '$',
      cents:   "\u00A2"
    }.freeze

    CONVERSIONS = {
      dollars: { dollars: 1, cents: 100 },
      cents:   { cents: 1, dollars: Rational(1, 100) }
    }.freeze

    attr_reader :magnitude, :currency

    def initialize(magnitude, currency)
      super()

      @magnitude = magnitude.to_r
      @currency = currency
    end

    def convert_to(other_currency)
      conversion = CONVERSIONS.dig(currency, other_currency)
      raise "Don't know how to convert #{currency} to #{other_currency}" unless conversion

      self.class.new(magnitude * conversion, other_currency)
    end
    alias as convert_to
    alias in convert_to

    def per(unit)
      Rate[self, Duration.resolve_unit(unit.to_sym)]
    end

    def *(other)
      Money[other * magnitude, currency]
    end

    def /(other)
      Money[magnitude / other, currency]
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

    def to_i
      magnitude.round
    end

    def to_f(precision = 2)
      magnitude.round(precision).to_f
    end

    def to_r
      magnitude.to_r
    end

    def to_s
      sym = SYMBOLS[currency]

      if sym
        "#{sym}#{format "%.2f", magnitude}"
      else
        "#{format "%.2f", magnitude} #{currency}"
      end
    end
    alias inspec to_s
  end
end
