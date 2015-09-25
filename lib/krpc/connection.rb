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
    
    def send(msg) @socket.send(msg,0) end
    def recv(maxlen = 1) @socket.recv(maxlen) end
    
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
    
    protected #----------------------------------
    
    def trim_fill(str, len, fill_char = "\x00")
      str = str.encode("UTF-8")[0,len]
      str + fill_char*(len-str.length)
    end
  end

  ##
  # TCP connection for sending RPC calls and retrieving it's results.
  class RPCConnection < Connection
    attr_reader :name, :client_id
    
    def initialize(name, host = DEFAULT_SERVER_HOST, port = DEFAULT_SERVER_RPC_PORT)
      super host, port
      @name = name
    end

    # Perform handshake with kRPC server, obtaining `@client_id`.
    def handshake
      send Encoder::RPC_HELLO_MESSAGE
      send trim_fill(name, Encoder::NAME_LENGTH)
      @client_id = recv Decoder::GUID_LENGTH
    end
    
    # Clean up - sets `@client_id` to `nil`.
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
      send Encoder::STREAM_HELLO_MESSAGE
      send rpc_connection.client_id
      resp = recv Decoder::OK_LENGTH
      raise ConnectionError unless resp == Decoder::OK_MESSAGE
    end
  end
  
end
