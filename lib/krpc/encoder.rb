require 'krpc/protobuf_utils'
require 'krpc/types'

module KRPC
  module Encoder
    RPC_HELLO_MESSAGE = "\x48\x45\x4C\x4C\x4F\x2D\x52\x50\x43\x00\x00\x00"
    STREAM_HELLO_MESSAGE = "\x48\x45\x4C\x4C\x4F\x2D\x53\x54\x52\x45\x41\x4D"
    NAME_LENGTH = 32

    class << self

      # Given a type object, and ruby object, encode the ruby object
      def encode(obj, type)
        if type.is_a?(Types::MessageType) then type.ruby_type.encode(obj)
        elsif type.is_a?(Types::ValueType) then encode_value(obj, type)
        elsif type.is_a?(Types::EnumType)
          enum_value = type.ruby_type[obj]
          encode_value(enum_value, TypeStore["int32"])
        elsif type.is_a?(Types::ClassType)
          remote_oid = if obj == nil then 0 else obj.remote_oid end
          encode_value(remote_oid, TypeStore["uint64"])
        elsif type.is_a?(Types::ListType)
          ruby_type = TypeStore["KRPC.List"].ruby_type
          msg = ruby_type.new(
            items: obj.map{|x| encode(TypeStore.coerce_to(x, type.value_type), type.value_type)}.to_a
          )
          ruby_type.encode(msg)
        elsif type.is_a?(Types::DictionaryType)
          ruby_type = TypeStore["KRPC.Dictionary"].ruby_type
          entry_type = TypeStore["KRPC.DictionaryEntry"].ruby_type
          entries = obj.map do |k,v|
            entry_type.new(
              key: encode(TypeStore.coerce_to(k, type.key_type), type.key_type),
              value: encode(TypeStore.coerce_to(v, type.value_type), type.value_type)
            )
          end
          msg = ruby_type.new(entries: entries)
          ruby_type.encode(msg)
        elsif type.is_a?(Types::SetType)
          ruby_type = TypeStore["KRPC.Set"].ruby_type
          msg = ruby_type.new(
            items: obj.map{|x| encode( TypeStore.coerce_to(x, type.value_type), type.value_type )}.to_a
          )
          ruby_type.encode(msg)
        elsif type.is_a?(Types::TupleType)
          ruby_type = TypeStore["KRPC.Tuple"].ruby_type
          msg = ruby_type.new(
            items: obj.zip(type.value_types).map{|x,t| encode( TypeStore.coerce_to(x, t), t )}.to_a
          )
          ruby_type.encode(msg)
        else raise(RuntimeError, "Cannot encode object #{obj} of type #{type}")
        end
      end

      def encode_value(value, type)
        ProtobufUtils::Encoder.encode(value, type.protobuf_type)
      end

      def encode_request(req)
        data = PB::Request.encode(req)
        length = ProtobufUtils::Encoder.encode_nonnegative_varint(data.length)
        length + data
      end

      def hash_to_enumeration_values(hash)
        hash.map {|k,v| PB::EnumerationValue.new(name: k.to_s, value: v) }
      end

    end
  end
end
