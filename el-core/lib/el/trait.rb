# frozen_string_literal: true

require_relative 'self_describing'

module El
  class ::Module
    def uses(trait, &block)
      used_traits << trait
      module_exec(trait, &block)
      include(trait)
    end

    def used_traits
      @used_traits ||= []
    end
  end

  # Use a module as a trait
  #
  # @example
  #   module Callable
  #     extend Trait
  #
  #     requires :call, "When defined will enable this object to behave like a Proc"
  #
  #     def to_proc
  #       proc do |*args|
  #         call(*args)
  #       end
  #     end
  #   end
  #
  #   class Function
  #     uses Callable do
  #       def call
  #         1
  #       end
  #     end
  #   end
  #
  #   Function.used_traits # => [Callable]
  #
  #   class Messenger
  #     def call
  #       # send message
  #     end
  #   end
  #
  #   messenger = Messenger.new
  #   messenger.extend(Callable)
  #   messenger.to_proc # => #<Proc>
  module Trait
    MissingMethodError = Class.new(RuntimeError)

    def requires(method, doc = nil)
      required_methods << method

      add_method_metadata(method, doc: doc, required: true) if doc

      method
    end

    def required_methods
      @required_methods ||= []
    end

    def self.extended(obj)
      obj.extend(SelfDescribing) if obj.is_a?(Module)
    end

    def validate_trait_use(base)
      required_methods.each do |method|
        unless base.method_defined?(method)
          raise MissingMethodError, "`#{method}` is required by #{self} but is missing in #{base}"
        end
      end

      base.instance_methods.each do |method|
        warn "`#{method}` is already defined in #{base}" unless base.method_defined?(method)
      end
    end

    def validate_singleton_trait_use(object)
      required_methods.each do |method|
        unless object.respond_to?(method)
          raise MissingMethodError, "`#{method}` is required by #{self} but is missing in #{object.inspect}:#{object.class}"
        end
      end

      object.methods.each do |method|
        warn "`#{method}` is already defined in #{object.inspect}:#{object.class}" if object.respond_to?(method)
      end
    end

    def extend_object(obj)
      validate_singleton_trait_use(obj)
    end

    # TODO: perhaps use prepend?
    def append_features(base)
      if base.is_a?(Trait)
        required_methods.each do |method|
          base.requires(method, metadata.dig(:methods, method, :doc))
        end
      else
        validate_trait_use(base)
      end
      super
    end
  end
end
