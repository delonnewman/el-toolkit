# frozen_string_literal: true

module El
  # A collection of functions for performing calculations
  module NumericUtils
    require_relative 'money'

    module_function

    def dollars(magnitude)
      Money[magnitude, '$']
    end
  end
end
