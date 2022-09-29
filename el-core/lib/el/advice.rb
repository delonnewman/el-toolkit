# frozen_string_literal: true

module El
  class Advice
    require_relative 'constants'
    require_relative 'advising'

    extend Advising

    class << self
      def advises(advised_class, as: advised_object_method_name(advised_class), delegating: EMPTY_ARRAY)
        if advised_class.is_a?(Symbol)
          self.advised_class = nil
          self.advised_object_alias = advised_class
        else
          self.advised_class = advised_class
          self.advised_object_alias = as
        end

        define_method(advised_object_alias) { advised_object } if advised_object_alias

        return advised_class if delegating.empty?

        require 'forwardable'
        def_instance_delegators(:advised_object, *delegating)

        advised_class
      end

      attr_reader :advised_class, :advised_object_alias

      private

      attr_writer :advised_class, :advised_object_alias

      def advised_object_method_name(advised_class)
        return if advised_class.nil? || !advised_class.is_a?(Class)

        advised_class.name.split('::').last.underscore.to_sym
      end
    end

    attr_reader :advised_object

    def initialize(advised_object)
      @advised_object = advised_object
    end
  end
end
