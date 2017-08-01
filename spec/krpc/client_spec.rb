require_relative '../spec_helpers'


describe KRPC::Client do
  include_context "test client support"

  specify "error handling" do
    expect { @test_service.throw_argument_exception }.to raise_error(KRPC::RPCError, /Invalid argument/)
    expect { @test_service.throw_invalid_operation_exception }.to raise_error(KRPC::RPCError, /Invalid operation/)
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
    expect(KRPC::Gen::TestService::TestClass.static_method(@test_client, "bob", "bill")).to eq "jebbobbill"
  end

  specify "class properties handling" do
    obj = @test_service.create_test_object("jeb")
    obj.int_property = 0
    expect(obj.int_property).to eq 0
    obj.int_property = 42
    expect(obj.int_property).to eq 42
    obj2 = @test_service.create_test_object("kermin")
    obj.object_property = obj2
    expect(obj.object_property.remote_oid).to eq obj2.remote_oid
  end

  specify "optional arguments handling" do
    expect(@test_service.optional_arguments("jeb")).to eq "jebfoobarbaz"
    expect(@test_service.optional_arguments("jeb", "bob", "bill")).to eq "jebbobbillbaz"
  end

  specify "named parameters handling" do
    expect(@test_service.optional_arguments(x: "1", y: "2", z: "3", another_parameter: "4")).to eq "1234"
    expect(@test_service.optional_arguments(y: "4", z: "1", x: "2", another_parameter: "3")).to eq "2413"
    expect(@test_service.optional_arguments("1", "2", another_parameter: "3", z: "4")).to eq "1243"
    expect(@test_service.optional_arguments("1", "2", z: "3")).to eq "123baz"
    expect(@test_service.optional_arguments("1", "2", another_parameter: "3")).to eq "12bar3"
    expect { @test_service.optional_arguments("1", "2", "3", "4", another_parameter: "5") }.to raise_error(KRPC::ArgumentErrorSig, /there are both positional and keyword arguments for parameter "another_parameter"/)
    expect { @test_service.optional_arguments("1", "2", "3", y: "4") }.to raise_error(KRPC::ArgumentErrorSig, /there are both positional and keyword arguments for parameter "y"/)
    expect { @test_service.optional_arguments("1", foo: "4") }.to raise_error(KRPC::ArgumentErrorSig, /keyword arguments for non existing parameters: foo/)

    obj = @test_service.create_test_object("jeb")
    expect(obj.optional_arguments(x: "1", y: "2", z: "3", another_parameter: "4")).to eq "1234"
    expect(obj.optional_arguments(z: "1", x: "2", another_parameter: "3", y: "4")).to eq "2413"
    expect(obj.optional_arguments("1", "2", another_parameter: "3", z: "4")).to eq "1243"
    expect(obj.optional_arguments("1", "2", z: "3")).to eq "123baz"
    expect(obj.optional_arguments("1", "2", another_parameter: "3")).to eq "12bar3"
    expect { obj.optional_arguments("1", "2", "3", "4", another_parameter: "5") }.to raise_error(KRPC::ArgumentErrorSig, /there are both positional and keyword arguments for parameter "another_parameter"/)
    expect { obj.optional_arguments("1", "2", "3", y: "4") }.to raise_error(KRPC::ArgumentErrorSig, /there are both positional and keyword arguments for parameter "y"/)
    expect { obj.optional_arguments("1", foo: "4") }.to raise_error(KRPC::ArgumentErrorSig, /keyword arguments for non existing parameters: foo/)
  end

  specify "blocking procedure handling" do
    expect(@test_service.blocking_procedure(0, 0)).to eq 0
    expect(@test_service.blocking_procedure(1, 0)).to eq 1
    expect(@test_service.blocking_procedure(2)).to eq (1 + 2)
    expect(@test_service.blocking_procedure(42)).to eq (1..42).reduce(:+)
  end

  specify "wrong method arguments handling" do
    expect { @test_service.int32_to_string }.to raise_error(KRPC::ArgumentErrorSig, /missing argument for parameter "value"/)
    expect { @test_service.int32_to_string(2, 3) }.to raise_error(KRPC::ArgumentsNumberErrorSig, /wrong number of arguments \(2 for 1\)/)

    obj = @test_service.create_test_object("bob")
    expect { obj.object_to_string }.to raise_error(KRPC::ArgumentErrorSig, /missing argument for parameter "other"/)
    expect { obj.object_to_string(2) }.to raise_error(KRPC::ArgumentErrorSig, /argument for parameter "other" must be a KRPC::Gen::TestService::TestClass/)
    expect { obj.object_to_string(obj, 2) }.to raise_error(KRPC::ArgumentsNumberErrorSig, /wrong number of arguments \(2 for 1\)/)

    expect { KRPC::Gen::TestService::TestClass.static_method }.to raise_error(KRPC::ArgumentErrorSig, /missing argument for parameter "client"/)
    expect { KRPC::Gen::TestService::TestClass.static_method(2) }.to raise_error(KRPC::ArgumentErrorSig, /argument for parameter "client" must be a KRPC::Client -- got 2 of type /)
    expect { KRPC::Gen::TestService::TestClass.static_method(@test_client, "str", "str2", "str3") }.to raise_error(KRPC::ArgumentsNumberErrorSig, /wrong number of arguments \(4 for 1\.\.3\)/)

    expect { @test_service.optional_arguments("1", "2", "3", "4", "5") }.to raise_error(KRPC::ArgumentsNumberErrorSig, /wrong number of arguments \(5 for 1\.\.4\)/)
    obj = @test_service.create_test_object("jeb")
    expect { obj.optional_arguments("1", "2", "3", "4", "5") }.to raise_error(KRPC::ArgumentsNumberErrorSig, /wrong number of arguments \(5 for 1\.\.4\)/)
  end

  specify "enums handling" do
    expect(@test_service.enum_return).to eq :value_b
    expect(@test_service.enum_echo(:value_a)).to eq :value_a
    expect(@test_service.enum_echo(:value_b)).to eq :value_b
    expect(@test_service.enum_echo(:value_c)).to eq :value_c

    expect(@test_service.enum_default_arg(:value_a)).to eq :value_a
    expect(@test_service.enum_default_arg).to eq :value_c
    expect(@test_service.enum_default_arg(:value_b)).to eq :value_b

    expect(KRPC::Gen::TestService::TestEnum).to eq ({value_a: 0, value_b: 1, value_c: 2})
  end

  specify "invalid enum handling" do
    expect(KRPC::Gen::TestService::TestEnum[:value_invalid]).to eq nil
  end

  specify "collections handling" do
    expect(@test_service.increment_list([])).to eq []
    expect(@test_service.increment_list([0, 1, 2])).to eq [1, 2, 3]
    expect(@test_service.increment_dictionary({}, {})).to eq ({})
    expect(@test_service.increment_dictionary({a: 0, b: 1, c: 2}, {})).to eq ({"a" => 1, "b" => 2, "c" => 3})
    expect(@test_service.increment_set(Set.new)).to eq Set.new
    expect(@test_service.increment_set(Set.new([0, 1, 2]))).to eq Set.new([1, 2, 3])
    expect(@test_service.increment_tuple([1, 2])).to eq [2, 3]
    expect { @test_service.increment_list(nil) }.to raise_error(KRPC::ArgumentErrorSig, /argument for parameter "l" must be a Array -- got nil of type NilClass/)
    expect { @test_service.increment_set(nil) }.to raise_error(KRPC::ArgumentErrorSig, /argument for parameter "h" must be a Set -- got nil of type NilClass/)
    expect { @test_service.increment_dictionary(nil) }.to raise_error(KRPC::ArgumentErrorSig, /argument for parameter "d" must be a Hash -- got nil of type NilClass/)
  end

  specify "nested collections handling" do
    expect(@test_service.increment_nested_collection({}, {})).to eq ({})
    expect(@test_service.increment_nested_collection({"a" => [0, 1], b: [], c: [2]}, {})).to eq ({"a" => [1, 2], "b" => [], "c" => [3]})
  end

  specify "collections of objects handling" do
    list = @test_service.add_to_object_list([], "jeb")
    expect(list.length).to eq 1
    expect(list.first.get_value).to eq "value=jeb"
    list2 = @test_service.add_to_object_list(list, "bob")
    expect(list2.length).to eq 2
    expect(list2.first.get_value).to eq "value=jeb"
    expect(list2[1].get_value).to eq "value=bob"
  end

  specify "client generated members" do
    expect(@test_client.methods).to include(:krpc, :test_service)
  end

  specify "krpc service members" do
    expect(@test_client.krpc.class.instance_methods(false)).to include(:get_services, :get_status, :add_stream, :remove_stream, :clients, :current_game_scene)
  end

  specify "hardcoded core service members should be in sync with generated krpc service members" do
    core_service_members = @test_client.core.class.instance_methods(false)
    krpc_service_members = @test_client.krpc.class.instance_methods(false)
    expect(core_service_members).to match_array krpc_service_members
  end

  specify "test service generated members" do
    expected_static_methods = [
        :float_to_string,
        :double_to_string,
        :int32_to_string,
        :int64_to_string,
        :bool_to_string,
        :string_to_int32,
        :bytes_to_hex_string,
        :add_multiple_values,

        :create_test_object,
        :echo_test_object,

        :optional_arguments,

        :enum_return,
        :enum_echo,
        :enum_default_arg,

        :blocking_procedure,

        :increment_list,
        :increment_dictionary,
        :increment_set,
        :increment_tuple,
        :increment_nested_collection,
        :add_to_object_list,

        :counter,
        :throw_argument_exception,
        :throw_invalid_operation_exception
    ]
    expected_instance_methods = expected_static_methods + [
        :string_property,
        :string_property_private_get=,
        :string_property_private_set,
        :object_property
    ]

    expect(KRPC::Services::TestService.methods(false)).to include(*expected_static_methods)
    expect(KRPC::Services::TestService.instance_methods(false)).to include(*expected_instance_methods)
  end

  specify "test class generated members" do
    expected_static_methods = [:static_method]
    expected_instance_methods = expected_static_methods + [
        :get_value,
        :float_to_string,
        :object_to_string,
        :int_property,
        :object_property,
        :optional_arguments
    ]

    expect(KRPC::Gen::TestService::TestClass.methods(false)).to include(*expected_static_methods)
    expect(KRPC::Gen::TestService::TestClass.instance_methods(false)).to include(*expected_instance_methods)
  end

  specify "line endings handling" do
    strings = [
        "foo\nbar",
        "foo\rbar",
        "foo\n\rbar",
        "foo\r\nbar",
        "foo\x10bar",
        "foo\x13bar",
        "foo\x10\x13bar",
        "foo\x13\x10bar"
    ]
    strings.each do |str|
      @test_service.string_property = str
      expect(@test_service.string_property).to eq str
    end
  end

end
