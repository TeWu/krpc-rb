require 'krpc/error'

module KRPC
  module ProcedureNameParser

    def self.parse(proc_name)
      parts = proc_name.split('_')
      name = parts[-1]
      raise(ProcedureNameParserError, "Procedure name is empty") if proc_name.empty?
      raise(ProcedureNameParserError, "Invalid procedure name") if parts.size > 3

      case parts.size
        when 1
          Result.new(:plain_procedure, false, false, name, nil)
        when 2
          case parts[0]
            when 'get'
              Result.new(:service_property_getter, false, false, name, nil)
            when 'set'
              Result.new(:service_property_setter, true, false, name, nil)
            else
              Result.new(:class_method, false, true, name, parts[0])
          end
        when 3
          case parts[1]
            when 'get'
              Result.new(:class_property_getter, false, true, name, parts[0])
            when 'set'
              Result.new(:class_property_setter, true, true, name, parts[0])
            when 'static'
              Result.new(:class_static_method, false, true, name, parts[0])
            else
              raise(ProcedureNameParserError, "Invalid procedure name")
          end
      end
    end


    class Result < Struct.new(:type, :setter?, :class_member?, :member_name, :class_name)
      def class_name
        raise(ValueError, "Procedure is not a class method or property") unless super
        super
      end
    end

  end
end
