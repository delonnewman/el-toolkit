# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/PerceivedComplexity
# rubocop:disable Metrics/BlockLength

require 'uri'

module El
  # Utilities for working with HTTP data
  module HTTPUtils
    module_function

    # Parse form encoded data into a nested hash / array values.
    #
    # @param string [String] url encoded data
    # @param [Hash] options
    # @option options [Boolean] :symbolize_keys when true all keys will be symbols otherwise they will be strings
    #
    # @example
    #   El::HTTPUtils.parse_form_encoded_data("a=1&b=2&[c][]=3&[c][]=4&[d][e]=10&[d][f]=11") # =>
    #   { :a => "1",
    #     :b => "2",
    #     :c => ["3", "4"],
    #     :d => {
    #        :e => "10",
    #        :f => "11" }}
    def parse_form_encoded_data(string, **options)
      parse_nested_hash_keys(URI.decode_www_form(string), **options)
    end

    def parse_nested_hash_keys(hash, **options)
      hash.each_with_object({}) do |(key, value), h|
        parse_nesting_key(key, value, h, **options)
      end
    end

    # @api private
    def parse_nesting_key(key, value, root = {}, symbolize_keys: true)
      tokens = key.chars

      # states
      read_hash = false
      many_values = false

      key_ = nil
      buffer = []
      params = root
      tokens.each_with_index do |ch, i|
        if ch == '[' && tokens[i + 1] == ']' # start reading collection
          many_values = true
        elsif ch == '[' && tokens[i + 1] != ']' # start reading hash
          read_hash = true
          unless buffer.empty?
            key_ = symbolize_keys ? buffer.join.to_sym : buffer.join
            buffer = []
            params[key_] ||= {} unless params[key_].is_a?(Hash)
            params = params[key_]
          end
        elsif ch == ']' && read_hash # complete reading hash
          read_hash = false
          key_ = symbolize_keys ? buffer.join.to_sym : buffer.join
          buffer = []
          if i == tokens.length - 1
            params[key_] = value
          elsif tokens[i + 1] != '[' || tokens[i + 2] != ']'
            params[key_] ||= {}
            params = params[key_]
          end
        elsif ch == ']' && many_values # complete reading collection
          unless buffer.empty?
            key_ = symbolize_keys ? buffer.join.to_sym : buffer.join
            buffer = []
          end

          raise "Unexpected `[]' a key is required" if key_.nil?

          params[key_] ||= [] unless params[key_].is_a?(Array)
          params[key_] << value
        elsif ch == ']'
          raise 'Unexpected "]" expecting key or "["'
        else
          buffer << ch
        end
      end

      unless buffer.empty?
        key_ = symbolize_keys ? buffer.join.to_sym : buffer.join
        params[key_] = value
      end

      root
    end
  end
end
