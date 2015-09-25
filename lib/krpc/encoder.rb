require 'krpc/protobuf_utils'

module KRPC
  module Encoder
    RPC_HELLO_MESSAGE = "\x48\x45\x4C\x4C\x4F\x2D\x52\x50\x43\x00\x00\x00"
    STREAM_HELLO_MESSAGE = "\x48\x45\x4C\x4C\x4F\x2D\x53\x54\x52\x45\x41\x4D"
    NAME_LENGTH = 32
    
    class << self
      
      # Given a type object, and ruby object, encode the ruby object
      def encode(obj, type)
        if type.is_a?(Types::MessageType) then obj.serialize_to_string
        elsif type.is_a?(Types::ValueType) then encode_value(obj, type)
        elsif type.is_a?(Types::EnumType)
          enum_value = type.ruby_type[obj]
          encode_value(enum_value, TypeStore["int32"])
        elsif type.is_a?(Types::ClassType)
          remote_oid = if obj == nil then 0 else obj.remote_oid end
          encode_value(remote_oid, TypeStore["uint64"])
        elsif type.is_a?(Types::ListType)
          msg = TypeStore["KRPC.List"].ruby_type.new
          msg.items = obj.map{|x| encode(x, type.value_type)}.to_a
          msg.serialize_to_string
        elsif type.is_a?(Types::DictionaryType)
          entry_type = TypeStore["KRPC.DictionaryEntry"].ruby_type
          msg = TypeStore["KRPC.Dictionary"].ruby_type.new
          msg.entries = obj.map do |k,v|
            entry = entry_type.new
            entry.key = encode(k, type.key_type)
            entry.value = encode(v, type.value_type)
            entry
          end
          msg.serialize_to_string
        elsif type.is_a?(Types::SetType)
          msg = TypeStore["KRPC.Set"].ruby_type.new
          msg.items = obj.map{|x| encode(x, type.value_type)}.to_a
          msg.serialize_to_string
        elsif type.is_a?(Types::TupleType)
          msg = TypeStore["KRPC.Tuple"].ruby_type.new
          msg.items = obj.zip(type.value_types).map{|x,t| encode(x, t)}.to_a
          msg.serialize_to_string
        else raise(RuntimeError, "Cannot encode object #{obj} of type #{type}")
        end
      end
            
      def encode_value(value, type)
        ProtobufUtils::Encoder.encode(value, type.protobuf_type)
      end
      
      def encode_request(req)
        data = req.serialize_to_string
        length =  ProtobufUtils::Encoder.encode_nonnegative_varint(data.length)
        length + data
      end
      
    end
  end
end
