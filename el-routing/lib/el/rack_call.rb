# frozen_string_literal: true

require_relative 'invalid_request'
require_relative 'routing/utils'

module El
  # Negotiate Rack invocations
  class RackCall
    include Routing::Utils

    # The default headers for responses
    DEFAULT_HEADERS = {
      'content-type' => 'text/html'
    }.freeze

    def initialize(env, routes, context: nil, suppress_errors: false)
      @env = env
      @routes = routes
      @suppress_errors = suppress_errors
      @context = context
    end

    def suppress_errors? = @suppress_errors
    def raise_errors? = !suppress_errors?

    def request
      @request ||= routes.match(env)
    end

    def invalid?
      request.nil? || request.route.nil?
    end

    # Evaluate the request and return a Rack response while negotiating error handling.
    #
    # @return [Array(Integer, Hash{String, #to_s}, #each)]
    def evaluate
      response
    rescue InvalidRequest
      if context.respond_to?(:not_found)
        context.public_send(:not_found)
      elsif raise_errors?
        raise e
      end
    rescue StandardError => e
      request.errors.write("#{e.class}: #{e.message}\n#{e.backtrace.map { "  #{_1}" }.join("\n")}")
      if context.respond_to?(:error)
        context.public_send(:error, e)
      elsif raise_errors?
        raise e
      end
    end

    # Evaluate the request and return a Rack response.
    #
    # @return [Array(Integer, Hash{String, #to_s}, #each)]
    def response
      res = catch(:halt) { call_action }

      if (is_array_res = res.is_a?(Array) && res[0].is_a?(Integer)) && res.size == 3
        res
      elsif is_array_res && res.size == 2
        [res[0], DEFAULT_HEADERS.dup, res[2]]
      elsif res.is_a?(Integer)
        [res, DEFAULT_HEADERS.dup, EMPTY_ARRAY]
      elsif res.is_a?(Rack::Response)
        res.finish
      elsif res.is_a?(Hash) && res.key?(:status)
        [res[:status], res.fetch(:headers, DEFAULT_HEADERS.dup), res.fetch(:body, EMPTY_ARRAY)]
      elsif res.respond_to?(:each)
        [200, DEFAULT_HEADERS.dup, res]
      else
        [200, DEFAULT_HEADERS.dup, StringIO.new(res.to_s)]
      end
    end

    # Invoke the action in response to this request.
    #
    # @raise [InvalidRequest] if the request does not have an associated route
    def call_action
      raise InvalidRequest, "the request is invalid" if invalid?
      action = request.route.action

      return call_controller_action(action, request, context) if controller_action?(action)
      return action.call unless action.arity.positive?

      action.call(request)
    end

    private

    attr_reader :context, :env, :routes
  end
end
