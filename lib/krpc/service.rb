require 'krpc/gen'
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
        class_types_by_name = Hash.new do |h,k|
          TypeStore[PB::Type.new(code: :CLASS, service: service_name, name: k)]
        end
        service_msg.classes.map(&:name).each {|cn| class_types_by_name[cn] }

        # Create service' enums
        service_msg.enumerations.each do |enum|
          enum_type = TypeStore[PB::Type.new(code: :ENUMERATION, service: service_name, name: enum.name)]
          enum_type.set_values(enum.values)
        end

        # Create service' procedures
        service_msg.procedures.each do |proc|
          cls = if proc.class_member?
                  class_types_by_name[proc.class_name].ruby_type
                else
                  service_class
                end
          Gen.add_rpc_method(cls, service_name, proc)
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
          TypeStore[PB::Type.new(code: :ENUMERATION, service: 'Core', name: 'GameScene')].set_values(
            Encoder.hash_to_enumeration_values(
              space_center: 0, flight: 1, tracking_station: 2, editor_vab: 3, editor_sph: 4
            )
          )

          # Generate procedures
          opts = {doc_service_name: 'Core'}

          include_rpc_method 'KRPC', 'GetStatus',
                             return_type: PB::Type.new(code: :STATUS),
                             xmldoc: "<doc>\n<summary>\nReturns some information about the server, such as the version.\n</summary>\n</doc>",
                             **opts
          include_rpc_method 'KRPC', 'GetServices',
                             return_type: PB::Type.new(code: :SERVICES),
                             xmldoc: "<doc>\n<summary>\nReturns information on all services, procedures, classes, properties etc. provided by the server.\nCan be used by client libraries to automatically create functionality such as stubs.\n</summary>\n</doc>",
                             **opts
          include_rpc_method 'KRPC', 'AddStream',
                             params: [
                               PB::Parameter.new(name: 'call', type: PB::Type.new(code: :PROCEDURE_CALL)),
                               PB::Parameter.new(name: 'start', type: PB::Type.new(code: :BOOL), default_value: "\x01")
                             ],
                             return_type: PB::Type.new(code: :STREAM),
                             xmldoc: "<doc>\n<summary>\nAdd a streaming request and return its identifier.\n</summary>\n</doc>",
                             **opts
          include_rpc_method 'KRPC', 'StartStream',
                             params: [PB::Parameter.new(name: 'id', type: PB::Type.new(code: :UINT64))],
                             xmldoc: "<doc>\n<summary>\nStart a previously added streaming request.\n</summary>\n</doc>",
                             **opts
          include_rpc_method 'KRPC', 'RemoveStream',
                             params: [PB::Parameter.new(name: 'id', type: PB::Type.new(code: :UINT64))],
                             xmldoc: "<doc>\n<summary>\nRemove a streaming request.\n</summary>\n</doc>",
                             **opts
          include_rpc_method 'KRPC', 'get_Clients',
                             return_type: PB::Type.new(code: :LIST, types: [PB::Type.new(code: :TUPLE, types: [PB::Type.new(code: :BYTES), PB::Type.new(code: :STRING), PB::Type.new(code: :STRING)])]),
                             xmldoc: "<doc>\n<summary>\nA list of RPC clients that are currently connected to the server.\nEach entry in the list is a clients identifier, name and address.\n</summary>\n</doc>",
                             **opts
          include_rpc_method 'KRPC', 'get_CurrentGameScene',
                             return_type: PB::Type.new(code: :ENUMERATION, service: 'Core', name: 'GameScene'),
                             xmldoc: "<doc>\n<summary>\nGet the current game scene.\n</summary>\n</doc>",
                             **opts
          include_rpc_method 'KRPC', 'GetClientID',
                             return_type: PB::Type.new(code: :BYTES),
                             xmldoc: "<doc>\n<summary>\nReturns the identifier for the current client.\n</summary>\n</doc>",
                             **opts
          include_rpc_method 'KRPC', 'GetClientName',
                             return_type: PB::Type.new(code: :STRING),
                             xmldoc: "<doc>\n<summary>\nReturns the name of the current client.\nThis is an empty string if the client has no name.\n</summary>\n</doc>",
                             **opts
          include_rpc_method 'KRPC', 'get_Paused',
                             return_type: PB::Type.new(code: :BOOL),
                             xmldoc: "<doc>\n<summary>\nWhether the game is paused.\n</summary>\n</doc>",
                             **opts
          include_rpc_method 'KRPC', 'set_Paused',
                             params: [PB::Parameter.new(name: 'value', type: PB::Type.new(code: :BOOL))],
                             xmldoc: "<doc>\n<summary>\nWhether the game is paused.\n</summary>\n</doc>",
                             **opts
          include_rpc_method 'KRPC', 'AddEvent',
                             params: [PB::Parameter.new(name: 'expression', type: PB::Type.new(code: :CLASS, service: 'KRPC', name: 'Expression'))],
                             return_type: PB::Type.new(code: :EVENT),
                             xmldoc: "<doc>\n<summary>\nCreate an event from a server side expression.\n</summary>\n</doc>",
                             **opts
        end
      end
    end

  end
end
