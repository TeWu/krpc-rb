require 'krpc/gen'
require 'krpc/attributes'
require 'krpc/protobuf_utils'
require 'krpc/error'
require 'krpc/core_extensions'
require 'set'

module KRPC
  module Types
    PROTOBUF_VALUE_TYPES = ["double", "float", "int32", "int64", "uint32", "uint64", "bool", "string", "bytes"]
    RUBY_VALUE_TYPES = [Float, Integer, Boolean, String]
    PROTOBUF_TO_RUBY_VALUE_TYPE = {
      "double" => Float,
      "float"  => Float,
      "int32"  => Integer,
      "int64"  => Integer,
      "uint32" => Integer,
      "uint64" => Integer,
      "bool"   => Boolean,
      "string" => String,
      "bytes"  => String
    }
    PROTOBUF_TO_MESSAGE_TYPE = ProtobufUtils.create_PB_to_PB_message_class_hash("KRPC")
    
    class TypeStore
      @cache = {}
      class << self
      
        def [](type_string)
          return @cache[type_string] if @cache.include? type_string
          
          type =
            if PROTOBUF_VALUE_TYPES.include? type_string then ValueType.new(type_string)
            elsif type_string.start_with? "Class(" || type_string == "Class" then ClassType.new(type_string)
            elsif type_string.start_with? "Enum("  || type_string == "Enum"  then EnumType.new(type_string)
            elsif type_string.start_with? "List("  || type_string == "List"  then ListType.new(type_string)
            elsif type_string.start_with? "Dictionary(" || type_string == "Dictionary" then DictionaryType.new(type_string)
            elsif type_string.start_with? "Set("   || type_string == "Set"   then SetType.new(type_string)
            elsif type_string.start_with? "Tuple(" || type_string == "Tuple" then TupleType.new(type_string)
            else # A message type (eg. type_string = "KRPC.List" or "KRPC.Services")
              raise(ValueError, "\"#{type_string}\" is not a valid type string") unless /^[A-Za-z0-9_\.]+$/ =~ type_string
              if PROTOBUF_TO_MESSAGE_TYPE.has_key? type_string
                MessageType.new(type_string)
              else
                raise(ValueError, "\"#{type_string}\" is not a valid type string")
              end
            end

          @cache[type_string] = type
          type      
        end
        
        def get_parameter_type(pos, type, attrs)
          type_attrs = Attributes.get_parameter_type_attrs(pos, attrs)
          type_attrs.each do |ta|
            begin
              return self[ta]
            rescue ValueError
            end
          end
          self[type]
        end

        def get_return_type(type, attrs)
          type_attrs = Attributes.get_return_type_attrs(attrs)
          type_attrs.each do |ta|
            begin
              return self[ta]
            rescue ValueError
            end
          end
          self[type]
        end
        
        def coerce_to(value, type)
          return value if type.is_a?(EnumType) && value.class == Symbol # Enum handling
          return value if value.is_a?(type.ruby_type)
          # A NilClass can be coerced to a ClassType
          return nil if type.is_a?(ClassType) && value == nil
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
          if type.ruby_type == Float && value.respond_to?(:to_f)
            return value.to_f
          elsif type.ruby_type == Integer && value.respond_to?(:to_i)
            return value.to_i
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
      
      protected
      
      def parse_type_string(type)
        raise ValueError.new if type == nil
        result = ""
        level  = 0
        type.each_char do |x|
          break if level == 0 && x == ','
          level += 1 if x == '('
          level -= 1 if x == ')'
          result += x
        end
        raise ValueError.new if level != 0
        return [result, nil] if result == type
        raise ValueError.new if type[result.length] != ','
        [result, type[(result.length+1)..-1]]
      end
    end
    
    class ValueType < TypeBase
      def initialize(type_string)
        raise(ValueError, "\"#{type_string}\" is not a valid type string for a value type") unless PROTOBUF_TO_RUBY_VALUE_TYPE.has_key? type_string
        super(type_string, PROTOBUF_TO_RUBY_VALUE_TYPE[type_string])
      end
    end
    
    class MessageType < TypeBase
      def initialize(type_string)
        if PROTOBUF_TO_MESSAGE_TYPE.has_key? type_string
          super(type_string, PROTOBUF_TO_MESSAGE_TYPE[type_string])
        else
          raise(ValueError, "\"#{type_string}\" is not a valid type string for a message type")
        end
      end
    end
    
    class ClassType < TypeBase
      attr_reader :service_name, :class_name
      def initialize(type_string)
        m = /Class\(([^\.]+)\.([^\.]+)\)/.match type_string
        raise(ValueError, "\"#{type_string}\" is not a valid type string for a class type") unless m
        @service_name, @class_name = m[1..2]
        super(type_string, Gen.generate_class(service_name, class_name))
      end
    end
    
    class EnumType < TypeBase
      attr_reader :service_name, :enum_name
      def initialize(type_string)
        m = /Enum\(([^\.]+)\.([^\.]+)\)/.match type_string
        raise(ValueError, "\"#{type_string}\" is not a valid type string for a enumeration type") unless m
        @service_name, @enum_name = m[1..2]
        # Sets ruby_type to nil, set_values must be called to set the ruby_type
        super(type_string, nil)
      end
      
      def set_values(values)
        @ruby_type = Gen.generate_enum(service_name, enum_name, values)
      end
    end
    
    class ListType < TypeBase
      attr_reader :value_type
      def initialize(type_string)
        m = /^List\((.+)\)$/.match type_string
        raise(ValueError, "\"#{type_string}\" is not a valid type string for a list type") unless m
        @value_type = TypeStore[m[1]]
        super(type_string, Array)
      end
    end
    
    class DictionaryType < TypeBase
      attr_reader :key_type, :value_type
      def initialize(type_string)
        m = /^Dictionary\((.+)\)$/.match type_string
        raise(ValueError, "\"#{type_string}\" is not a valid type string for a dictionary type") unless m

        key_string, type   = parse_type_string(m[1])
        value_string, type = parse_type_string(type)
        raise(ValueError, "\"#{type_string}\" is not a valid type string for a dictionary type") if type != nil
        @key_type   = TypeStore[key_string]
        @value_type = TypeStore[value_string]

        super(type_string, Hash)
      end
    end
    
    class SetType < TypeBase
      attr_reader :value_type
      def initialize(type_string)
        m = /^Set\((.+)\)$/.match type_string
        raise(ValueError, "\"#{type_string}\" is not a valid type string for a set type") unless m
        @value_type = TypeStore[m[1]]
        super(type_string, Set)
      end
    end
    
    class TupleType < TypeBase
      attr_reader :value_types
      def initialize(type_string)
        m = /^Tuple\((.+)\)$/.match type_string
        raise(ValueError, "\"#{type_string}\" is not a valid type string for a tuple type") unless m
        
        @value_types = []
        type = m[1]
        while type != nil
          value_type, type = parse_type_string(type)
          @value_types << TypeStore[value_type]
        end
        
        super(type_string, Array)
      end
    end
        
  end
  
  TypeStore = Types::TypeStore
end

