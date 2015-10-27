require_relative '../spec_helpers'


describe KRPC::Client do
  include_context "test client support"

  specify "error handling" do
    expect { @test_service.throw_argument_exception }.to raise_error(KRPC::RPCError, "Invalid argument")
    expect { @test_service.throw_invalid_operation_exception }.to raise_error(KRPC::RPCError, "Invalid operation")
  end

  specify "value parameters handling" do
    expect(@test_service.float_to_string(3.14159)).to match(/3[\.,]14159/)
    expect(@test_service.double_to_string(3.14159)).to match(/3[\.,]14159/)
    expect(@test_service.int32_to_string(42)).to eq "42"
    expect(@test_service.int64_to_string(123456789000)).to eq "123456789000"
    expect(@test_service.bool_to_string(true)).to eq "True"
    expect(@test_service.bool_to_string(false)).to eq "False"
    expect(@test_service.string_to_int32("12345")).to eq 12345
    expect(@test_service.bytes_to_hex_string("\xDE\xAD\xBE\xEF".bytes)).to eq "deadbeef"
  end

  specify "multiple value parameters handling" do
    expect(@test_service.add_multiple_values(0.14159, 1, 2)).to match(/3[\.,]14159/)
  end

  specify "auto value type conversion handling" do
    expect(@test_service.float_to_string(42)).to eq "42"
    expect(@test_service.float_to_string(42.0)).to eq "42"
    expect(@test_service.add_multiple_values(1, 2, 3)).to eq "6"
    expect(@test_service.float_to_string("42")).to eq "42"
  end

  specify "incorrect parameter type handling" do
    expect { @test_service.float_to_string("foo") }.to raise_error(KRPC::ArgumentErrorSig)
    expect { @test_service.add_multiple_values(1, 2, 3.0) }.to raise_error(KRPC::ArgumentErrorSig)
    expect { @test_service.add_multiple_values(0.14159, 'foo', 2) }.to raise_error(KRPC::ArgumentErrorSig)
  end

  specify "properties handling" do
    @test_service.string_property = "foo"
    expect(@test_service.string_property).to eq "foo"
    expect(@test_service.string_property_private_set).to eq "foo"
    @test_service.string_property_private_get = "foo"
    obj = @test_service.create_test_object("bar")
    @test_service.object_property = obj
    expect(@test_service.object_property).to eq obj
  end

  specify "class as return value handling" do
    obj = @test_service.create_test_object('jeb')
    expect(obj.class.name).to eq "KRPC::Gen::TestService::TestClass"
  end

  specify "class none value handling" do
    expect(@test_service.echo_test_object(nil)).to be nil
    obj = @test_service.create_test_object("bob")
    expect(obj.object_to_string(nil)).to eq "bobnull"
    # Check following doesn't throw an exception
    @test_service.object_property
    @test_service.object_property = nil
    expect(@test_service.object_property).to be nil
  end

  specify "class methods handling" do
    obj = @test_service.create_test_object("bob")
    expect(obj.get_value).to eq "value=bob"
    expect(obj.float_to_string(3.14159)).to match(/bob3[\.,]14159/)
    obj2 = @test_service.create_test_object("bill")
    expect(obj.object_to_string(obj2)).to eq "bobbill"
  end

  specify "class static methods handling" do
    expect(KRPC::Gen::TestService::TestClass.static_method(@test_client)).to eq "jeb"
    expect(KRPC::Gen::TestService::TestClass.static_method(@test_client,"bob", "bill")).to eq "jebbobbill"
  end

  specify "wrong method arguments handling" do
    expect { @test_service.int32_to_string }.to raise_error(KRPC::ArgumentErrorSig, /missing argument for parameter "value"/)
    expect { @test_service.int32_to_string(2, 3) }.to raise_error(KRPC::ArgumentsNumberErrorSig, /wrong number of arguments \(2 for 1\)/)

    obj = @test_service.create_test_object("bob")
    expect { obj.object_to_string }.to raise_error(KRPC::ArgumentErrorSig, /missing argument for parameter "other"/)
    expect { obj.object_to_string(2) }.to raise_error(KRPC::ArgumentErrorSig, /argument for parameter "other" must be a KRPC::Gen::TestService::TestClass/)
    expect { obj.object_to_string(obj, 2) }.to raise_error(KRPC::ArgumentsNumberErrorSig, /wrong number of arguments \(2 for 1\)/)

    expect { KRPC::Gen::TestService::TestClass.static_method }.to raise_error(KRPC::ArgumentErrorSig, /missing argument for parameter "client"/)
    expect { KRPC::Gen::TestService::TestClass.static_method(2) }.to raise_error(KRPC::ArgumentErrorSig, /argument for parameter "client" must be a KRPC::Client -- got 2 of type Fixnum/)
    expect { KRPC::Gen::TestService::TestClass.static_method(@test_client, "str", "str2", "str3") }.to raise_error(KRPC::ArgumentsNumberErrorSig, /wrong number of arguments \(4 for 1\.\.3\)/)
  end
  
end
