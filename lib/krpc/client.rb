require 'krpc/connection'
require 'krpc/service'
require 'krpc/types'
require 'krpc/encoder'
require 'krpc/decoder'
require 'krpc/error'
require 'krpc/core_extensions'
require 'krpc/KRPC.pb'

module KRPC
  class Client
    DEFAULT_NAME = ""

    include Doc::SuffixMethods

    attr_reader :name, :rpc_connection, :stream_connection, :type_store, :krpc
    
    def initialize(name = DEFAULT_NAME, host = Connection::DEFAULT_SERVER_HOST, rpc_port = Connection::DEFAULT_SERVER_RPC_PORT, stream_port = Connection::DEFAULT_SERVER_STREAM_PORT)
      @name = name
      @rpc_connection = RPCConncetion.new(name, host, rpc_port)
      @stream_connection = StreamConncetion.new(rpc_connection, host, stream_port)
      @type_store = Types::TypeStore.new
      @krpc = Services::KRPC.new(self)
      Doc.add_docstring_info(false, self.class, "krpc", return_type: @krpc.class)
    end
    
    def connect
      rpc_connection.connect
      stream_connection.connect
      self
    end
    
    def connect!
      connect
      generate_services_api!
      self
    end
    
    def close
      stream_connection.close
      rpc_connection.close
    end

    def connected?
      rpc_connection.connected?
    end
        
    def generate_services_api!
      return self if services_api_generated?
      raise(Exception, "Can't generate services API while not connected to server -- call Client#connect! to connect to server and generate services API in one call") if not connected?
      
      resp = krpc.get_services
      resp.services.each do |service_msg|
        next if service_msg.name == "KRPC"
        service = Services.create_service(service_msg, self)
        method_name = service.class.class_name.underscore
        self.class.instance_eval do
          define_method method_name do service end
        end
        Doc.add_docstring_info(false, self.class, method_name, return_type: service.class)
      end
      self
    end
    
    def services_api_generated?
      respond_to? :space_center
    end
    
    def rpc(service, procedure, args=[], kwargs={}, param_names=[], param_types=[], required_params_count=0, param_default=[], return_type: nil)
      # Send request
      req = build_request(service, procedure, args, kwargs, param_names, param_types, required_params_count, param_default)
      rpc_connection.send Encoder.encode_request(req)
      # Receive response
      resp_length = rpc_connection.recv_varint
      resp_data = rpc_connection.recv resp_length
      resp = PB::Response.new
      resp.parse_from_string resp_data
      # Check for an error response
      raise(RPCError, resp.error) if resp.has_field? "error"
      # Optionally decode and return the response' return value
      if return_type == nil
        nil
      else
        Decoder.decode(resp.return_value, return_type, type_store)
      end
    rescue IOError => e
      raise(Exception, "RPC call attempt while not connected to server -- call Client#connect first") if not connected?
      raise e
    end
    
    protected #----------------------------------

    def build_request(service, procedure, args=[], kwargs={}, param_names=[], param_types=[], required_params_count=0, param_default=[])
      begin
        raise(ArgumentError, "param_names and param_types should be equal length\n\tparam_names = #{param_names}\n\tparam_types = #{param_types}") unless param_names.size == param_types.size
        raise ArgumentsNumberErrorSig.new(args.count, required_params_count..param_names.count) unless args.count <= param_names.count
        kwargs_remaining = kwargs.count
        
        param_names_symbols = param_names.map(&:to_sym)
        req_args = param_names_symbols.map.with_index do |name,i|
          is_kwarg = kwargs.has_key? name
          raise ArgumentErrorSig.new("there are both positional and keyword arguments for parameter \"#{name}\"") if is_kwarg && i < args.count 
          kwargs_remaining -= 1 if is_kwarg
          unless i >= required_params_count && 
                 (!is_kwarg && i >= args.count ||
                  !is_kwarg && args[i] == param_default[i] ||
                  is_kwarg  && kwargs[name] == param_default[i])
            arg = if is_kwarg then kwargs[name]
                  elsif i < args.count then args[i]
                  else raise ArgumentErrorSig.new("missing argument for parameter \"#{name}\"") 
                  end
            begin
              arg = type_store.coerce_to(arg, param_types[i])
            rescue ValueError
              raise ArgumentErrorSig.new("argument for parameter \"#{name}\" must be a #{param_types[i].ruby_type} -- got #{args[i]} of type #{args[i].class}")
            end
            v = Encoder.encode(arg, param_types[i], type_store)
            PB::Argument.new(position: i, value: v)
          end
        end.compact
        raise ArgumentErrorSig.new("keyword arguments for non existing parameters: #{(kwargs.keys - param_names_symbols).join(", ")}") unless kwargs_remaining == 0
      rescue ArgumentErrorSig => err
        raise err.with_signature(Doc.docstring_for_procedure(service, procedure))
      end
      PB::Request.new(service: service, procedure: procedure, arguments: req_args)
    end
    
  end
end

