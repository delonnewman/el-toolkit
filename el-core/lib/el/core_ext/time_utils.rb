require_relative '../duration'

class Numeric
  El::Duration::UNITS.each_key do |unit|
    define_method unit do
      El::Duration[self, unit]
    end
  end
end
