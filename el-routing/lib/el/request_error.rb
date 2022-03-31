module El
  class RequestError
    def initialize(env, error)
      @env = env
      @error = error
    end

    DEFAULT_RESPONSE = [505, { 'Content-Type' => 'text/html' }, ['Server Error'].freeze].freeze

    def respond(*)
      DEFAULT_RESPONSE
    end
    alias respond! respond

    def error?
      true
    end

    def not_found?
      false
    end
  end
end
