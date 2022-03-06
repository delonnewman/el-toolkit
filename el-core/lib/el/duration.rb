# frozen_string_literal: true

module El
  # Represent a duration of time with a unit
  class Duration
    include Comparable

    attr_reader :magnitude, :unit, :value, :tolerance

    UNITS = {
      millennia:  31_104_000_000,
      centuries:  3_110_400_000,
      decades:    311_040_000,
      years:      31_104_000,
      months:     2_592_000,
      weeks:      604_800,
      days:       86_400,
      half_hours: 1_800,
      hours:      3_600,
      minutes:    60,
      seconds:    1
    }.freeze

    UNITS_SINGULAR = {
      millennia:  'millennium',
      centuries:  'century',
      decades:    'decade',
      years:      'year',
      months:     'month',
      weeks:      'week',
      days:       'day',
      half_hours: 'half_hour',
      hours:      'hour',
      minutes:    'minute',
      seconds:    'second'
    }.freeze

    UNITS_PLURAL = UNITS_SINGULAR.each_with_object({}) do |(k, v), h|
      h[v.to_sym] = k.name
    end

    UNITS_RESOLVE = UNITS_SINGULAR.each_with_object({}) do |(k, v), h|
      h[v.to_sym] = k
      h[k] = UNITS_PLURAL[v.to_sym].to_sym
    end

    class << self
      def valid_unit?(unit, units = UNITS)
        units.include?(unit)
      end

      def validate_unit!(unit, units = UNITS)
        return if valid_unit?(unit, units)

        raise "Invalid unit #{unit.inspect}, expected one of the following: #{units.keys.map(&:inspect).join(", ")}"
      end

      def from_seconds(seconds, unit)
        unit = resolve_unit(unit)
        return new(seconds, unit) if unit == :seconds

        new(Rational(seconds, UNITS[unit]), unit)
      end

      def [](magnitude, unit)
        new(magnitude, unit)
      end

      def singular_unit(unit)
        validate_unit! unit, UNITS_SINGULAR

        UNITS_SINGULAR[unit]
      end

      def plural_unit(plural)
        validate_unit! plural, UNITS_PLURAL

        UNITS_PLURAL[plural]
      end

      def resolve_unit(unit)
        validate_unit! unit, UNITS_RESOLVE

        UNITS_RESOLVE[unit]
      end
    end

    def initialize(magnitude, unit, tolerance: 0.0)
      unit = Duration.resolve_unit(unit)

      @value = magnitude * UNITS[unit]
      @magnitude = magnitude
      @tolerance = tolerance
      @unit = unit
    end

    def add_duration(other)
      unit =
        case UNITS[unit] <=> UNITS[other.unit]
        when -1
          other.unit
        when 0
          other.unit
        when 1
          self.unit
        end

      Duration.from_seconds(value + other.value, unit)
    end

    def convert(unit)
      Duration.from_seconds(value, unit)
    end
    alias as convert

    def +(other)
      case other
      when Duration
        add_duration(other)
      when Time, Date
        other + to_i
      else
        Duration.from_second(to_i + other, unit)
      end
    end

    def *(other)
      case other
      when Duration
        Duration[magnitude * other.convert(unit).magnitude, unit]
      else
        Duration.from_seconds(value * other, unit)
      end
    end

    def ~@
      with_tolerance(0.5)
    end

    def <(other)
      return nil unless other.is_a?(Duration)

      largest_value < other.smallest_value
    end

    def >(other)
      return nil unless other.is_a?(Duration)

      smallest_value > other.largest_value
    end

    def ==(other)
      return nil unless other.is_a?(Duration)

      !(self < other && self > other)
    end

    def <=>(other)
      if self < other
        -1
      elsif self > other
        1
      elsif self == other
        0
      end
    end

    def tolerance_value
      magnitude * tolerance * UNITS[unit]
    end

    def largest_value
      value + tolerance_value
    end

    def smallest_value
      value - tolerance_value
    end

    def with_tolerance(tolerance)
      Duration.new(magnitude, unit, tolerance: tolerance)
    end

    def from_now
      self + Time.now
    end

    def ago
      Time.now - to_i
    end

    def singular_unit
      UNITS_SINGULAR[unit]
    end

    def to_f
      value.to_f
    end

    def to_i
      value.to_i
    end

    def to_r
      value.to_r
    end

    def to_s
      u = magnitude == 1 ? singular_unit : unit
      t = tolerance.zero? ? nil : '~'

      "#{t}#{magnitude.to_f.round(1)} #{u.name.tr("_", " ")}"
    end
  end
end
