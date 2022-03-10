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

      # TODO: There's a pattern here, this could be generalized, but we don't want it to cost too much in performance.
      def controller_action?(action)
        action.is_a?(Array) && action[0].is_a?(Class)
      end

      def call_controller_action(action, routable)
        method = action[0].new(routable).method(action[1] || :call)
        return method.call(routable.request) if method.arity.positive?

        method.call
      end

      def single_arity_proc?(action)
        action.is_a?(Proc) && (!action.lambda? || action.arity.positive?)
      end

      def call_single_arity_proc(action, routable)
        routable.instance_exec(routable.request, &action)
      end

      public

      # rubocop:disable Metrics/AbcSize
      # @api private
      def call_action(routable)
        return call_controller_action(action, routable) if controller_action?(action)
        return call_single_arity_proc(action, routable) if single_arity_proc?(action)

        return routable.instance_exec(&action) if action.respond_to?(:to_proc)
        return action.call if action.respond_to?(:arity) && action.arity.zero?

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

      def route_path(*args)
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

      def route_url(root, *args)
        "#{root}/#{route_path(*args)}"
      end
    end
  end
end
