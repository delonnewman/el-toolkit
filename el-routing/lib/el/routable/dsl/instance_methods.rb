# frozen_string_literal: true

module El
  module Routable
    module DSL
      module InstanceMethods
        # Throw a :halt symbol and pass the response as an argument.
        def halt(*response)
          response = response[0] if response.size == 1
          throw :halt, response
        end

        # Return the value of the RACK_ENV environment variable as a symbol.
        # If the environment variable is not set return :development.
        #
        # @return [Symbol]
        def rack_env
          ENV.fetch('RACK_ENV', :development).to_sym
        end

        # Return a not found response
        def not_found
          [404, RequestEvaluator::DEFAULT_HEADERS.dup, StringIO.new('Not Found')]
        end

        # Return an error response
        def error(_)
          [500, RequestEvaluator::DEFAULT_HEADERS.dup, StringIO.new('Server Error')]
        end
      end
    end
  end
end
