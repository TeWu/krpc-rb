require 'krpc/doc'
require 'krpc/streaming'
require 'krpc/core_extensions'
require 'colorize'

module KRPC
  module Gen
    class << self
      def service_gen_module(service_name)
        const_get_or_create(service_name, Module.new)
      end

      def generate_class(service_name, class_name)
        mod = service_gen_module(service_name)
        mod.const_get_or_create(class_name) do
          Class.new(ClassBase) do
            @service_name = service_name
            class << self; attr_reader :service_name end
          end
        end
      end

      def generate_enum(service_name, enum_name, values)
        mod = service_gen_module(service_name)
        mod.const_get_or_create(enum_name) do
          values.map{|ev| [ev.name.underscore.to_sym, ev.value]}.to_h
        end
      end

      def add_rpc_method(cls, method_name, service_name, proc, *options)
        is_static = options.include? :static
        prepend_self_to_args = options.include? :prepend_self_to_args
        param_names, param_types, param_default, return_type = parse_procedure(proc)
        method_name = method_name.underscore
        args = [cls, method_name, param_default, param_names, param_types, prepend_self_to_args, proc, return_type, service_name]

        define_rpc_method(*args)
        define_static_rpc_method(*args) if is_static
        add_stream_constructing_proc(*args) unless options.include? :no_stream
        Doc.add_docstring_info(is_static, cls, method_name, service_name, proc.name, param_names, param_types, param_default, return_type: return_type, xmldoc: proc.documentation)
      end

      def transform_exceptions(method_owner, method_name, prepend_self_to_args, &block)
        begin
          block.call
        rescue ArgumentsNumberErrorSig => err
          err = err.with_signature(Doc.docstring_for_method(method_owner, method_name, false))
          if prepend_self_to_args then raise err.with_arguments_count_incremented_by(-1)
          elsif method_owner.is_a?(Class) then raise err.with_arguments_count_incremented_by(1)
          else raise err end
        rescue ArgumentErrorSig => err
          raise err.with_signature(Doc.docstring_for_method(method_owner, method_name, false))
        end
      end

      private #----------------------------------

      def define_static_rpc_method(cls, method_name, param_default, param_names, param_types, prepend_self_to_args, proc, return_type, service_name)
        cls.instance_eval do
          define_singleton_method method_name do |*args|
            Gen.transform_exceptions(cls, method_name, prepend_self_to_args) do
              raise ArgumentErrorSig.new("missing argument for parameter \"client\"") if args.count < 1
              raise ArgumentErrorSig.new("argument for parameter \"client\" must be a #{KRPC::Client.name} -- got #{args.first.inspect} of type #{args.first.class}") unless args.first.is_a?(KRPC::Client)
              client = args.shift
              kwargs = args.extract_kwargs!
              client.execute_rpc(service_name, proc.name, args, kwargs, param_names, param_types, param_default, return_type: return_type)
            end
          end
        end
      end

      def define_rpc_method(cls, method_name, param_default, param_names, param_types, prepend_self_to_args, proc, return_type, service_name)
        cls.instance_eval do
          define_method method_name do |*args|
            Gen.transform_exceptions(self, method_name, prepend_self_to_args) do
              kwargs = args.extract_kwargs!
              args = [self] + args if prepend_self_to_args
              self.client.execute_rpc(service_name, proc.name, args, kwargs, param_names, param_types, param_default, return_type: return_type)
            end
          end
        end
      end

      def add_stream_constructing_proc(cls, method_name, param_default, param_names, param_types, prepend_self_to_args, proc, return_type, service_name)
        cls.stream_constructors[method_name] = Proc.new do |this, *args, **kwargs|
          Gen.transform_exceptions(this, method_name, prepend_self_to_args) do
            req_args = prepend_self_to_args ? [this] + args : args
            request = this.client.build_request(service_name, proc.name, req_args, kwargs, param_names, param_types, param_default)
            this.client.streams_manager.create_stream(request, return_type, this.method(method_name), *args, **kwargs)
          end
        end
      end

      def parse_procedure(proc)
        param_names = proc.parameters.map{|p| p.name.underscore}
        param_types = proc.parameters.map.with_index do |p,i|
          TypeStore.get_parameter_type(i, p.type, proc.attributes)
        end
        param_default = proc.parameters.zip(param_types).map do |param, type|
          if param.has_default_value
            Decoder.decode(param.default_value, type, :clientless)
          else :no_default_value
          end
        end
        return_type = if proc.has_return_type
                        TypeStore.get_return_type(proc.return_type, proc.attributes)
                      else nil end
        [param_names, param_types, param_default, return_type]
      end
    end

    module RPCMethodGenerator
      def include_rpc_method(method_name, service_name, procedure_name, params: [], return_type: nil, xmldoc: "", options: [])
        Gen.add_rpc_method(self.class, method_name, service_name, PB::Procedure.new(name: procedure_name, parameters: params, has_return_type: return_type != nil, return_type: return_type != nil ? return_type : "", documentation: xmldoc), options)
      end
    end

    ##
    # Base class for service-defined class types.
    class ClassBase
      include Doc::SuffixMethods
      include Streaming::StreamConstructors

      attr_reader :client, :remote_oid

      def self.krpc_name
        name[11..-1]
      end

      def initialize(client, remote_oid)
        @client, @remote_oid = client, remote_oid
      end

      alias_method :eql?, :==
      def ==(other)
        other.class == self.class and other.remote_oid == remote_oid
      end
      def hash
        remote_oid.hash
      end

      def to_s
        "#<#{self.class} @remote_oid=#{remote_oid}>"
      end

      def inspect
        "#<#{self.class} ".green + "@remote_oid" + "=".green + remote_oid.to_s.bold.blue + ">".green
      end
    end

  end
end
