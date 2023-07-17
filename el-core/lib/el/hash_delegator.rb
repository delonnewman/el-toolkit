# frozen_string_literal: true

require 'set'
require_relative 'core_ext/hash'
require_relative 'constants'

module El
  # Thread-safe immutable objects that provide delegation and basic validation to hashes.
  #
  # @example
  #   class Person < HashDelegator
  #     required :first_name, :last_name
  #     transform_keys(&:to_sym)
  #
  #     def name
  #       "#{first_name} #{last_name}"
  #     end
  #   end
  #
  #   person = Person.new(first_name: "Mary", last_name: "Lamb", age: 32)
  #   person.age # => 32
  #   person.name # => "Mary Lamb"
  #
  #   # it supports all non-mutating methods of Hash
  #   person.merge!(favorite_food: "Thai") # => NoMethodError
  #   person.merge(favorite_food: "Thai") # => #<Person { first_name: "Mary", last_name: "Lamb", age: 32 }>
  #
  #   # respects inheritance
  #   class Employee < Person
  #     required :employee_id
  #   end
  #
  #   Employee.new(age: 32, employee_id: 1234) # => Error, first_name attribute is required
  #   Employee.new(first_name: "John", last_name: "Smith", age: 23, employee_id: 3456) # => #<Employee ...>
  # TODO: Make a subclass of Delegator, rename MapDelegator, make HashDelegator mutable
  # perhaps another variant that would be good is AtomicMapDelegator, that wraps an Atom that wraps a Map
  class HashDelegator
    class << self
      # Return required attributes or nil
      #
      # @return [Set]
      def required_attributes
        return @required_attributes if @required_attributes
        return superclass.required_attributes if superclass.respond_to?(:required_attributes)

        EMPTY_SET
      end

      # Specify required attributes
      #
      # @param attributes [Array]
      # @return [Class<HashDelegator>]
      def requires(*attributes)
        @required_attributes =
          if superclass.respond_to?(:required_attributes) && !superclass.required_attributes.nil?
            superclass.required_attributes + attributes.to_set
          else
            attributes.to_set
          end

        self
      end

      # Return optional attributes or nil
      #
      # @return [Set]
      def optional_attributes
        return @optional_attributes if @optional_attributes
        return superclass.optional_attributes if superclass.respond_to?(:optional_attributes)

        EMPTY_SET
      end

      # Specifiy optional attributes
      #
      # @param attributes [Array]
      # @return [Class<HashDelegator>]
      def optional(*attributes)
        @optional_attributes =
          if superclass.respond_to?(:optional_attributes) && !superclass.optional_attributes.nil?
            superclass.optional_attributes + attributes.to_set
          else
            attributes.to_set
          end

        self
      end

      def validate!(data)
        required_attributes&.each do |attribute|
          attribute = key_transformer.call(attribute) if key_transformer
          raise "#{attribute.inspect} is required, but is missing" unless data.key?(attribute)
        end
      end

      # Specify the default value if the value is a Proc or a block is passed
      # each hash's default_proc attribute will be set.
      #
      # @param value [Object] default value
      # @param block [Proc] default proc
      # @return [Class<HashDelegator>]
      def default(value = nil, &block)
        if block
          @default_value = block
          return self
        end

        if value.is_a?(Proc) && value.lambda? && value.arity != 2
          lambda = value
          value  = ->(*args) { lambda.call(*args.slice(0, lambda.arity)) }
        end

        @default_value = value

        self
      end

      # Return the default value
      def default_value
        return @default_value if @default_value

        superclass.default_value if superclass.respond_to?(:default_value)
      end

      # Specify the key transformer
      def transform_keys(&block)
        @key_transformer = block
      end

      # Return the key transformer
      def key_transformer
        return @key_transformer if @key_transformer

        superclass.key_transformer if superclass.respond_to?(:key_transformer)
      end
    end

    # Methods that mutate the internal hash, these cannot be called publicly.
    MUTATING_METHODS = Set[
      :clear,
      :delete,
      :update,
      :delete_if,
      :keep_if,
      :compact!,
      :filter!,
      :merge!,
      :reject!,
      :select!,
      :transform_keys!,
      :transform_values!,
      :default=,
      :default_proc=,
      :compare_by_identity,
      :rehash,
      :replace,
      :initialize_copy,
      :shift,
      :store
    ].freeze

    # Methods that are closed (in the algebraic sense) meaning that
    # they will not remove required keys.
    CLOSED_METHODS = Set[
      :compact,
      :merge
    ].freeze

    # Initialize the HashDelegator with the given hash.
    # If the hash is not frozen it will be duplicated. If a key transformer
    # is specified the hashes keys will be processed with it (duplicating the original hash).
    # The hash will be validated for the existance of the required attributes (note
    # that a key with a nil value still exists in the hash).
    #
    #
    # @param hash [Hash]
    def initialize(hash = EMPTY_HASH)
      if instance_of?(HashDelegator)
        @__hash__ = hash.frozen? ? hash : hash.dup
      else
        @__hash__ = apply_key_transformer(hash)
        set_default!
        self.class.validate!(@__hash__)
      end
    end

    protected

    attr :__hash__

    private

    def apply_key_transformer(hash)
      if key_transformer
        hash.transform_keys(&key_transformer)
      elsif hash.frozen?
        hash
      else
        hash.dup
      end
    end

    def set_default!
      if self.class.default_value.is_a?(Proc)
        @__hash__.default_proc = self.class.default_value
      else
        @__hash__.default = self.class.default_value
      end
    end

    public

    def key_transformer
      self.class.key_transformer
    end

    def required_attributes
      self.class.required_attributes
    end

    def optional_attributes
      self.class.optional_attributes
    end

    def known_attributes
      @known_attributes ||= required_attributes + optional_attributes
    end

    # If the given keys include any known attributes
    # the hash will be duplicated and except will be called
    # on the duplicated hash. Otherwise a new instance of
    # the HashDelegator will be return without the specified keys.
    #
    # @param keys [Array]
    # @return [Hash, HashDelegator]
    def except(*keys)
      common = keys.to_set & known_attributes

      if common.empty?
        self.class.new(@__hash__.except(*keys))
      else
        to_hash.except(*keys)
      end
    end

    # If the given keys include all of the required attributes
    # a new HashDelegator will be returned with only the specified keys.
    # Otherwise a internal hash will be duplicated and slice will
    # be called on the duplicated hash.
    #
    # @param keys [Array]
    # @return [Hash, HashDelegator]
    def slice(*keys)
      required = required_attributes
      common   = keys.to_set & required

      if keys.size == common.size && common.size == required.size
        self.class.new(@__hash__.slice(*keys))
      else
        to_hash.slice(*keys)
      end
    end

    # Return a duplicate of the delegated hash.
    #
    # @return [Hash]
    def to_hash
      @__hash__.dup
    end
    alias to_h to_hash

    def to_s
      "#<#{self.class} #{@__hash__.inspect}>"
    end
    alias inspect to_s

    # Return the value associated with the given key. If a key transformer
    # is special the key will be transformed first. If the key is missing
    # the default value will be return (nil unless specified).
    #
    # @param key
    def [](key)
      xformer = key_transformer

      if xformer
        @__hash__[xformer.call(key)]
      else
        @__hash__[key]
      end
    end

    def key?(name)
      @__hash__.key?(name)
    end

    # Return the numerical hash of the decorated hash.
    #
    # @return [Integer]
    def hash
      @__hash__.hash
    end

    # Return true if the other object has the same numerical hash
    # as this object.
    #
    # @return [Boolean]
    def eql?(other)
      hash == other.hash
    end

    # Return true if the other object has all of this objects required attributes.
    #
    # @param other
    def ===(other)
      return false unless other.is_a?(Hash) || other.is_a?(HashDelegator)

      required = required_attributes

      other.respond_to?(:keys) && (common = other.keys.to_set & required) &&
        common.size == other.keys.size && common.size == required.size
    end

    # Return true if the other object is of the same class and the
    # numerical hash of the other object and this object are equal.
    #
    # @param other
    #
    # @return [Boolean]
    def ==(other)
      other.instance_of?(self.class) && eql?(other)
    end

    # Return true if the superclass responds to the method
    # or if the method is a key of the internal hash or
    # if the hash responds to this method. Otherwise return false.
    #
    # @note DO NOT USE DIRECTLY
    #
    # @see Object#respond_to?
    # @see Object#respond_to_missing?
    #
    # @param method [Symbol]
    # @param include_all [Boolean]
    def respond_to_missing?(method, include_all)
      super || known_attributes.include?(method) || hash_respond_to?(method)
    end

    def try(method, *args, **kwargs, &block)
      return unless respond_to?(method)

      public_send(method, *args, **kwargs, &block)
    end

    # If the method is a key of the internal hash return it's value.
    # If the internal hash responds to the method forward the method
    # to the hash. If the method is 'closed' return a new HashDelegator
    # otherwise return the raw result. If none of these conditions hold
    # call the superclass' method_missing.
    #
    # @see CLOSED_METHODS
    # @see Object#method_missing
    #
    # @param method [Symbol]
    # @param args [Array]
    # @param block [Proc]
    def method_missing(method, *args, &block)
      return @__hash__[method] if known_attributes.include?(method) || @__hash__.key?(method)

      if hash_respond_to?(method)
        result = @__hash__.public_send(method, *args, &block)
        return result unless CLOSED_METHODS.include?(method)

        return self.class.new(result)
      end

      super
    end

    private

    def hash_respond_to?(method)
      !MUTATING_METHODS.include?(method) && @__hash__.respond_to?(method)
    end
  end
end
