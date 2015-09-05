require "./protobuf_utils"
require "set"

module KRPC
  module Decoder
    OK_LENGTH = 2
    OK_MESSAGE = "\x4F\x4B"
    GUID_LENGTH = 16
    
    class << self
    
      ## Given a type object, and serialized data, decode the ruby value/object
      def decode(data, type, type_store)
        if type.is_a?(Types::MessageType) then decode_message(data, type)
        elsif type.is_a?(Types::ValueType) then decode_value(data, type)
        elsif type.is_a?(Types::EnumType) 
          v = decode_value(data, type_store.as_type("int32"))
          type.ruby_type.key(v)
        elsif type.is_a?(Types::ClassType)
          remote_oid = decode_value(data, type_store.as_type("uint64"))
          if remote_oid != 0
            type.ruby_type.new(remote_oid)
          else nil end
        elsif type.is_a?(Types::ListType)
          msg = decode_message(data, type_store.as_type("KRPC.List"))
          msg.items.map{|x| decode(x, type.value_type, type_store)}.to_a
        elsif type.is_a?(Types::DictionaryType)
          msg = decode_message(data, type_store.as_type("KRPC.Dictionary"))
          msg.entries.map{|e| [decode(e.key,   type.key_type,   type_store),
                               decode(e.value, type.value_type, type_store)]}.to_h
        elsif type.is_a?(Types::SetType)
          msg = decode_message(data, type_store.as_type("KRPC.Set"))
          Set.new(msg.items.map{|x| decode(x, type.value_type, type_store)}.to_a)
        elsif type.is_a?(Types::TupleType)
          msg = decode_message(data, type_store.as_type("KRPC.Tuple"))
          msg.items.zip(type.value_types).map{|x,t| decode(x, t, type_store)}.to_a
        else raise RuntimeError.new("Cannot decode type #{type} from data: #{data}")
        end
      end

      def decode_value(data, type)
        ProtobufUtils::Decoder.decode(data, type.protobuf_type)
      end
      
      def decode_message(data, type)
        msg = type.ruby_type.new
        msg.parse_from_string data.to_s
        msg
      end
      
    end
  end
end

