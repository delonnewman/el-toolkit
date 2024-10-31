# frozen_string_literal: true

require_relative 'routing/utils'

module El
  # All the data associated with a route
  class RouteData
    # @!attribute method
    #   @return [Symbol]
    attr_reader :method

    # @!attribute path
    #   @return [String]
    attr_reader :path

    # @!attribute options
    #   @return [Hash{Symbol, Object}]
    attr_reader :options

    # @!attribute action
    #   @return [Array<(Class<#call>, Symbol)>, #call]
    attr_reader :action

    # @!attribute parsed_path
    #   @return [{:name => Array<Symbol, nil>, :path => String }]
    attr_reader :parsed_path

    # @param method [Symbol]
    # @param path [String]
    # @param action [Array<(Class<#call>, Symbol)>, #call]
    # @param options [Hash{Symbol, Object}]
    def initialize(method, path, action, options = EMPTY_HASH)
      @method      = method
      @path        = path
      @action      = action
      @options     = options
      @parsed_path = parse_path(path)
      freeze
    end

    private

    NAME_PATTERN = /\A[\w\-%\.]+\z/i
    private_constant :NAME_PATTERN

    def parse_path(str)
      str = str.start_with?('/') ? str[1, str.size] : str
      names = []

      route = str.split(%r{/+}).each_with_index.map do |part, i|
        if part.start_with?(':')
          names[i] = part[1, part.size].to_sym
          NAME_PATTERN
        elsif part.end_with?('*')
          /^#{part[0, part.size - 1]}/i
        else
          part
        end
      end

      { names: names, path: route }
    end

    public

    def route_alias
      path_method_prefix.to_sym
    end

    IGNORED_PREFIXES = Set.new(%w[index show create remove update]).freeze
    IGNORED_SEGMENTS = Set.new(%w[new]).freeze

    def path_method_prefix
      return 'root' if path == '/'
      return options[:as].name if options.key?(:as)

      path_parts = path.split('/')
      return 'root' if path_parts.length.zero? || path_parts[1].start_with?(':')

      parts = []
      if Routing::Utils.controller_action?(action) && !IGNORED_PREFIXES.include?(action[1].name)
        parts << action[1].name
      end

      path.split('/').each do |part|
        next if IGNORED_SEGMENTS.include?(part)

        parts << part.gsub(/\W+/, '_') unless part.start_with?(':') || part.empty?
      end
      parts.join('_')
    end

    def path_method_name
      "#{path_method_prefix}_path"
    end

    def url_method_name
      "#{path_method_prefix}_url"
    end
  end
end
