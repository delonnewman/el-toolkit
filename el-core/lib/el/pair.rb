require_relative 'sequential'

module El
  class Pair
    include Enumerable

    attr_reader :car, :cdr

    alias this car
    alias first car

    alias other cdr
    alias next cdr
    alias last cdr

    def initialize(car, cdr)
      @car = car
      @cdr = cdr
    end

    def each(&block)
      block.call(car)
      block.call(cdr)
      self
    end
  end
end