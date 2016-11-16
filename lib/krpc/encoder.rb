require 'krpc/protobuf_utils'
require 'krpc/types'

module KRPC
  module Encoder
    class << self
      
      # Given a type object, and ruby object, encode the ruby object
      def encode(obj, type)
        if type.is_a?(Types::MessageType) then type.ruby_type.encode(obj)
        elsif type.is_a?(Types::ValueType) then encode_value(obj, type)
        elsif type.is_a?(Types::EnumType)
          enum_value = type.ruby_type[obj]
          encode_value(enum_value, 'sint32')
        elsif type.is_a?(Types::ClassType)
          remote_oid = obj.nil? ? 0 : obj.remote_oid
          encode_value(remote_oid, 'uint64')
        elsif type.is_a?(Types::ListType)
          PB::List.encode(PB::List.new(
            items: obj.map{|x| encode(TypeStore.coerce_to(x, type.value_type), type.value_type)}.to_a
          ))
        elsif type.is_a?(Types::DictionaryType)
          entries = obj.map do |k,v|
            PB::DictionaryEntry.new(
              key: encode(TypeStore.coerce_to(k, type.key_type), type.key_type),
              value: encode(TypeStore.coerce_to(v, type.value_type), type.value_type)
            )
          end
          PB::Dictionary.encode(PB::Dictionary.new(entries: entries))
        elsif type.is_a?(Types::SetType)
          PB::Set.encode(PB::Set.new(
            items: obj.map{|x| encode( TypeStore.coerce_to(x, type.value_type), type.value_type )}.to_a
          ))
        elsif type.is_a?(Types::TupleType)
          PB::Tuple.encode(PB::Tuple.new(
            items: obj.zip(type.value_types).map{|x,t| encode( TypeStore.coerce_to(x, t), t )}.to_a
          ))
        else raise(RuntimeError, "Cannot encode object #{obj} of type #{type}")
        end
      end
      
      def encode_value(value, type)
        type_string = type.is_a?(String) ? type : type.protobuf_type.code.to_s.downcase
        ProtobufUtils::Encoder.encode(value, type_string)
      end
      
      def encode_message_with_size(msg)
        data = msg.class.encode(msg)
        length = ProtobufUtils::Encoder.encode_nonnegative_varint(data.length)
        length + data
      end

      def hash_to_enumeration_values(hash)
        hash.map {|k,v| PB::EnumerationValue.new(name: k.to_s, value: v)}
      end

    end
  end
end
