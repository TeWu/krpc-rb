require 'thread'

module KRPC
  module Streaming

    class StreamsManager
      attr_reader :client
      
      def initialize(client)
        @client = client
        @streams = {}
        @streams_mutex = Mutex.new
        @streaming_thread = Thread.new {}
      end
    
      # Send a streaming request, create related Stream object and return it. If identical Stream
      # already exists, dont create new Stream and return the existing one.
      def create_stream(request, return_type, method, *args, **kwargs)
        raise RuntimeError("Cannot stream a property setter") if method.name.to_s.end_with? '='
        id = client.krpc.add_stream(request)
        @streams_mutex.synchronize do
          if @streams.include? id
            @streams[id]
          else
            value = method.call(*args, **kwargs)
            @streams[id] = Stream.new(self, id, return_type, value, method, *args, **kwargs)
          end
        end
      end
      
      # Remove a streaming request and disactivate the Stream object. Returns `true` if
      # streaming request is removed or `false` if passed Stream object is already inactive.
      def remove_stream(stream)
        return false unless stream.active?
        @streams_mutex.synchronize do
          return false if not @streams.include? stream.id
          client.krpc.remove_stream stream.id
          @streams.delete stream.id
        end
        stream.value = RuntimeError.new("Stream has been removed")
        true
      end
      
      # Start streaming thread. It receives stream data, and updates Stream object's `value` attribute.
      def start_streaming_thread
        stop_streaming_thread
        @streaming_thread = Thread.new do
          connection = client.stream_connection
          stream_message_type = client.type_store.as_type("KRPC.StreamMessage")
          response_type = client.type_store.as_type("KRPC.Response")
          loop do
            size = connection.recv_varint
            data = connection.recv(size)
            stream_msg = Decoder.decode(data, stream_message_type, client.type_store)
            @streams_mutex.synchronize do
              stream_msg.responses.each do |stream_resp|
                next if not @streams.include? stream_resp.id
                stream = @streams[stream_resp.id]
                if stream_resp.response.has_field?("error")
                  stream.value = RPCError.new(stream_resp.response.error)
                else
                  stream.value = Decoder.decode(stream_resp.response.return_value, stream.return_type, client.type_store)
                end
              end
            end
          end
        end
      end
      
      # Stop streaming thread.
      def stop_streaming_thread
        @streaming_thread.terminate
      end
    end
    
    class Stream
      attr_reader :id, :method, :args, :kwargs, :return_type, :manager
      attr_writer :value
      
      def initialize(manager, id, return_type, value, method, *args, **kwargs)
        @manager = manager
        @id = id
        @return_type, @value = return_type, value
        @method, @args, @kwargs = method, args, kwargs
        @active = true
      end
      
      # Get the current stream value. Has alias method `value`.
      def get
        raise @value if @value.is_a?(Exception)
        @value
      end
      alias_method :value, :get
      
      # Remove stream. Has alias method `close`.
      def remove
        result = manager.remove_stream self
        @active = false
        result
      end
      alias_method :close, :remove
      
      # Check if stream is active (i.e. not removed).
      def active?; @active end
    end
  
    module StreamConstructors
      STREAM_METHOD_SUFFIX = "_stream"
      STREAM_METHOD_REGEX = /^(.+)(?:#{STREAM_METHOD_SUFFIX})$/
      
      module ClassMethods
        def stream_constructors
          @stream_constructors ||= {}
        end
      end

      def self.included(base)
        base.extend ClassMethods
        base.extend self
      end
      
      def method_missing(method, *args, **kwargs, &block)
        if STREAM_METHOD_REGEX =~ method.to_s
          if respond_to? $1.to_sym
            ctors = self.is_a?(Module) ? stream_constructors : self.class.stream_constructors
            return ctors[$1].call(self, *args, **kwargs) if ctors.include? $1
          end
        end
        super
      end
      
      def respond_to_missing?(method, *)
        if STREAM_METHOD_REGEX =~ method.to_s
          if respond_to? $1.to_sym
            ctors = self.is_a?(Module) ? stream_constructors : self.class.stream_constructors
            return true if ctors.include? $1
          end
        end
        super
      end
      
    end
    
  end
end

