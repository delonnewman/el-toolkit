# frozen_string_literal: true

require 'el/core_ext/to_param'

module El
  class RouteHelpers < Module
    class << self
      def params_from(args)
        if args.last.is_a?(Hash)
          [args.slice(0, args.size - 1), args.last]
        else
          [args, EMPTY_HASH]
        end
      end

      def path_with_params(base, params)
        return base if params.empty?

        "#{base}?#{params.to_query}"
      end

      def base_path(path_pattern, *args)
        vars = path_pattern.scan(/(:\w+)/)

        if vars.length != args.length
          raise ArgumentError, "wrong number of arguments expected #{vars.length} got #{args.length}"
        end

        return path_pattern if vars.length.zero?

        path = nil
        vars.each_with_index do |str, i|
          val = args[i]
          path = path_pattern.sub(str[0], val.to_param)
        end
        path
      end
    end

    attr_reader :routes

    def initialize(routes)
      super()
      @routes = routes
    end

    def inspect
      "RouteHelpers(#{helper_method_names.map(&:inspect).join(", ")})"
    end

    def extended(object)
      object.instance_variable_set(:@route_helpers, self)
      object.define_method(:helper_method_names) do
        @route_helpers.helper_method_names
      end
    end

    def helper_method_code(base_url)
      routes.map do |r|
        %(
          def #{r.path_method_name}(*args)
            args, params = El::RouteHelpers.params_from(args)
            El::RouteHelpers.path_with_params(El::RouteHelpers.base_path(#{r.path.inspect}, *args), params)
          end

          def #{r.url_method_name}(*args)
            args, params = El::RouteHelpers.params_from(args)
            base = El::RouteHelpers.base_path(#{r.path.inspect}, *args)
            El::RouteHelpers.path_with_params(URI.join(#{base_url.inspect}, base).to_s, params)
          end
        )
      end.join("\n")
    end
    alias code helper_method_code

    def helper_method_names
      @helper_method_names ||= routes.flat_map { |r| [r.path_method_name.to_sym, r.url_method_name.to_sym] }.sort
    end

    def generate_methods!(base_url = '')
      module_eval helper_method_code(base_url), __FILE__, __LINE__

      self
    end
  end
end
