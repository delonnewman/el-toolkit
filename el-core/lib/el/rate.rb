# frozen_string_literal: true

require_relative 'duration'

module El
  # Represent a rate with magnitude and unit
  class Rate
    class << self
      def [](magnitude, unit)
        new(magnitude, unit)
      end
    end

    attr_reader :magnitude, :duration

    def initialize(magnitude, unit)
      @magnitude = magnitude
      @duration = Duration[1, unit]
    end

    def unit
      @duration.singular_unit
    end

    def to_s
      "#{magnitude} / #{unit}"
    end

    def convert(unit)
      Rate[magnitude, unit]
    end

    def for(magnitude, unit, tolerance: 0.0)
      self * Duration.new(magnitude, unit, tolerance: tolerance)
    end

    def *(other)
      raise 'Can only multiply a Rate by a Duration' unless other.is_a?(Duration)

      magnitude * (duration * other).magnitude
    end
  end
end
