# frozen_string_literal: true

require_relative 'self_describing'

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
      required_methods << method

      add_method_metadata(method, doc: doc, required: true) if doc

      method
    end

    def required_methods
      @required_methods ||= []
    end

    def self.extended(obj)
      if obj.is_a?(Module)
        obj.extend(SelfDescribing)
        return
      end

      required_methods.each do |method|
        raise "`#{method}` must be defined to use the #{self} trait" unless obj.respond_to?(method)
      end

      instance_methods.each do |method|
        warn "`#{method}` is already defined in #{obj.inspect}" if obj.respond_to?(method)
      end
    end

    def self.included(base)
      required_methods.each do |method|
        raise "`#{method}` must be defined to use the #{self} trait" unless base.method_defined?(method)
      end

      instance_methods.each do |method|
        warn "`#{method}` is already defined in #{base}" if base.method_defined?(method)
      end
    end
  end
end
