require 'krpc/krpc.pb'
require 'krpc/procedure_name_parser'

module KRPC
  module ProtobufExtensions
    module MessageExtensions

      def ==(other)
        super
      rescue TypeError
        false
      end

      def field_empty?(field)
        val = self.send(field)
        val == "" || val == [] || val.nil?
      end

    end
    module ProcedureExtensions
      extend Forwardable

      def info
        @info ||= ProcedureNameParser.parse(name)
      end
      def_delegators :info, *ProcedureNameParser::Result.members

    end
  end
end

KRPC::PB.constants(false).map {|const_name| KRPC::PB.const_get(const_name,true)}.each do |msgclass|
  msgclass.prepend KRPC::ProtobufExtensions::MessageExtensions
end
KRPC::PB::Procedure.prepend KRPC::ProtobufExtensions::ProcedureExtensions

