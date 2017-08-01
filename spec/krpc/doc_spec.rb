require_relative '../spec_helpers'


describe KRPC::Doc do

  describe KRPC::Doc::SuffixMethods do
    include_context "test client support"

    specify "_doc suffix methods" do
      expect { @test_client.test_service_doc }.to output("\e[0;36;49mClient\e[0m\e[0;36;49m#\e[0m\e[1;39;49mtest_service\e[0m() :\e[0;91;49mTestService\e[0m \n\n\e[0;94;49m Service documentation string. \e[0m\n").to_stdout
      expect { @test_service.create_test_object_doc }.to output("\e[0;36;49mTestService\e[0m\e[0;36;49m.\e[0m\e[1;39;49mcreate_test_object\e[0m(\n\t\e[0;92;49mvalue\e[0m :String\n) :\e[0;91;49mTestClass\e[0m \n\n").to_stdout

      obj = @test_service.create_test_object("foo")
      expect { obj.get_value_doc }.to output("\e[0;36;49mTestService::TestClass\e[0m\e[0;36;49m#\e[0m\e[1;39;49mget_value\e[0m() :\e[0;91;49mString\e[0m \n\n\e[0;94;49m Method documentation string. \e[0m\n").to_stdout
      obj.int_property = 0
      int_property_setter_docstring = "\e[0;36;49mTestService::TestClass\e[0m\e[0;36;49m#\e[0m\e[1;39;49mint_property=\e[0m(\n\t\e[0;92;49mvalue\e[0m :Integer\n) :\e[0;91;49mnil\e[0m \n\n\e[0;94;49m Property documentation string. \e[0m\n"
      expect { obj.send('int_property=_doc') }.to output(int_property_setter_docstring).to_stdout
      expect { obj.int_property_doc = 1 }.to output(int_property_setter_docstring).to_stdout
      expect(obj.int_property).to eq 0
    end

    specify ".krpc_name" do
      expect(@test_client.class.krpc_name).to eq "Client"
      expect(@test_service.class.krpc_name).to eq "TestService"
      obj = @test_service.create_test_object("foo")
      expect(obj.class.krpc_name).to eq "TestService::TestClass"
    end
  end

end
