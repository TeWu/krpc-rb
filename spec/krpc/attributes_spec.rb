require_relative '../spec_helpers'


describe KRPC::Attributes do
  Attributes = KRPC::Attributes
  ValueError = KRPC::ValueError

  TEST_STRINGS = [
    "",
    "ProcedureName",
    "get_PropertyName",
    "set_PropertyName",
    "ClassName_MethodName",
    "ClassName_static_StaticMethodName",
    "ClassName_get_PropertyName",
    "ClassName_set_PropertyName"
  ]

  def _check(method, *true_strings)
    for s in TEST_STRINGS
      expect(Attributes.send(method, s)).to be (true_strings.include? s)
    end
  end


  specify "#is_a_property_accessor" do
    _check(:is_a_property_accessor, "get_PropertyName", "set_PropertyName")
  end

  specify "#is_a_property_getter" do
    _check(:is_a_property_getter, "get_PropertyName")
  end

  specify "#is_a_property_setter" do
    _check(:is_a_property_setter, "set_PropertyName")
  end

  specify "#is_a_class_member" do
    _check(:is_a_class_member, "ClassName_MethodName", "ClassName_static_StaticMethodName",
                               "ClassName_get_PropertyName", "ClassName_set_PropertyName")
  end

  specify "#is_a_class_method" do
    _check(:is_a_class_method, "ClassName_MethodName")
  end

  specify "#is_a_class_static_method" do
    _check(:is_a_class_static_method, "ClassName_static_StaticMethodName")
  end

  specify "#is_a_class_property_accessor" do
    _check(:is_a_class_property_accessor, "ClassName_get_PropertyName", "ClassName_set_PropertyName")
  end

  specify "#is_a_class_property_getter" do
    _check(:is_a_class_property_getter, "ClassName_get_PropertyName")
  end

  specify "#is_a_class_property_setter" do
    _check(:is_a_class_property_setter, "ClassName_set_PropertyName")
  end

  specify "#get_class_name" do
    expect { Attributes.get_class_name("") }.to raise_error(ValueError)
    expect { Attributes.get_class_name("get_PropertyName") }.to raise_error(ValueError)
    expect { Attributes.get_class_name("set_PropertyName") }.to raise_error(ValueError)
    expect(Attributes.get_class_name("ClassName1_MethodName")).to eq "ClassName1"
    expect(Attributes.get_class_name("ClassName2_static_StaticMethodName")).to eq "ClassName2"
    expect(Attributes.get_class_name("ClassName3_get_PropertyName1")).to eq "ClassName3"
    expect(Attributes.get_class_name("ClassName4_set_PropertyName2")).to eq "ClassName4"
    expect { Attributes.get_class_name("PropertyName") }.to raise_error(ValueError)
  end

  specify "#get_class_member_name" do
    expect { Attributes.get_class_member_name("") }.to raise_error(ValueError)
    expect { Attributes.get_class_member_name("get_PropertyName") }.to raise_error(ValueError)
    expect { Attributes.get_class_member_name("set_PropertyName") }.to raise_error(ValueError)
    expect(Attributes.get_class_member_name("ClassName1_MethodName")).to eq "MethodName"
    expect(Attributes.get_class_member_name("ClassName2_static_StaticMethodName")).to eq "StaticMethodName"
    expect(Attributes.get_class_member_name("ClassName3_get_PropertyName1")).to eq "PropertyName1"
    expect(Attributes.get_class_member_name("ClassName4_set_PropertyName2")).to eq "PropertyName2"
    expect { Attributes.get_class_member_name("PropertyName") }.to raise_error(ValueError)
  end

  specify "#get_property_name" do
    expect { Attributes.get_property_name("") }.to raise_error(ValueError)
    expect(Attributes.get_property_name("get_PropertyName1")).to eq "PropertyName1"
    expect(Attributes.get_property_name("set_PropertyName2")).to eq "PropertyName2"
    expect { Attributes.get_property_name("ClassName1_MethodName") }.to raise_error(ValueError)
    expect { Attributes.get_property_name("ClassName2_static_StaticMethodName") }.to raise_error(ValueError)
    expect { Attributes.get_property_name("ClassName3_get_PropertyName1") }.to raise_error(ValueError)
    expect { Attributes.get_property_name("ClassName4_set_PropertyName2") }.to raise_error(ValueError)
    expect { Attributes.get_property_name("PropertyName") }.to raise_error(ValueError)
  end

end
