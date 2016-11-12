require 'krpc/krpc.pb'

module KRPC
  module ProtobufUtils
    module Decoder
      class << self
      
        def decode(bytes, type)
          meth_name = "decode_" + type
          raise RuntimeError.new("Unsupported type #{type}") unless respond_to?(meth_name)
          send(meth_name, bytes)
        end

        # based on: https://developers.google.com/protocol-buffers/docs/encoding#varints  &  http://www.rubydoc.info/gems/ruby-protocol-buffers/1.0.1/ProtocolBuffers/Varint#decode-class_method  &  https://github.com/google/protobuf/blob/master/python/google/protobuf/internal/decoder.py#L136  
        def decode_varint(bytes)
          decode_varint_pos(bytes)[0]
        end
        def decode_varint_pos(bytes)
          pos = 0
          result = 0
          shift = 0
          loop do
            byte = bytes[pos].ord
            pos += 1
            result |= (byte & 0b0111_1111) << shift
            return [result, pos] if (byte & 0b1000_0000) == 0
            shift += 7
            raise(RuntimeError, "too many bytes when decoding varint") if shift >= 64
          end
        end
        def decode_signed_varint(bytes)
          result = decode_varint(bytes) 
          result -= (1 << 64) if result > 0x7fffffffffffffff
          result
        end
        
        alias_method :decode_int32, :decode_signed_varint
        alias_method :decode_int64, :decode_signed_varint
        alias_method :decode_uint32, :decode_varint
        alias_method :decode_uint64, :decode_varint
        
        # based on: https://github.com/ruby-protobuf/protobuf/search?q=pack
        def decode_float(bytes)
          bytes.unpack('e').first
        end
        def decode_double(bytes)
          bytes.unpack('E').first
        end
        def decode_bool(bytes)
          decode_varint(bytes) != 0
        end
        def decode_string(bytes)
          size, pos = decode_varint_pos(bytes)
          bytes[pos..(pos+size)].force_encoding(Encoding::UTF_8)
        end
        def decode_bytes(bytes)
          size, pos = decode_varint_pos(bytes)
          bytes[pos..(pos+size)].bytes
        end
        
      end
    end
    
    module Encoder
      class << self
      
        def encode(value, type)
          meth_name = "encode_" + type
          raise(RuntimeError, "Unsupported type #{type}") unless respond_to?(meth_name)
          send(meth_name, value)
        end
        
        # based on: http://www.rubydoc.info/gems/ruby-protocol-buffers/1.0.1/ProtocolBuffers/Varint#decode-class_method  &  https://github.com/google/protobuf/blob/master/python/google/protobuf/internal/encoder.py#L390
        def encode_varint(value)
          return [value].pack('C') if value < 0b1000_0000
          result = ""
          loop do
            byte = value & 0b0111_1111
            value >>= 7
            if value == 0
              return result << byte.chr
            else
              result << (byte | 0b1000_0000).chr
            end
          end
        end
        def encode_signed_varint(value)
          value += (1 << 64) if value < 0
          encode_varint(value)
        end
        def encode_nonnegative_varint(value)
          raise(RangeError, "Value must be non-negative, got #{value}") if value < 0
          encode_varint(value)
        end
      
        alias_method :encode_int32, :encode_signed_varint
        alias_method :encode_int64, :encode_signed_varint
        alias_method :encode_uint32, :encode_nonnegative_varint
        alias_method :encode_uint64, :encode_nonnegative_varint
      
        def encode_float(value)
          [value].pack('e')
        end
        def encode_double(value)
          [value].pack('E')
        end
        def encode_bool(value)
          encode_varint(value ? 1 : 0)
        end
        def encode_string(value)
          size = encode_varint(value.bytesize)
          size + value.bytes.map(&:chr).join.b
        end
        def encode_bytes(value)
          size = encode_varint(value.size)
          size + value.map(&:chr).join.b
        end
        
      end
    end
    
  end
end
