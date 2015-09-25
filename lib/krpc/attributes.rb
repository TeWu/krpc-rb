require 'krpc/error'

module KRPC
  module Attributes
    class << self

      def is_any_start_with?(attrs, prefix)
        attrs.any?{|a| a.start_with? prefix }
      end
      alias_method :asw?, :is_any_start_with?
      
      def is_a_property_accessor(attrs) asw?(attrs,"Property.")  end
      def is_a_property_getter(attrs) asw?(attrs,"Property.Get(") end
      def is_a_property_setter(attrs) asw?(attrs,"Property.Set(") end
      def is_a_class_method_or_property_accessor(attrs) asw?(attrs,"Class.") end
      def is_a_class_method(attrs) asw?(attrs,"Class.Method(") end
      def is_a_class_static_method(attrs) asw?(attrs,"Class.StaticMethod(") end    
      def is_a_class_property_accessor(attrs) asw?(attrs,"Class.Property.") end
      def is_a_class_property_getter(attrs) asw?(attrs,"Class.Property.Get(") end
      def is_a_class_property_setter(attrs) asw?(attrs,"Class.Property.Set(") end
      
      def get_service_name(attrs)
        if is_a_class_method(attrs) || is_a_class_static_method(attrs)
          attrs.each do |a| 
            return $1 if /^Class\.(?:Static)?Method\(([^,\.]+)\.[^,]+,[^,]+\)$/ =~ a
          end
        elsif is_a_class_property_accessor(attrs)
          attrs.each do |a| 
            return $1 if /^Class\.Property.(?:Get|Set)\(([^,\.]+)\.[^,]+,[^,]+\)$/ =~ a
          end
        end
        raise(ValueError, "Procedure attributes are not a class method or property accessor")
      end
      
      def get_class_name(attrs)
        if is_a_class_method(attrs) || is_a_class_static_method(attrs)
          attrs.each do |a| 
            return $1 if /^Class\.(?:Static)?Method\([^,\.]+\.([^,\.]+),[^,]+\)$/ =~ a
          end
        elsif is_a_class_property_accessor(attrs)
          attrs.each do |a| 
            return $1 if /^Class\.Property.(?:Get|Set)\([^,\.]+\.([^,]+),[^,]+\)$/ =~ a
          end
        end
        raise(ValueError, "Procedure attributes are not a class method or property accessor")
      end
      
      def get_property_name(attrs)
        if is_a_property_accessor(attrs)
          attrs.each do |a| 
            return $1 if /^Property\.(?:Get|Set)\((.+)\)$/ =~ a
          end
        end
        raise(ValueError, "Procedure attributes are not a property accessor")
      end
      
      def get_class_method_or_property_name(attrs)
        if is_a_class_method(attrs) || is_a_class_static_method(attrs) || is_a_class_property_accessor(attrs)
          attrs.each do |a| 
            return $1 if /^Class\.(?:(?:Static)?Method|Property\.(?:Get|Set))\([^,]+,([^,]+)\)$/ =~ a
          end
        end
        raise(ValueError, "Procedure attributes are not a class method or class property accessor")
      end
      
      def get_parameter_type_attrs(pos, attrs)
        attrs.map do |a| 
          (/^ParameterType\(#{pos}\).(.+)$/ =~ a) ? $1 : nil
        end.compact
      end
      
      def get_return_type_attrs(attrs)
        attrs.map do |a| 
          (/^ReturnType.(.+)$/ =~ a) ? $1 : nil
        end.compact
      end
      
    end
  end
end
