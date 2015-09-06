require 'krpc/gen'
require 'krpc/attributes'
require 'krpc/doc'

module KRPC
  module Services
    class << self
    
      def create_service(service_msg, client)
        service_name = service_msg.name
        
        # Create service class
        service_class = Class.new(ServiceBase)
        const_set(service_name, service_class)
        
        # Create service' classes
        service_msg.classes.map(&:name).each do |sc_name|
          client.type_store.as_type("Class(#{service_name}.#{sc_name})")
        end
        
        # Create service' enums
        service_msg.enumerations.each do |enum|
          enum_type = client.type_store.as_type("Enum(#{service_name}.#{enum.name})")
          enum_type.set_values(enum.values)
        end
        
        # Create service' procedures
        service_msg.procedures.each do |proc|
          if Attributes.is_a_class_method_or_property_accessor(proc.attributes)
            class_name  = Attributes.get_class_name(proc.attributes)
            class_cls = client.type_store.as_type("Class(#{service_name}.#{class_name})").ruby_type
            method_name = Attributes.get_class_method_or_property_name(proc.attributes)
            if Attributes.is_a_class_property_accessor(proc.attributes)  # service' class property
              if Attributes.is_a_class_property_getter(proc.attributes)
                Gen.add_rpc_method(class_cls, method_name, service_name, proc, client, :prepend_self_to_args)
              else
                Gen.add_rpc_method(class_cls, method_name + '=', service_name, proc, client, :prepend_self_to_args)
              end
            elsif Attributes.is_a_class_method(proc.attributes)  # service' class method
              Gen.add_rpc_method(class_cls, method_name, service_name, proc, client, :prepend_self_to_args)
            else  # service' static class method
              Gen.add_rpc_method(class_cls, method_name, service_name, proc, client, :static)
            end
          elsif Attributes.is_a_property_accessor(proc.attributes)  # service' property
            property_name = Attributes.get_property_name(proc.attributes)
            if Attributes.is_a_property_getter(proc.attributes)
              Gen.add_rpc_method(service_class, property_name, service_name, proc, client)
            elsif Attributes.is_a_property_setter(proc.attributes)
              Gen.add_rpc_method(service_class, property_name + '=', service_name, proc, client)
            end
          else  # plain procedure = method available to service class and its instance
            Gen.add_rpc_method(service_class, proc.name, service_name, proc, client, :static)
          end
        end
        
        # Add methods available to class and instance in service class & service' classes
        service_class.add_methods_available_to_class_and_instance
        mod = Gen.service_gen_module(service_name)
        service_classes = mod.constants.map{|c| mod.const_get(c)}.select {|c| c.is_a? Class}
        service_classes.each(&:add_methods_available_to_class_and_instance)
        
        # Return service class instance
        service_class.new(client)
      end
      
    end
    
    class ServiceBase
      extend Gen::AvailableToClassAndInstanceMethodsHandler
      include Doc::SuffixMethods
      
      attr_reader :client
  
      def initialize(client)
        @client = client
      end
    end
    
    class KRPC < ServiceBase
      include Gen::RPCMethodGenerator
    
      def initialize(client)
        super(client)
        unless respond_to? :get_status
          include_rpc_method("get_status", "KRPC", "GetStatus", return_type: "KRPC.Status")
          include_rpc_method("get_services", "KRPC", "GetServices", return_type: "KRPC.Services")
          # TODO: implement me:
          # include_rpc_method("add_stream", "KRPC", "AddStream", ...)
          # include_rpc_method("remove_stream", "KRPC", "RemoveStream", ...)
        end
      end
    end
    
  end
end

