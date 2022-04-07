# frozen_string_literal: true

require 'el/core_ext/to_param'

module El
  class RouteHelpers < Module
    def initialize(routes, base_url)
      @routes = routes
      @base_url = base_url
      super()
    end

    def inspect
      'RouteHelpers'
    end

    attr_reader :routes, :base_url

    def generate_methods!
      module_eval routes.map { |r|
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
      }.join("\n"), __FILE__, __LINE__

      self
    end

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
  end
end
