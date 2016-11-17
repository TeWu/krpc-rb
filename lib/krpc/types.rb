require 'krpc/gen'
require 'krpc/protobuf_utils'
require 'krpc/error'
require 'krpc/core_extensions'
require 'set'

module KRPC
  module Types
    PROTOBUF_TO_RUBY_VALUE_TYPES = {
      DOUBLE: Float,
      FLOAT: Float,
      SINT32: Integer,
      SINT64: Integer,
      UINT32: Integer,
      UINT64: Integer,
      BOOL: Boolean,
      STRING: String,
      BYTES: Array
    }
    PROTOBUF_TO_RUBY_MESSAGE_TYPES = {
      PROCEDURE_CALL: PB::ProcedureCall,
      STREAM: PB::Stream,
      STATUS: PB::Status,
      SERVICES: PB::Services
    }
    
    
    class TypeStore
      @cache = {}
      class << self
      
        def [](protobuf_type)
          @cache[protobuf_type.to_proto.hash] ||= PROTOBUF_TYPE_CODE_TO_TYPE_TYPE[protobuf_type.code].new(protobuf_type)
        end
        
        def coerce_to(value, type)
          return value if type.is_a?(EnumType) && value.class == Symbol # Enum handling
          return value if value.is_a?(type.ruby_type)
          # A NilClass can be coerced to a ClassType
          return nil if type.is_a?(ClassType) && value.nil?
          # Handle service' class instance
          if type.is_a?(ClassType) && value.is_a?(Gen::ClassBase) && 
             type.ruby_type == value.class
            return value
          end
          # -- Collection types --
          begin
            # coerce "list" to array
            if type.is_a?(ListType) && value.respond_to?(:map) && value.respond_to?(:to_a)
              return type.ruby_type.new(value.map{|x| coerce_to(x, type.value_type) }.to_a)
            end
            # coerce "tuple" to array + check elements count
            if type.is_a?(TupleType) && value.respond_to?(:map) && value.respond_to?(:to_a) && value.respond_to?(:size)
              raise ValueError if value.size != type.value_types.size
              return type.ruby_type.new(value.map.with_index{|x,i| coerce_to(x, type.value_types[i]) }.to_a)
            end
          rescue ValueError
            raise(ValueError, "Failed to coerce value #{value.to_s} of type #{value.class} to type #{type}")
          end
          # Numeric types
          if type.ruby_type == Float && ( value.kind_of?(Float) || value.to_s.numeric? )
            return value.to_f
          elsif type.ruby_type == Integer && ( value.kind_of?(Integer) || value.to_s.integer? )
            return value.to_i
          end
          # Convert value type to string
          if type.ruby_type == String
            return value.to_s
          end
          raise(ValueError, "Failed to coerce value #{value.to_s} of type #{value.class} to type #{type}")
        end
      
      end
    end
    
    
    class TypeBase
      attr_reader :protobuf_type, :ruby_type
      def initialize(protobuf_type, ruby_type)
        @protobuf_type = protobuf_type
        @ruby_type = ruby_type
      end
    end
    
    class ValueType < TypeBase
      def initialize(pb_type)
        super(pb_type, PROTOBUF_TO_RUBY_VALUE_TYPES[pb_type.code] || raise(ValueError, "#{pb_type.code} is not a valid type code for a value type"))
      end
    end
    
    class ClassType < TypeBase
      attr_reader :service_name, :class_name
      def initialize(pb_type)
        @service_name, @class_name = pb_type.service, pb_type.name
        super(pb_type, Gen.generate_class(service_name, class_name))
      end
    end
    
    class EnumType < TypeBase
      attr_reader :service_name, :enum_name
      def initialize(pb_type)
        @service_name, @enum_name = pb_type.service, pb_type.name
        # Sets ruby_type to nil, set_values must be called to set the ruby_type
        super(pb_type, nil)
      end
      
      def set_values(values)
        @ruby_type = Gen.generate_enum(service_name, enum_name, values)
      end
    end
    
    class ListType < TypeBase
      attr_reader :value_type
      def initialize(pb_type)
        @value_type = TypeStore[pb_type.types.first]
        super(pb_type, Array)
      end
    end
    
    class SetType < TypeBase
      attr_reader :value_type
      def initialize(pb_type)
        @value_type = TypeStore[pb_type.types.first]
        super(pb_type, Set)
      end
    end
    
    class TupleType < TypeBase
      attr_reader :value_types
      def initialize(pb_type)
        @value_types = pb_type.types.map {|t| TypeStore[t] }
        super(pb_type, Array)
      end
    end
    
    class DictionaryType < TypeBase
      attr_reader :key_type, :value_type
      def initialize(pb_type)
        @key_type, @value_type = pb_type.types.map {|t| TypeStore[t] }
        super(pb_type, Hash)
      end
    end
    
    class MessageType < TypeBase
      def initialize(pb_type)
        super(pb_type, PROTOBUF_TO_RUBY_MESSAGE_TYPES[pb_type.code] || raise(ValueError, "\"#{pb_type.code}\" is not a valid type code for a message type"))
      end
    end
    
    PROTOBUF_TYPE_CODE_TO_TYPE_TYPE =
      PROTOBUF_TO_RUBY_VALUE_TYPES.keys.inject({}) {|a,e| a[e] = ValueType; a }.merge(
      PROTOBUF_TO_RUBY_MESSAGE_TYPES.keys.inject({}) {|a,e| a[e] = MessageType; a }).merge(
        CLASS: ClassType, ENUMERATION: EnumType,
        LIST: ListType, SET: SetType, TUPLE: TupleType, DICTIONARY: DictionaryType
      )
  end
  
  TypeStore = Types::TypeStore
end
