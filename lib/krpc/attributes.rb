require 'krpc/error'

module KRPC
  module Attributes
    class << self

      def is_a_property_accessor(name) name.start_with?('get_') || name.start_with?('set_') end
      def is_a_property_getter(name) name.start_with?('get_') end
      def is_a_property_setter(name) name.start_with?('set_') end
      def is_a_class_member(name)
        !(name.start_with?('get_') || name.start_with?('set_')) and name.include?('_')
      end
      def is_a_class_method(name)
        is_a_class_member(name) && begin
          type = name.split('_')[1]
          not ['get','set','static'].include? type
        end
      end
      def is_a_class_static_method(name) name.split('_')[1] == 'static' end
      def is_a_class_property_accessor(name)
        type = name.split('_')[1]
        type == 'get' || type == 'set'
      end
      def is_a_class_property_getter(name) name.split('_')[1] == 'get' end
      def is_a_class_property_setter(name) name.split('_')[1] == 'set' end
      
      
      def get_class_name(name)
        raise(ValueError, "Procedure is not a class method or property") unless is_a_class_member(name)
        name.partition('_')[0]
      end
      
      def get_class_member_name(name)
        raise(ValueError, "Procedure is not a class method or property") unless is_a_class_member(name)
        name.rpartition('_').last
      end
      
      def get_property_name(name)
        raise(ValueError, "Procedure is not a property") unless is_a_property_accessor(name)
        name[4..-1] # Strip 'get_' or 'set_' off of the start of the name
      end
      
    end
  end
end
