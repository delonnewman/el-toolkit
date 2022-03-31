# frozen_string_literal: true

module El
  class RequestNotFound
    def initialize(env)
      @env = env
    end

    DEFAULT_RESPONSE = [505, { 'Content-Type' => 'text/html' }, ['Not Found'].freeze].freeze

    def respond(*)
      DEFAULT_RESPONSE
    end
    alias respond! respond

    def not_found?
      true
    end

    def error?
      false
    end
  end
end
