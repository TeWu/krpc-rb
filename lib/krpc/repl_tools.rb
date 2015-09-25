require 'krpc/doc'

module KRPC
  module REPLTools
    def proc_doc(service_name, procedure_name)
      puts Doc.docstring_for_procedure(service_name, procedure_name)
    end
  end
end

include KRPC::REPLTools
