require 'krpc/krpc.pb'

module KRPC
  module ProtobufExtensions

    module MessageExtensions
      def ==(other)
        super
      rescue TypeError
        false
      end
    end

  end
end

KRPC::PB.constants(false).map {|const_name| KRPC::PB.const_get(const_name,true)}.each do |msgclass|
  msgclass.prepend KRPC::ProtobufExtensions::MessageExtensions
end

