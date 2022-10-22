require 'socket'
require_relative './lib/el/web_socket_server'

server = El::WebSocketServer.new('127.0.0.1', 2000)
loop do
  Thread.start(server.accept) do |client|
    client.write "Hi! #{Time.now}"
    loop do
      response = client.read
      puts response
      client.write "Pong: #{response.inspect}"
    end
    client.close
  end
end
