require 'thread'
require 'colorize'

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

      # Send the streaming request, create related Stream object and return it. If identical Stream
      # already exists, doesn't create new Stream and return the existing one.
      def create_stream(call, return_type, method, *args, **kwargs)
        raise RuntimeError("Cannot stream a property setter") if method.name.to_s.end_with? '='
        stream_msg = client.core.add_stream(call)
        id = stream_msg.id
        @streams_mutex.synchronize do
          if @streams.include? id
            @streams[id]
          else
            value = method.call(*args, **kwargs)
            @streams[id] = Stream.new(self, id, return_type, value, method, *args, **kwargs)
          end
        end
      end

      # Remove the streaming request and deactivate the Stream object. Returns `true` if the
      # streaming request has been removed or `false` if passed Stream object is already inactive.
      def remove_stream(stream)
        return false unless stream.active?
        @streams_mutex.synchronize do
          return false unless @streams.include? stream.id
          client.core.remove_stream stream.id
          @streams.delete stream.id
        end
        stream.value = RuntimeError.new("Stream has been removed")
        stream.mark_as_inactive
        true
      end

      # Remove all streams created by this streams manager.
      def remove_all_streams
        @streams.each {|_,stream| remove_stream(stream)}
      end

      # Start streaming thread. It receives stream data, and updates Stream object's `value` attribute.
      def start_streaming_thread
        stop_streaming_thread
        @streaming_thread = Thread.new do
          connection = client.stream_connection
          loop do
            size = connection.recv_varint
            data = connection.recv(size)
            stream_msg = PB::StreamUpdate.decode(data)
            @streams_mutex.synchronize do
              stream_msg.results.each do |result|
                next unless @streams.include? result.id
                stream = @streams[result.id]
                if result.result.field_empty? :error
                  stream.value = Decoder.decode(result.result.value, stream.return_type, client)
                else
                  stream.value = client.build_exception(result.result.error)
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
        manager.remove_stream self
      end
      alias_method :close, :remove

      # Check if stream is active (i.e. not removed).
      def active?; @active end

      # Mark stream as inactive.
      # WARNING: This method does not remove the stream. To remove the stream call Stream#remove instead.
      def mark_as_inactive; @active = false end

      def to_s
        inspect.gsub(/\n|\t/," ").squeeze(" ").uncolorize
      end

      def inspect
        def coderay(x)
          require 'coderay'
          if x.is_a?(Array) then "[" + x.map{|e| e.is_a?(Gen::ClassBase) ? e.inspect : coderay(e.inspect)}.join(", ") + "]"
          elsif x.is_a?(Hash) then "{" + x.map{|k,v| coderay(k.inspect) + "=>" + (v.is_a?(Gen::ClassBase) ? v.inspect : coderay(v.inspect))}.join(", ") + "}"
          else CodeRay.scan(x, :ruby).term end
        rescue Exception
         x.inspect
        end
        "#<#{self.class}".green +
            " @id" + "=".green + id.to_s.bold.blue +
            " @active" + "=".green + @active.to_s.bold.light_cyan +
            "\n\t@method" + "=".green + method.inspect.green +
            (args.empty? ? "" : "\n\t@args" + "=".green + coderay(args)) +
            (kwargs.empty? ? "" : "\n\t@kwargs" + "=".green + coderay(kwargs)) +
            "\n\treturn_ruby_type" + "=".green + coderay(return_type.ruby_type) +
            ">".green
      end
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
