# frozen_string_literal: true

require "dry-types"

module El
  # Data types for use with entities and thier attributes
  module Types
    include Dry.Types()

    def self.aliases
      @aliases ||= {}
    end

    def self.deref!(ref)
      aliases.fetch(ref) do
        raise "invalid type alias: `#{ref.inspect}'"
      end
    end

    def self.define_alias(name, type)
      aliases[name] = type
    end

    define_alias :string,  Strict::String
    define_alias :boolean, Strict::Boolean
    define_alias :integer, Strict::Integer
  end
end
