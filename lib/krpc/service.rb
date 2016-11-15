require 'krpc/gen'
require 'krpc/attributes'
require 'krpc/doc'
require 'krpc/streaming'

module KRPC
  module Services
    class << self
    
      # Generate classes and methods for the service - see documentation for Client#generate_services_api!
      def create_service(service_msg)
        service_name = service_msg.name
        
        # Create service class
        service_class = Class.new(ServiceBase)
        const_set(service_name, service_class)
        
        # Create service' classes
        classes_types_by_name = Hash.new do |h,k|
          TypeStore[PB::Type.new(code: :CLASS, service: service_name, name: k)]
        end
        service_msg.classes.map(&:name).each {|cn| classes_types_by_name[cn] }
        
        # Create service' enums
        service_msg.enumerations.each do |enum|
          enum_type = TypeStore[PB::Type.new(code: :ENUMERATION, service: service_name, name: enum.name)]
          enum_type.set_values(enum.values)
        end
        
        # Create service' procedures
        service_msg.procedures.each do |proc|
          if Attributes.is_a_class_member(proc.name)
            class_name  = Attributes.get_class_name(proc.name)
            class_cls = classes_types_by_name[class_name].ruby_type
            method_name = Attributes.get_class_member_name(proc.name)
            if Attributes.is_a_class_property_accessor(proc.name)  # service' class property
              if Attributes.is_a_class_property_getter(proc.name)
                Gen.add_rpc_method(class_cls, method_name, service_name, proc, :prepend_self_to_args)
              else
                Gen.add_rpc_method(class_cls, method_name + '=', service_name, proc, :prepend_self_to_args, :no_stream)
              end
            elsif Attributes.is_a_class_method(proc.name)  # service' class method
              Gen.add_rpc_method(class_cls, method_name, service_name, proc, :prepend_self_to_args)
            else  # service' static class method
              Gen.add_rpc_method(class_cls, method_name, service_name, proc, :static)
            end
          elsif Attributes.is_a_property_accessor(proc.name)  # service' property
            property_name = Attributes.get_property_name(proc.name)
            if Attributes.is_a_property_getter(proc.name)
              Gen.add_rpc_method(service_class, property_name, service_name, proc)
            elsif Attributes.is_a_property_setter(proc.name)
              Gen.add_rpc_method(service_class, property_name + '=', service_name, proc, :no_stream)
            end
          else  # plain procedure = method available to service class and its instance
            Gen.add_rpc_method(service_class, proc.name, service_name, proc, :static)
          end
        end
        
        # Return service class
        service_class
      end
      
    end
    
    ##
    # Base class for service objects, created at runtime using information received from the server.
    class ServiceBase
      include Doc::SuffixMethods
      include Streaming::StreamConstructors
      
      attr_reader :client
  
      def initialize(client)
        @client = client
      end
    end
    
    ##
    # Hardcoded version of 'krpc' service - The core kRPC service, e.g. for querying for the available services.
    class Core < ServiceBase
      include Gen::RPCMethodGenerator

      def initialize(client)
        super(client)
        unless respond_to? :get_status
          include_rpc_method("get_status", "KRPC", "GetStatus",
                             return_type: PB::Type.new(code: :STATUS),
                             xmldoc: "<doc><summary>Gets a status message from the server containing information including the server’s version string and performance statistics.</summary></doc>",
                             switches: [:static], options: {doc_service_name: "Core"})
          include_rpc_method("get_services", "KRPC", "GetServices",
                             return_type: PB::Type.new(code: :SERVICES),
                             xmldoc: "<doc><summary>Gets available services and procedures.</summary></doc>",
                             switches: [:static, :no_stream], options: {doc_service_name: "Core"})
          include_rpc_method("add_stream", "KRPC", "AddStream",
                             params: [PB::Parameter.new(name: "request", type: PB::Type.new(code: :PROCEDURE_CALL))],
                             return_type: PB::Type.new(code: :STREAM),
                             xmldoc: "<doc><summary>Add a streaming request. Returns it's identifier.</summary></doc>",
                             switches: [:static, :no_stream], options: {doc_service_name: "Core"})
          include_rpc_method("remove_stream", "KRPC", "RemoveStream",
                             params: [PB::Parameter.new(name: "id", type: PB::Type.new(code: :UINT64))],
                             xmldoc: "<doc><summary>Remove a streaming request</summary></doc>",
                             switches: [:static, :no_stream], options: {doc_service_name: "Core"})
        end
      end
    end
    
  end
end
