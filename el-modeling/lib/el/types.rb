# frozen_string_literal: true

require 'dry-types'

module El
  # Data types for use with entities and thier attributes
  module Types
    include Dry.Types()

    # Higher-Order Types
    ClassType = ->(klass) { ->(v) { v.is_a?(klass) } }
    RegExpType = ->(regex) { ->(v) { v.is_a?(String) && regex =~ v } }
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

    define_alias :string,   Coercible::String
    define_alias :symbol,   Coercible::Symbol
    define_alias :boolean,  Params::Bool
    define_alias :integer,  Coercible::Integer
    define_alias :float,    Coercible::Float
    define_alias :decimal,  Coercible::Decimal
    define_alias :date,     Params::Date
    define_alias :datetime, Params::DateTime
    define_alias :time,     Params::Time
    define_alias :uuid,     RegExpType[UUID_REGEXP]
    define_alias :hash,     Strict::Hash
    define_alias :array,    Strict::Array
  end
end
