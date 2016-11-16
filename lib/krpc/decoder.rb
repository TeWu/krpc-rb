require 'krpc/protobuf_utils'
require 'set'

module KRPC
  module Decoder
    class << self
    
      # Given a type object, and serialized data, decode the ruby value/object
      def decode(data, type, client)
        if type.is_a?(Types::MessageType) then type.ruby_type.decode(data)
        elsif type.is_a?(Types::ValueType) then decode_value(data, type)
        elsif type.is_a?(Types::EnumType)
          v = decode_value(data, 'sint32')
          type.ruby_type.key(v)
        elsif type.is_a?(Types::ClassType)
          remote_oid = decode_value(data, 'uint64')
          if remote_oid != 0
            type.ruby_type.new(client, remote_oid)
          else nil end
        elsif type.is_a?(Types::ListType)
          msg = PB::List.decode(data)
          msg.items.map{|x| decode(x, type.value_type, client)}.to_a
        elsif type.is_a?(Types::DictionaryType)
          msg = PB::Dictionary.decode(data)
          msg.entries.map{|e| [decode(e.key,   type.key_type,   client),
                               decode(e.value, type.value_type, client)]}.to_h
        elsif type.is_a?(Types::SetType)
          msg = PB::Set.decode(data)
          Set.new(msg.items.map{|x| decode(x, type.value_type, client)}.to_a)
        elsif type.is_a?(Types::TupleType)
          msg = PB::Tuple.decode(data)
          msg.items.zip(type.value_types).map{|x,t| decode(x, t, client)}.to_a
        else raise(RuntimeError, "Cannot decode type #{type} from data: #{data}")
        end
      end
      
      def decode_value(data, type)
        type_string = type.is_a?(String) ? type : type.protobuf_type.code.to_s.downcase
        ProtobufUtils::Decoder.decode(data, type_string) 
      end
      
    end
  end
end
