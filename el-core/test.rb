require 'digest'
require 'socket'
require 'stringio'
require 'websocket'

require_relative './lib/el/web_socket_server'

# server = El::WebSocketServer.new('127.0.0.1', 2000)
# loop do
#   Thread.start(server.accept) do |client|
#     client.write "Hi! #{Time.now}"
#     loop do
#       response = client.read
#       puts "RESPONSE: #{response.inspect}"
#       client.write "Pong: #{response.inspect}"
#     end
#     client.close
#   end
# end

server = TCPServer.new('localhost', 2000)

loop do
  # Wait for a connection
  socket = server.accept
  warn 'Incoming Request'

  # Read the HTTP request. We know it's finished when we see a line with nothing but \r\n
  handshake = WebSocket::Handshake::Server.new
  handshake << socket.gets until handshake.finished?

  unless handshake.valid?
    warn 'Aborting non-websocket connection'
    socket.close
    next
  end

  warn "Responding to handshake with: #{handshake}"
  socket.write(handshake.to_s)

  warn 'Handshake completed. Starting to parse websocket frame.'

  first_byte = socket.getbyte
  fin = first_byte & 0b10000000
  opcode = first_byte & 0b00001111

  # Our server will only support single-frame, text messages.
  # Raise an exception if the client tries to send anything else.
  raise "We don't support continuations" unless fin
  raise 'We only support opcode 1' unless opcode == 1

  second_byte = socket.getbyte
  is_masked = second_byte & 0b10000000
  payload_size = second_byte & 0b01111111

  raise 'All frames sent to a server should be masked according to the websocket spec' unless is_masked
  raise 'We only support payloads < 126 bytes in length' unless payload_size < 126

  warn "Payload size: #{payload_size} bytes"

  mask = 4.times.map { socket.getbyte }
  warn "Got mask: #{mask.inspect}"

  data = payload_size.times.map { socket.getbyte }
  warn "Got masked data: #{data.inspect}"

  unmasked_data = data.each_with_index.map { |byte, i| byte ^ mask[i % 4] }
  warn "Unmasked the data: #{unmasked_data.inspect}"

  warn "Converted to a string: #{unmasked_data.pack('C*').force_encoding('utf-8').inspect}"

  socket.close
end
