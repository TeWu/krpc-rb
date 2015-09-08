require 'krpc/client'

module KRPC
  class << self
  
    # Connect to a kRPC server, generate services API and return Client object. If the block is
    # given, then it's called passing Client object and the connection to kRPC server is closed
    # at the end of the block.
    def connect(name = Client::DEFAULT_NAME, host = Connection::DEFAULT_SERVER_HOST, rpc_port = Connection::DEFAULT_SERVER_RPC_PORT, stream_port = Connection::DEFAULT_SERVER_STREAM_PORT, &block)
      client = Client.new(name, host, rpc_port, stream_port).connect!
      if block_given?
        begin block.call(client) ensure client.close end
      end
      client
    end
    
  end
end

