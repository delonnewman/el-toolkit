# frozen_string_literal: true

require_relative "self_describing"

module El
  # Use a module as a trait
  #
  # @example
  #   module Callable
  #     extend Trait
  #
  #     requires :call, "When defined will enable this object to behave like a Proc"
  #
  #     def to_proc
  #       lambda do |*args|
  #         call(*args)
  #       end
  #     end
  #   end
  module Trait
    def requires(method, doc = nil)
      @required_methods ||= []
      @required_methods << method

      add_method_metadata(method, doc: doc, required: true) if doc

      method
    end

    def required_methods
      @required_methods
    end

    def self.extended(base)
      base.extend(SelfDescribing)
    end

    def self.included(_base)
      required_methods.each do |method|
        raise "#{method} must be defined to use this trait: #{self}" unless method_defined?(method)
      end
    end
  end
end
