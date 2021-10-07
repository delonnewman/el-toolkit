# frozen_string_literal: true

module El
  module Trait
    def required(*methods)
      @required_methods = methods
    end

    def required_methods
      @required_methods
    end

    def self.included(_)
      required_methods.each do |method|
        raise "#{method} must be defined to use this trait: #{self}" unless method_defined?(method)
      end
    end
  end
end
