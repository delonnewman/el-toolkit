# frozen_string_literal: true

module El
  class JSONResponse
    SUCCESS = { status: 'success' }.freeze
    ERROR   = { status: 'error' }.freeze

    def initialize(response)
      @response = response
    end

    def render(data, status: nil)
      @response.tap do |r|
        r.write data.to_json
        r.set_header 'Content-Type', 'application/json'
        r.status = status if status
      end
    end

    def success(data = nil, status: 200)
      msg = if data
              SUCCESS.merge(data: data)
            else
              SUCCESS
            end

      render(msg, status: status)
    end

    def error(message, status: 500)
      render(ERROR.merge(message: message), status: status)
    end
  end
end
