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

    CONVERSIONS = {
      '$'      => { cents: Rational(1, 100) },
      :dollars => { cents: Rational(1, 100) },
      :cents   => { dollars: 100 }
    }.freeze

    attr_reader :magnitude, :currency

    def initialize(magnitude, currency)
      super()

      @magnitude = magnitude
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
      if currency.is_a?(Symbol)
        "#{format "%.2f", magnitude} #{currency}"
      else
        "#{currency}#{format "%.2f", magnitude}"
      end
    end
  end
end
