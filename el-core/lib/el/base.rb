# frozen_string_literal: true

require_relative "self_describing"

module El
  # An enhanced base class
  class Base
    extend SelfDescribing

    class << self
      def assign_once(name, ignore: false)
        define_method "#{name}=" do |value|
          current_value = instance_variable_get("@#{name}")

          return value if ignore && current_value
          raise "#{name} has already been set, it cannot be set again." if current_value

          instance_variable_set("@#{name}", value)
        end

        define_method name do
          instance_variable_get("@#{name}")
        end
      end
    end
  end
end
