require 'krpc/gen'
require 'krpc/attributes'
require 'krpc/encoder'
require 'krpc/types'
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
        service_msg.classes.map(&:name).each do |sc_name|
          TypeStore["Class(#{service_name}.#{sc_name})"]
        end

        # Create service' enums
        service_msg.enumerations.each do |enum|
          enum_type = TypeStore["Enum(#{service_name}.#{enum.name})"]
          enum_type.set_values(enum.values)
        end

        # Create service' procedures
        service_msg.procedures.each do |proc|
          if Attributes.is_a_class_method_or_property_accessor(proc.attributes)
            class_name  = Attributes.get_class_name(proc.attributes)
            class_cls = TypeStore["Class(#{service_name}.#{class_name})"].ruby_type
            method_name = Attributes.get_class_method_or_property_name(proc.attributes)
            if Attributes.is_a_class_property_accessor(proc.attributes)  # service' class property
              if Attributes.is_a_class_property_getter(proc.attributes)
                Gen.add_rpc_method(class_cls, method_name, service_name, proc, :prepend_self_to_args)
              else
                Gen.add_rpc_method(class_cls, method_name + '=', service_name, proc, :prepend_self_to_args, :no_stream)
              end
            elsif Attributes.is_a_class_method(proc.attributes)  # service' class method
              Gen.add_rpc_method(class_cls, method_name, service_name, proc, :prepend_self_to_args)
            else  # service' static class method
              Gen.add_rpc_method(class_cls, method_name, service_name, proc, :static)
            end
          elsif Attributes.is_a_property_accessor(proc.attributes)  # service' property
            property_name = Attributes.get_property_name(proc.attributes)
            if Attributes.is_a_property_getter(proc.attributes)
              Gen.add_rpc_method(service_class, property_name, service_name, proc)
            elsif Attributes.is_a_property_setter(proc.attributes)
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
    # Hardcoded version of `krpc` service - The core kRPC service, e.g. for querying for the available services.
    class Core < ServiceBase
      include Gen::RPCMethodGenerator

      def initialize(client)
        super(client)
        unless respond_to? :get_status
          # Generate enumerations
          TypeStore['Enum(Core.GameScene)'].set_values(
            Encoder.hash_to_enumeration_values(
              space_center: 0, flight: 1, tracking_station: 2, editor_vab: 3, editor_sph: 4
            )
          )

          # Generate procedures
          opts = {doc_service_name: 'Core'}

          include_rpc_method 'get_status', 'KRPC', 'GetStatus',
                             return_type: 'KRPC.Status',
                             xmldoc: "<doc><summary>Gets a status message from the server containing information including the server’s version string and performance statistics.</summary></doc>",
                             switches: [:static], options: opts
          include_rpc_method 'get_services', 'KRPC', 'GetServices',
                             return_type: 'KRPC.Services',
                             xmldoc: "<doc><summary>Gets available services and procedures.</summary></doc>",
                             switches: [:static, :no_stream], options: opts
          include_rpc_method 'add_stream', 'KRPC', 'AddStream',
                             params: [PB::Parameter.new(name: 'request', type: 'KRPC.Request')],
                             return_type: 'uint32',
                             xmldoc: "<doc><summary>Add a streaming request. Returns it's identifier.</summary></doc>",
                             switches: [:static, :no_stream], options: opts
          include_rpc_method 'remove_stream', 'KRPC', 'RemoveStream',
                             params: [PB::Parameter.new(name: 'id', type: 'uint32')],
                             xmldoc: "<doc><summary>Remove a streaming request</summary></doc>",
                             switches: [:static, :no_stream], options: opts
          include_rpc_method 'clients', 'KRPC', 'get_Clients',
                             return_type: 'KRPC.List',
                             attributes: ['Property.Get(Clients)', 'ReturnType.List(Tuple(bytes,string,string))'],
                             xmldoc: "<doc><summary>A list of RPC clients that are currently connected to the server.\nEach entry in the list is a clients identifier, name and address.</summary></doc>",
                             switches: [:static], options: opts
          include_rpc_method 'current_game_scene', 'KRPC', 'get_CurrentGameScene',
                             return_type: 'int32',
                             attributes: ['Property.Get(CurrentGameScene)', 'ReturnType.Enum(Core.GameScene)'],
                             xmldoc: "<doc><summary>Get the current game scene.</summary></doc>",
                             switches: [:static], options: opts
        end
      end
    end

  end
end
