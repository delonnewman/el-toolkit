# frozen_string_literal: true

require "uri"

module El
  # Utilities for working with HTTP data
  module HTTPUtils
    module_function

    def parse_form_encoded_data(string, **options)
      parse_nested_hash_keys(URI.decode_www_form(string), **options)
    end

    def parse_nested_hash_keys(hash, symbolize_keys: false)
      hash.each_with_object({}) do |(key, value), h|
        key = key.to_sym if  symbolize_keys && !key.is_a?(Symbol)
        key = key.name   if !symbolize_keys &&  key.is_a?(Symbol)

        parse_nesting_key(key, value, h)
      end
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def parse_nesting_key(key, value, root = {})
      tokens = key.chars

      # states
      read_hash = false
      many_values = false # TODO: add support for collections

      key_ = nil
      buffer = []
      params = root
      tokens.each_with_index do |ch, i|
        # start reading hash
        if ch == "[" && tokens[i + 1] != "]"
          read_hash = true
          unless buffer.length.zero?
            key_ = buffer.join("").to_sym
            buffer = []
            params[key_] ||= {} unless params[key_].is_a?(Hash)
            params = params[key_]
          end
        elsif ch == "]" && read_hash # complete reading hash
          read_hash = false
          key_ = buffer.join("").to_sym
          buffer = []
          if i == tokens.length - 1
            params[key_] = value
          elsif tokens[i + 1] != "[" || tokens[i + 2] != "]"
            params[key_] ||= {}
            params = params[key_]
          end
        elsif ch == "]"
          raise 'Unexpected "]" expecting key or "["'
        else
          buffer << ch
        end
      end

      unless buffer.empty?
        key_ = buffer.join("").to_sym
        params[key_] = value
      end

      root
    end
  end
end
