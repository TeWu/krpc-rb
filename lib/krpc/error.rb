
module KRPC

  class Error < Exception; end

  class ConnectionError < Error; end
  class RPCError < Error; end
  class ValueError < Error; end
  class ProcedureNameParserError < Error; end


  class ArgumentError < Error; end
  class ArgumentErrorSig < ArgumentError
    attr_reader :message_without_signature, :signature

    def initialize(msg = nil, sig = nil)
      @message_without_signature, @signature = msg, sig
      super(signature.nil? ? msg : msg + "\n" + signature.to_s)
    end

    def with_signature(sig)
      self.class.new(message_without_signature, sig)
    end
  end

  class ArgumentsNumberErrorSig < ArgumentErrorSig
    attr_reader :args_count, :valid_params_count_range

    def initialize(args_count, valid_params_count_range, sig = nil)
      @args_count, @valid_params_count_range = args_count, valid_params_count_range
      valid_params_str = (valid_params_count_range.min == valid_params_count_range.max ? valid_params_count_range.min : valid_params_count_range).to_s
      super("wrong number of arguments (#{args_count} for #{valid_params_str})", sig)
    end

    def with_arguments_count_incremented_by(args_count_increment)
      self.class.new(args_count + args_count_increment, (valid_params_count_range.min + args_count_increment)..(valid_params_count_range.max + args_count_increment), signature)
    end
    
    def with_signature(sig)
      self.class.new(args_count, valid_params_count_range, sig)
    end
  end

end
