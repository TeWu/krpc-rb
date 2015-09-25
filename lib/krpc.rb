require 'krpc/client'

module KRPC
  class << self
  
    # Connect to a kRPC server, generate services API and return Client object. If the block is
    # given, then it's called passing Client object and the connection to kRPC server is closed
    # at the end of the block.
    def connect(*args, &block)
      Client.new(*args).connect!(&block)
    end
    
  end
end
