require 'krpc/encoder'
require 'krpc/decoder'
require 'socket'

module KRPC

  ##
  # A TCP Connection.
  class Connection
    DEFAULT_SERVER_HOST = "127.0.0.1"
    DEFAULT_SERVER_RPC_PORT = 50000
    DEFAULT_SERVER_STREAM_PORT = 50001
    
    attr_reader :host, :port, :socket
    
    def initialize(host, port)
      @host, @port = host, port
    end
    
    # Connect and perform handshake.
    def connect
      if connected? then raise(ConnectionError, "Already connected")
      else 
        @socket = TCPSocket.open(host, port) 
        begin
          handshake
        rescue Exception => e
          close
          raise e
        end
      end
      self
    end
    
    # Close connection and clean up.
    def close
      if connected?
        socket.close
        cleanup
        true
      else false end
    end
    
    # Return `true` if connected to a server, `false` otherwise.
    def connected?
      !socket.nil? && !socket.closed?
    end
    
    def handshake; end
    def cleanup; end
    
    def protobuf_handshake(type, **attrs)
      send_message PB::ConnectionRequest.new(type: type, **attrs)
      resp = receive_message PB::ConnectionResponse
      raise(ConnectionError, "#{resp.status} -- #{resp.message}") unless resp.status == :OK
      resp
    end
    
    def send(data)
      @socket.send(data, 0)
    end
    def send_message(msg)
      send Encoder.encode_message_with_size(msg)
    end
    
    def recv(maxlen = 1)
      maxlen == 0 ? "" : @socket.read(maxlen)
    end
    def recv_varint
      int_val = 0
      shift = 0
      loop do
        byte = recv.ord
        int_val |= (byte & 0b0111_1111) << shift
        return int_val if (byte & 0b1000_0000) == 0
        shift += 7
        raise(RuntimeError, "too many bytes when decoding varint") if shift >= 64
      end
    end
    def receive_message(msg_type)
      msg_length = recv_varint
      msg_data = recv(msg_length)
      msg_type.decode(msg_data)
    end
  end

  ##
  # TCP connection for sending RPC calls and retrieving its results.
  class RPCConnection < Connection
    attr_reader :name, :client_id
    
    def initialize(name = Client::DEFAULT_NAME, host = DEFAULT_SERVER_HOST, port = DEFAULT_SERVER_RPC_PORT)
      super host, port
      @name = name
    end

    # Perform handshake with kRPC server, obtaining `@client_id`.
    def handshake
      resp = protobuf_handshake(:RPC, client_name: name)
      @client_id = resp.client_identifier
    end
    
    def cleanup
      @client_id = nil
    end
  end

  ##
  # TCP connection for streaming.
  class StreamConnection < Connection
    attr_reader :rpc_connection
    
    def initialize(rpc_connection, host = DEFAULT_SERVER_HOST, port = DEFAULT_SERVER_STREAM_PORT)
      super host, port
      @rpc_connection = rpc_connection
    end
    
    # Perform handshake with kRPC server, sending `client_id` retrieved from `rpc_connection`.
    def handshake
      raise(ConnectionError, "RPC connection must obtain client_id before stream connection can perform valid handshake - closing stream connection") if rpc_connection.client_id.nil? 
      protobuf_handshake(:STREAM, client_identifier: rpc_connection.client_id)
    end
  end
  
end
