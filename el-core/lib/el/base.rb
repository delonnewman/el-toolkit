# frozen_string_literal: true

module El
  # An enhanced base class
  class Base
    class << self
      def attr_assign_once(name)
        define_method "#{name}=" do |value|
          current_value = instance_variable_get("@#{name}")
          raise "#{name} has already been set, it cannot be set again." if current_value

          instance_variable_set("@#{name}", value)
        end
      end
    end
  end
end
