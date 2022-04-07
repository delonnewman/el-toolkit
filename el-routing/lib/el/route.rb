# frozen_string_literal: true

module El
  # All the data associated with a route
  class Route
    attr_reader :method, :path, :options, :action, :parsed_path

    def initialize(method, path, action, options = EMPTY_HASH)
      @method      = method
      @path        = path
      @action      = action
      @options     = options
      @parsed_path = parse_path(path)
    end

    private

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
    NAME_PATTERN = /\A[\w\-]+\z/i.freeze
    private_constant :NAME_PATTERN

    def controller_action?(action)
      action.is_a?(Array) && action[0].is_a?(Class) && action[1].is_a?(Symbol)
    end

    def call_controller_action(action, routeable, request)
      action[0].call(routeable, request).call(action[1])
    end

    public

    # @api private
    def call_action(routable, request)
      return call_controller_action(action, routable, request) if controller_action?(action)
      return action.call unless action.arity.positive?

      action.call(request)
    end

    def route_alias
      path_method_prefix.to_sym
    end

    IGNORED_PREFIXES = %w[index show create remove update].to_set.freeze
    IGNORED_SEGMENTS = %w[new].to_set.freeze

    def path_method_prefix
      return 'root' if path == '/'
      return options[:as].name if options.key?(:as)

      path_parts = path.split('/')
      return 'root' if path_parts.length.zero? || path_parts[1].start_with?(':')

      parts = []
      parts << action[1].name if !IGNORED_PREFIXES.include?(action[1].name) && controller_action?(action)

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
