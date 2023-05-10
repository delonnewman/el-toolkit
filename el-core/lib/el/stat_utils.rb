# frozen_string_literal: true

module El
  # Some utilities for probabilities & statistics
  module StatUtils
    module_function

    # Return a table of the objects in the array and their probability.
    #
    # @see https://github.com/rubyworks/facets/blob/main/lib/core/facets/array/probability.rb#L10
    #
    # @param [Array] array
    # @return [Hash{Any, Float}]
    def probabilities(array)
      table = Hash.new(0.0)
      size = 0.0
      array.each do |e|
        table[e] += 1.0
        size += 1.0
      end
      table.each_key { |e| table[e] /= size }
      table
    end
    alias probability probabilities

    # Return the Shannon entropy of the array
    #
    # @see https://github.com/rubyworks/facets/blob/main/lib/core/facets/array/entropy.rb#L16
    #
    # @param [Array] array
    # @return [Float]
    def entropy(array)
      table = probabilities(array)
      -1.to_f * table.keys.inject(0.to_f) do |sum, i|
        sum + (table[i] * (Math.log(table[i]) / Math.log(2.to_f)))
      end
    end

    # Returns the maximum possible Shannon entropy of the array with given size assuming that it is an
    # "order-0" source (each element is selected independently of the next).
    #
    # @see https://github.com/rubyworks/facets/blob/main/lib/core/facets/array/entropy.rb#L32
    #
    # @param [Array] array
    # @return [Float]
    def ideal_entropy(array)
      unit = 1.0.to_f / array.size
      (-1.to_f * array.size.to_f * unit * Math.log(unit) / Math.log(2.to_f))
    end
  end
end
