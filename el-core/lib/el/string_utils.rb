# frozen_string_literal: true

module El
  # A collection of utilities for working with strings
  module StringUtils
    module_function

    # Blantantly stolen from active-support
    def underscore(string)
      return string unless /[A-Z-]|::/ =~ string

      word = string.to_s.gsub("::", "/")
      word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
      word.tr!("-", "_")
      word.downcase!
      word
    end

    def humanize(string)
      string = string.name if string.is_a?(Symbol)
      return string unless /[\W_]/ =~ string

      string.to_s.gsub(/[\W_]/, " ")
    end

    def titlecase(string)
      humanize(string).split(" ").map!(&:capitalize).join(" ")
    end

    # rubocop:disable Metrics/MethodLength
    def camelcase(string, uppercase_first: true)
      string = string.to_s
      string = if uppercase_first
                 string.sub(/^[a-z\d]*/, &:capitalize)
               else
                 string.sub(/^[A-Z\d]*/) do |match|
                   match[0].downcase!
                   match
                 end
               end
      string.gsub!(%r{(?:_|(/))([a-z\d]*)}i) { Regexp.last_match(2).capitalize.to_s }
      string.gsub!("/", "::")
      string
    end

    def dasherize(string)
      string
    end
  end
end
