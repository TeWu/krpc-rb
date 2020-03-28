require 'krpc/types'


RSpec.describe KRPC::Streaming do
  include_context "test client support"

  def expect_equal_allow_delay(actual_getter, expected, retry_delay=0.1, max_retries=16)
    i = 0
    while i<max_retries do
      i += 1
      return if actual_getter.call == expected
      sleep retry_delay
    end
    expect(actual_getter).to eq expected
  end


  specify "error handling" do
    expect { @test_service.throw_argument_exception_stream }.to raise_error(KRPC::RPCError, /^KRPC.ArgumentException: Invalid argument/)
    expect { @test_service.throw_invalid_operation_exception_stream }.to raise_error(KRPC::RPCError, /^KRPC.InvalidOperationException: Invalid operation/)
    expect { @test_service.throw_argument_null_exception_stream("") }.to raise_error(KRPC::RPCError, /^KRPC.ArgumentNullException: Value cannot be null.\nParameter name: foo/)
    expect { @test_service.throw_argument_out_of_range_exception_stream(0) }.to raise_error(KRPC::RPCError, /^KRPC.ArgumentOutOfRangeException: Specified argument was out of the range of valid values.\nParameter name: foo/)
    expect { @test_service.throw_custom_exception_stream }.to raise_error(KRPC::RPCError, /^TestService.CustomException: A custom kRPC exception/)
  end

  specify "value parameters handling" do
    expect(@test_service.float_to_string_stream(3.14159).get).to match(/3[\.,]14159/)
  end

  specify "multiple value parameters handling" do
    expect(@test_service.add_multiple_values_stream(0.14159, 1, 2).value).to match(/3[\.,]14159/)
  end

  specify "incorrect parameter type handling" do
    expect { @test_service.float_to_string_stream("foo") }.to raise_error(KRPC::ArgumentErrorSig)
  end

  specify "properties handling" do
    @test_service.string_property = "foo"
    stream = @test_service.string_property_stream
    expect(stream.get).to eq "foo"
    @test_service.string_property = "bar"
    expect_equal_allow_delay(lambda{stream.get}, "bar")
    obj1 = @test_service.create_test_object("bar1")
    obj2 = @test_service.create_test_object("bar2")
    @test_service.object_property = obj1
    stream2 = @test_service.object_property_stream
    expect(stream2.get).to eq obj1
    @test_service.object_property = obj2
    expect_equal_allow_delay(lambda{stream2.get}, obj2)
  end

  specify "named parameters handling" do
    obj = @test_service.create_test_object("jeb")
    obj8 = @test_service.create_test_object("8")
    expect(obj.optional_arguments_stream(z: "1", x: "2", obj: obj8, y: "4").get).to eq "2418"
    expect(obj.optional_arguments_stream("1", "2", obj: obj8).get).to eq "12bar8"
  end

  specify "KRPC::Streaming::Stream object info" do
    obj = @test_service.create_test_object("bob")
    stream = obj.float_to_string_stream(3.14159)
    expect(stream.method).to eq obj.method(:float_to_string)
    expect(stream.args).to eq [3.14159]
    expect(stream.kwargs).to eq ({})
    expect(stream.return_type).to eq KRPC::TypeStore[PB::Type.new(code: :STRING)]

    stream2 = @test_service.optional_arguments_stream(z: "bob", x: "foo")
    expect(stream2.method).to eq @test_service.method(:optional_arguments)
    expect(stream2.args).to eq []
    expect(stream2.kwargs).to eq ({z: "bob", x: "foo"})
    expect(stream2.return_type).to eq KRPC::TypeStore[PB::Type.new(code: :STRING)]
  end

  specify "KRPC::Streaming::Stream#active?" do
    stream = @test_service.optional_arguments_stream(5)
    stream2 = @test_service.optional_arguments_stream(6)
    expect(stream.active?).to be true
    expect(stream2.active?).to be true
    stream.close
    expect(stream.active?).to be false
    expect(stream2.active?).to be true
    stream.close
    stream.remove
    expect(stream.active?).to be false
    expect(stream2.active?).to be true
    stream2.remove
    expect(stream.active?).to be false
    expect(stream2.active?).to be false
  end

  specify "Streams disconnect when client disconnects" do
    stream = @test_service.optional_arguments_stream(3)
    stream2 = @test_service.optional_arguments_stream(4)
    stream.close
    expect(stream.active?).to be false
    expect(stream2.active?).to be true
    @test_client.close
    expect(stream.active?).to be false
    expect(stream2.active?).to be false
    @test_client.connect
    expect(stream.active?).to be false
    expect(stream2.active?).to be false
  end

  specify "Streams rate control" do
    stream = @test_service.counter_stream
    stream.rate = 50
    expect(stream.rate).to eq 50
    stream.rate = 10
    expect(stream.rate).to eq 10
    stream.close
  end

end

