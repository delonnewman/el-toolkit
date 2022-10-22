# frozen_string_literal: true

require 'socket'
require 'stringio'
require 'websocket'
require 'fiber'

require_relative 'constants'

module El
  class WebSocket
    # @param [TCPSocket] socket
    def initialize(socket, handshake)
      @socket = socket
      @handshake = handshake
    end

    private

    attr_reader :socket, :handshake

    public

    def close
      socket.close
    end

    def read
      bytes, = socket.recvfrom(2000)
      puts "RAW DATA: #{bytes.inspect}"

      if bytes.empty?
        socket.close
        return EMPTY_STRING
      end

      frame = ::WebSocket::Frame::Incoming::Client.new(version: handshake.version)
      frame << bytes
      puts "FRAME: #{frame.inspect}"

      buffer = StringIO.new
      while (f = frame.next)
        if f.type == :close
          socket.close
          return buffer.string
        else
          buffer.write(f)
        end
      end

      puts "BUFFER: #{buffer.string.inspect}"

      buffer.string
    end

    def write(data)
      frame = ::WebSocket::Frame::Outgoing::Client.new(version: handshake.version, data: data, type: :text)
      socket.write(frame)
      socket.flush
    end
  end

  class WebSocketServer
    def self.start(host, port, &block)
      new(host, port).start(&block)
    end

    def initialize(host, port)
      @server = TCPServer.new(host, port)
      @handshake = ::WebSocket::Handshake::Server.new
      @reading = [@server]
      @writing = []
      @clients = {}
    end

    private

    attr_reader :server, :handshake, :reading, :writing, :clients

    public

    # @return [WebSocket]
    def accept
      socket = server.accept
      reading << socket

      handshake << socket.gets until handshake.finished?

      unless handshake.valid?
        socket.close
        return nil
      end

      socket.write(handshake)
      socket.flush
      clients[socket] = WebSocket.new(socket, handshake)
    end

    def start(&block)
      readable, = IO.select(reading, writing, nil)

      (readable || EMPTY_ARRAY).each do |socket|
        if (client = clients[socket]) == server
          client = accept
        else
          msg = client.read
        end

        block.call(client) if client && block_given?
      end
    end

    def stop
      server.close
    end
  end
end
