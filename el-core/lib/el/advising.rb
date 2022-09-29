# frozen_string_literal: true

module El
  # Compose instances of the named class into the current class.
  #
  # @example
  #   # app/model/survey.rb
  #   class Survey < ApplicationModel
  #     extend El::Advising
  #
  #     # will create an instance method named "editing"
  #     advised_by Survey::Editing, delegating: %i[edited? new_edit current_edit latest_edit]
  #   end
  #
  #   # app/model/survey/editing.rb
  #   class Survey::Editing < El::Advice
  #     advises Survey
  #
  #     def edited? ... end
  #     def new_edit ... end
  #     def current_edit ... end
  #     def latest_edit ... end
  #   end
  module Advising
    require_relative 'constants'

    # @param method_name [Symbol]
    # @param klass [Class]
    # @param args [Array]
    # @param calling [Symbol, nil] (optionally) a named method that will be called after the object is instantiated
    # @param memoize [Boolean] memoize the composed object, defaults to true
    def define_advising_method(method_name, klass, args = EMPTY_ARRAY, calling: nil, memoize: true)
      define_method(method_name) do
        obj = advising_object_memos.fetch(method_name) do
          klass.new(self, *args).tap do |obj|
            advising_object_memos[method_name] = obj if memoize
          end
        end

        calling ? obj.public_send(calling) : obj
      end

      define_advising_object_memos if memoize
      method_name
    end

    # A macro method for declaring how to compose the named class.
    #
    # @param klass [Class]
    # @param args optionally pass arguments to the constructor
    # @param as [Symbol, nil] the name of the generated method, if nil will use the default name
    # @param delegating [Array<Symbol>] a list of methods to delegate to the generated method
    def advised_by(klass, *args, as: nil, delegating: EMPTY_ARRAY, **options)
      method = as || advising_class_method_name(klass)

      define_advising_method(method, klass, args, **options.slice(:calling, :memoize))

      unless delegating.empty?
        require 'forwardable' unless defined?(Forwardable)
        extend Forwardable
        def_instance_delegators(method, *delegating)
      end
    end

    private

    def advising_class_method_name(klass)
      raise "can't generate method name for anonymous class" unless klass.name

      klass.name.split('::').last.underscore.to_sym
    end

    def define_advising_object_memos
      return if method_defined?(:advising_object_memos)

      define_method(:advising_object_memos) do
        @advising_object_memos ||= {}
      end
    end
  end
end
