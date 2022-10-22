# frozen_string_literal: true

require 'async'
require 'websocket'

require_relative 'subscriber'
require_relative 'web_socket_server'

module El
  class WebSocketSubscriber < Subscriber
    def initialize(host, port, &block)
      @logger = Logger.new($stdout)
      @server = WebSocketServer.new(host, port)
      @callable = block
      super()
    end

    private

    attr_reader :logger, :server, :callable

    # @param [Publisher::Event] event
    def update(event)
      logger.info "Event #{event.inspect} from #{self}:#{self.class}"

      Async do |task|
        task.async do
          client = server.accept
          return if client.nil?

          if callable
            callable.call(client)
          else
            client.write(event.to_json)
          end
        end
      end
    end
  end
end
