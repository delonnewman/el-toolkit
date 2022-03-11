# frozen_string_literal: true

module El
  module Routable
    # All the data associated with a route
    class Route
      attr_reader :method, :path, :options, :action, :parsed_path

      def initialize(method, path, action, options)
        @method      = method
        @path        = path
        @action      = action
        @options     = options
        @parsed_path = parse_path(path)
      end

      private

      # rubocop:disable Metrics/MethodLength
      def parse_path(str)
        str   = str.start_with?('/') ? str[1, str.size] : str
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
      # rubocop:enable Metrics/MethodLength

      NAME_PATTERN = /\A[\w\-]+\z/i.freeze
      private_constant :NAME_PATTERN

      def controller_action?(action)
        action.is_a?(Array) && action[0].is_a?(Class)
      end

      def call_controller_action(action, routable)
        method = action[0].new(routable).method(action[1] || :call)
        return method.call(routable.request) if method.arity.positive?

        method.call
      end

      public

      # rubocop:disable Metrics/AbcSize
      # @api private
      def call_action(routable, route_params)
        return action.call if action.respond_to?(:arity) && action.arity.zero?
        return call_controller_action(action, routable) if controller_action?(action)
        return routable.instance_exec(*route_params.values, &action) if action.respond_to?(:to_proc)

        action.call(routable.request)
      end
      # rubocop:enable Metrics/AbcSize

      def path_method_prefix
        return 'root' if path == '/'

        parts = []
        path.split('/').each do |part|
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

      def route_url(root, *args)
        args, params = params_from(args)
        path_with_params(URI.join(root, base_path(*args)), params)
      end

      def route_path(*args)
        args, params = params_from(args)
        path_with_params(base_path(*args), params)
      end

      private

      def params_from(args)
        if args.last.is_a?(Hash)
          [args.slice(0, args.size - 1), args.last]
        else
          [args, EMPTY_HASH]
        end
      end

      def path_with_params(base, params)
        return base if params.empty?

        "#{base}?#{URI.encode_www_form(params)}"
      end

      def base_path(*args)
        vars = @path.scan(/(:\w+)/)

        if vars.length != args.length
          raise ArgumentError, "wrong number of arguments expected #{vars.length} got #{args.length}"
        end

        return @path if vars.length.zero?

        path = nil
        vars.each_with_index do |str, i|
          path = @path.sub(str[0], args[i].to_s)
        end
        path
      end
    end
  end
end
