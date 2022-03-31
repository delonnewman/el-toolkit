# frozen_string_literal: true

module El
  # Data types for use with entities and thier attributes
  module Types
    # Higher-Order Types
    ClassType = lambda { |klass|
      raise 'A class is required' unless klass.is_a?(Class)

      ->(v) { v.is_a?(klass) }
    }

    UnionType = lambda do |*klasses|
      lambda do |v|
        klasses.reduce(false) do |result, klass|
          result || v.is_a?(klass)
        end
      end
    end

    RegExpType = ->(regex) { ->(v) { regex =~ v } }
    SetType = ->(set) { ->(v) { set.include?(v) } }

    UUID_REGEXP = /\A[0-9A-Fa-f]{8,8}-[0-9A-Fa-f]{4,4}-[0-9A-Fa-f]{4,4}-[0-9A-Fa-f]{4,4}-[0-9A-Fa-f]{12,12}\z/.freeze

    def self.aliases
      @aliases ||= ::Hash.new { |_, k| k }
    end

    def self.deref!(ref)
      aliases.fetch(ref) do
        raise "invalid type alias: `#{ref.inspect}'"
      end
    end

    def self.define_alias(name, type)
      aliases[name] = type
    end

    define_alias :string,   ClassType[String]
    define_alias :symbol,   ClassType[Symbol]
    define_alias :boolean,  UnionType[FalseClass, TrueClass]
    define_alias :integer,  ClassType[Integer]
    define_alias :float,    ClassType[Float]
    define_alias :date,     ClassType[Date]
    define_alias :datetime, ClassType[DateTime]
    define_alias :time,     ClassType[Time]
    define_alias :uuid,     RegExpType[UUID_REGEXP]
    define_alias :hash,     ClassType[Hash]
    define_alias :array,    ClassType[Array]
    define_alias :set,      ClassType[Set]
  end
end
