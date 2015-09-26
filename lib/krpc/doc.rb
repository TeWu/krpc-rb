require 'krpc/core_extensions'
require 'nokogiri'
require 'colorize'

module KRPC
  module Doc
    @docstr_infos = {}
    @procedure_docstr_infos = {}
    class << self
      
      def docstring_for_method(method_owner, method_name, is_print_xmldoc_summary = true)
        is_static, class_cls = method_owner.class == Class ? [true, method_owner] : [false, method_owner.class]
        service_module_name, class_name = ruby_class_to_pb_module_class_pair(class_cls)
        key = [service_module_name, is_static, class_name, method_name.to_s].hash
        if @docstr_infos.has_key? key
          construct_docstring(*@docstr_infos[key], true, is_print_xmldoc_summary)
        else
          "No docstring for #{class_cls.name}#{calc_separator(is_static)}#{method_name.to_s} method" +
            (method_owner.respond_to?(method_name) ? "" : "\nThere is no such method -- maybe a typo")
        end
      end
      
      def docstring_for_procedure(service_name, procedure_name, is_print_xmldoc_summary = true)
        key = [service_name, procedure_name].hash
        if @procedure_docstr_infos.has_key? key
          construct_docstring(service_name, '.', procedure_name, *@procedure_docstr_infos[key][3..-1], false, is_print_xmldoc_summary)
        else
          "No docstring for #{service_name}.#{procedure_name} procedure"
        end
      end

      def add_docstring_info(is_static, cls, method_name, service_name="", procedure_name="", param_names=[], param_types=[], param_default=[], return_type: nil, xmldoc: "")
        service_module_name = service_name == cls.class_name ? Services.class_name : service_name
        key0 = [service_name, procedure_name].hash
        key1 = [service_module_name, false, cls.class_name, method_name].hash
        val = [cls.krpc_name, calc_separator(is_static), method_name, param_names, param_types, param_default, return_type, xmldoc]
        @docstr_infos[key1] = @procedure_docstr_infos[key0] = val
        if is_static
          key2 = [service_module_name, true, cls.class_name, method_name].hash
          @docstr_infos[key2] = val
        end
      end
      
      def add_special_docstring_info(key, value)
        @docstr_infos[key] = value
      end
      
      private #----------------------------------
      
      def ruby_class_to_pb_module_class_pair(ruby_class)
        return ["", Client.class_name] if ruby_class == Client
        rest, _, pb_class_name = ruby_class.name.rpartition("::")
        _, _, pb_service_name = rest.rpartition("::")
        [pb_service_name, pb_class_name]
      end
      
      def calc_separator(is_static)
        is_static ? '.' : '#'
      end
      
      def construct_docstring(namespace, separator, name, param_names, param_types, param_default, return_type, xmldoc, is_hide_this_param, is_print_xmldoc_summary)
        xmldoc = Nokogiri::XML(xmldoc)
        xmldoc_summary = xmlElements2str(xmldoc.xpath("doc/summary").children, :light_blue, :light_green, :light_red)

        xmldoc_returns = xmlElements2str(xmldoc.xpath("doc/returns").children, :blue, :green, :light_red)
        xmldoc_returns = "- ".blue + xmldoc_returns unless xmldoc_returns.empty? 

        xmldoc_params = {}
        xmldoc.xpath("doc/param").each do |e|
          param_name = e.attr("name")
          if param_name
            unless e.text.strip.empty?
              xmldoc_params[param_name.underscore] = " - ".blue + xmlElements2str(e.children, :blue, :green, :yellow)
            else
              xmldoc_params[param_name.underscore] = ""
            end
          end
        end
        
        param_infos = param_names.zip(param_types.map{|x| type2str(x)}, param_default)
        param_infos.shift if is_hide_this_param && param_names[0] == "this"
        if param_infos.empty?
          params = ""
        else
          params = "\n" + param_infos.map.with_index do |pi, i|
            "\t#{pi[0].light_green} :#{pi[1]}" + (pi[2].nil? ? "" : " = #{pi[2]}".magenta) \
              + (param_infos.size == i+1 ? "" : ",") \
              + xmldoc_params[pi[0]].to_s
          end.join("\n") + "\n"
        end
        "#{namespace.cyan}#{separator.cyan}#{name.bold}(#{params}) :#{type2str(return_type).light_red} #{xmldoc_returns}" \
          + (is_print_xmldoc_summary ? "\n\n#{xmldoc_summary}" : "")
      end
      
      def type2str(type)
        return "nil" if type.nil?
        return type.class_name if type.class == Class
        rt = type.ruby_type
        if type.is_a?(Types::EnumType) then "Enum" + rt.keys.to_s
        elsif type.is_a?(Types::ListType) ||
              type.is_a?(Types::SetType) 
          "#{rt.class_name}[#{type2str(type.value_type)}]"
        elsif type.is_a?(Types::DictionaryType)
          %Q{#{rt.class_name}[#{type2str(type.key_type)} => #{type2str(type.value_type)}]}
        elsif type.is_a?(Types::TupleType)
          %Q{#{rt.class_name}[#{type.value_types.map{|x| type2str(x)}.join(", ")}]}
        else rt.class_name end
      end
        
      def xmlElements2str(elements, main_color, paramref_color, value_color, error_color = :red)
        elements.map do |elem|
          if elem.is_a?(Nokogiri::XML::Text)
            elem.text.colorize(main_color)
          else
            begin
              case elem.name
                when "paramref" then elem.attr("name").underscore.colorize(paramref_color)
                when "a", "math" then elem.text.colorize(main_color)
                when "see"
                  type, _, cref = elem.attr("cref").rpartition(':')
                  cref = cref.split('.')
                  if type == 'T'
                    cref.join("::").colorize(value_color)
                  elsif type == 'M'
                    begin
                      val = cref[2].underscore.to_sym
                      raise RuntimeException unless ::KRPC::Gen.const_get(cref[0], false).const_get(cref[1], false)[val].is_a?(Integer)
                      (':' + val.to_s).colorize(value_color)
                    rescue
                      raise RuntimeException unless is_method_defined(["Services"] + cref) || is_method_defined(["Gen"] + cref)
                      (cref[0..-2].join("::") + "#").cyan + cref[-1].underscore
                    end
                  else raise RuntimeException end
                when "list"
                  "!n!" + elem.children.map{|ch| "!s! * ".bold + ch.text}.join("!n!").colorize(main_color)
                when "c"
                  elem.text.gsub("null","nil").colorize(value_color)
                else elem.to_s.colorize(error_color)
              end
            rescue RuntimeException => exc
              elem.to_s.colorize(error_color)
            end
          end
        end.join.gsub("\n"," ").gsub("!n!","\n").squeeze(' ').strip.gsub("!s!"," ")
      end
      
      def is_method_defined(path_array)
        method_name = path_array[-1].underscore
        begin
          cls = path_array[0..-2].inject(::KRPC){|a,e| a.const_get(e, false) }
          cls.method_defined?(method_name)
        rescue NameError
          false
        end
      end
      
    end
    
    
    module SuffixMethods
      DOCSTRING_SUFFIX = "_doc"
      DOCSTRING_SUFFIX_REGEX = /^(.+)(?:#{DOCSTRING_SUFFIX}(=)?)$/
      
      def self.included(base)
        base.extend self
        class << base
          def krpc_name
            class_name
          end
        end
      end
      
      def method_missing(method, *args, &block)
        if DOCSTRING_SUFFIX_REGEX =~ method.to_s
          documented_method_name = $1 + $2.to_s
          if respond_to? documented_method_name.to_sym
            return puts Doc.docstring_for_method(self,documented_method_name)
          end
        end
        super
      end
      
      def respond_to_missing?(method, *)
        if DOCSTRING_SUFFIX_REGEX =~ method.to_s
          return true if respond_to? ($1 + $2.to_s).to_sym
        end
        super
      end
    end
    
  end
end
