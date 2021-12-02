# frozen_string_literal: true

module El
  module StringUtils
    module_function

    def parse_nested_hash_keys(hash)
      hash.reduce({}) do |h, (key, value)|
        key = key.is_a?(Symbol) ? key.name : key.to_s
        parse_nesting_key(key, value, h)
      end
    end

    def parse_nesting_key(key, value, root = {})
      tokens = key.chars

      # states
      read_hash = false
      many_values = false # TODO: add support for collections

      key_ = nil; buffer = []; params = root
      tokens.each_with_index do |ch, i|
        # start reading hash
        if ch == '[' && tokens[i + 1] != ']'
          read_hash = true
          unless buffer.length.zero?
            key_ = buffer.join('').to_sym
            buffer = []
            params[key_] ||= {} unless params[key_].is_a?(Hash)
            params = params[key_]
          end
        elsif ch == ']' && read_hash # complete reading hash
          read_hash = false
          key_ = buffer.join('').to_sym
          buffer = []
          if i == tokens.length - 1
            params[key_] = value
          elsif tokens[i + 1] != '[' || tokens[i + 2] != ']'
            params[key_] ||= {}
            params = params[key_]
          end
        elsif ch == ']'
          raise 'Unexpected "]" expecting key or "["'
        else
          buffer << ch
        end
      end

      if buffer.length != 0
        key_ = buffer.join('').to_sym
        params[key_] = value
      end

      root
    end

    # Blantantly stolen from active-support
    def underscore(string)
      return string unless /[A-Z-]|::/ =~ string

      word = string.to_s.gsub('::', '/')
      word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
      word.tr!('-', '_')
      word.downcase!
      word
    end

    def humanize(string)
      string = string.name if string.is_a?(Symbol)
      return string unless /[\W_]/ =~ string

      string.to_s.gsub(/[\W_]/, ' ')
    end

    def titlecase(string)
      humanize(string).split(' ').map!(&:capitalize).join(' ')
    end

    def camelcase(string, uppercase_first: true)
      string = string.to_s
      if uppercase_first
        string = string.sub(/^[a-z\d]*/) { |match| match.capitalize }
      else
        string =
          string.sub(/^[A-Z\d]*/) do |match|
            match[0].downcase!
            match
          end
      end
      string.gsub!(%r{(?:_|(\/))([a-z\d]*)}i) { "#{$2.capitalize}" }
      string.gsub!('/', '::')
      string
    end

    def dasherize(string)
      string
    end
  end
end
