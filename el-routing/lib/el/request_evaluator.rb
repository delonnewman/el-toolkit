# frozen_string_literal: true

require_relative 'invalid_request'
require_relative 'routing/utils'

module El
  # Encapsulates request evaluation
  class RequestEvaluator
    include Routing::Utils

    # The default headers for responses
    DEFAULT_HEADERS = {
      'content-type' => 'text/html'
    }.freeze

    attr_reader :context

    def initialize(context = nil)
      @context = context
    end

    # Evaluate the request and return a Rack response.
    #
    # @param request [Request]
    #
    # @return [Array(Integer, Hash{String, #to_s}, #each)]
    def evaluate(request)
      res = catch(:halt) { call_action(request) }

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
    #
    # @param request [Request]
    def call_action(request)
      action = request.route&.action
      raise InvalidRequest, "a route has not been set for this request" unless action

      return call_controller_action(action, request, context) if controller_action?(action)
      return action.call unless action.arity.positive?

      action.call(request)
    end
  end
end
