require_relative '../spec_helpers'


describe KRPC::Attributes do
  include_context "test client support"
  Attributes = KRPC::Attributes
  ValueError = KRPC::ValueError

  specify "#is_a_property_accessor" do
    expect(Attributes.is_a_property_accessor([])).to be false
    expect(Attributes.is_a_property_accessor(["Property.Get(PropertyName)"])).to be true
    expect(Attributes.is_a_property_accessor(["Property.Set(PropertyName)"])).to be true
    expect(Attributes.is_a_property_accessor(["Class.Method(ServiceName.ClassName,MethodName)"])).to be false
    expect(Attributes.is_a_property_accessor(["Class.StaticMethod(ServiceName.ClassName,MethodName)"])).to be false
    expect(Attributes.is_a_property_accessor(["Class.Property.Get(ServiceName.ClassName,PropertyName)"])).to be false
    expect(Attributes.is_a_property_accessor(["Class.Property.Set(ServiceName.ClassName,PropertyName)"])).to be false
  end

  specify "#is_a_property_getter" do
    expect(Attributes.is_a_property_getter([])).to be false
    expect(Attributes.is_a_property_getter(["Property.Get(PropertyName)"])).to be true
    expect(Attributes.is_a_property_getter(["Property.Set(PropertyName)"])).to be false
    expect(Attributes.is_a_property_getter(["Class.Method(ServiceName.ClassName,MethodName)"])).to be false
    expect(Attributes.is_a_property_getter(["Class.StaticMethod(ServiceName.ClassName,MethodName)"])).to be false
    expect(Attributes.is_a_property_getter(["Class.Property.Get(ServiceName.ClassName,PropertyName)"])).to be false
    expect(Attributes.is_a_property_getter(["Class.Property.Set(ServiceName.ClassName,PropertyName)"])).to be false
  end

  specify "#is_a_property_setter" do
    expect(Attributes.is_a_property_setter([])).to be false
    expect(Attributes.is_a_property_setter(["Property.Get(PropertyName)"])).to be false
    expect(Attributes.is_a_property_setter(["Property.Set(PropertyName)"])).to be true
    expect(Attributes.is_a_property_setter(["Class.Method(ServiceName.ClassName,MethodName)"])).to be false
    expect(Attributes.is_a_property_setter(["Class.StaticMethod(ServiceName.ClassName,MethodName)"])).to be false
    expect(Attributes.is_a_property_setter(["Class.Property.Get(ServiceName.ClassName,PropertyName)"])).to be false
    expect(Attributes.is_a_property_setter(['Class.Property.Set(ServiceName.ClassName,PropertyName)'])).to be false
  end

  specify "#is_a_class_method" do
    expect(Attributes.is_a_class_method([])).to be false
    expect(Attributes.is_a_class_method(["Property.Get(PropertyName)"])).to be false
    expect(Attributes.is_a_class_method(["Property.Set(PropertyName)"])).to be false
    expect(Attributes.is_a_class_method(["Class.Method(ServiceName.ClassName,MethodName)"])).to be true
    expect(Attributes.is_a_class_method(["Class.StaticMethod(ServiceName.ClassName,MethodName)"])).to be false
    expect(Attributes.is_a_class_method(["Class.Property.Get(ServiceName.ClassName,PropertyName)"])).to be false
    expect(Attributes.is_a_class_method(["Class.Property.Set(ServiceName.ClassName,PropertyName)"])).to be false
  end

  specify "#is_a_class_property_accessor" do
    expect(Attributes.is_a_class_property_accessor([])).to be false
    expect(Attributes.is_a_class_property_accessor(["Property.Get(PropertyName)"])).to be false
    expect(Attributes.is_a_class_property_accessor(["Property.Set(PropertyName)"])).to be false
    expect(Attributes.is_a_class_property_accessor(["Class.Method(ServiceName.ClassName,MethodName)"])).to be false
    expect(Attributes.is_a_class_property_accessor(["Class.StaticMethod(ServiceName.ClassName,MethodName)"])).to be false
    expect(Attributes.is_a_class_property_accessor(["Class.Property.Get(ServiceName.ClassName,PropertyName)"])).to be true
    expect(Attributes.is_a_class_property_accessor(["Class.Property.Set(ServiceName.ClassName,PropertyName)"])).to be true
  end

  specify "#is_a_class_property_getter" do
    expect(Attributes.is_a_class_property_getter([])).to be false
    expect(Attributes.is_a_class_property_getter(["Property.Get(PropertyName)"])).to be false
    expect(Attributes.is_a_class_property_getter(["Property.Set(PropertyName)"])).to be false
    expect(Attributes.is_a_class_property_getter(["Class.Method(ServiceName.ClassName,MethodName)"])).to be false
    expect(Attributes.is_a_class_property_getter(["Class.StaticMethod(ServiceName.ClassName,MethodName)"])).to be false
    expect(Attributes.is_a_class_property_getter(["Class.Property.Get(ServiceName.ClassName,PropertyName)"])).to be true
    expect(Attributes.is_a_class_property_getter(["Class.Property.Set(ServiceName.ClassName,PropertyName)"])).to be false
  end

  specify "#is_a_class_property_setter" do
    expect(Attributes.is_a_class_property_setter([])).to be false
    expect(Attributes.is_a_class_property_setter(["Property.Get(PropertyName)"])).to be false
    expect(Attributes.is_a_class_property_setter(["Property.Set(PropertyName)"])).to be false
    expect(Attributes.is_a_class_property_setter(["Class.Method(ServiceName.ClassName,MethodName)"])).to be false
    expect(Attributes.is_a_class_property_setter(["Class.StaticMethod(ServiceName.ClassName,MethodName)"])).to be false
    expect(Attributes.is_a_class_property_setter(["Class.Property.Get(ServiceName.ClassName,PropertyName)"])).to be false
    expect(Attributes.is_a_class_property_setter(["Class.Property.Set(ServiceName.ClassName,PropertyName)"])).to be true
  end

  specify "#get_property_name" do
    expect { Attributes.get_property_name([]) }.to raise_error(ValueError)
    expect(Attributes.get_property_name(["Property.Get(PropertyName)"])).to eq "PropertyName"
    expect(Attributes.get_property_name(["Property.Set(PropertyName)"])).to eq "PropertyName"
    expect { Attributes.get_property_name(["Class.Method(ServiceName.ClassName,MethodName)"]) }.to raise_error(ValueError)
    expect { Attributes.get_property_name(["Class.StaticMethod(ServiceName.ClassName,MethodName)"]) }.to raise_error(ValueError)
    expect { Attributes.get_property_name(["Class.Property.Get(ServiceName.ClassName,PropertyName)"]) }.to raise_error(ValueError)
    expect { Attributes.get_property_name(["Class.Property.Set(ServiceName.ClassName,PropertyName)"]) }.to raise_error(ValueError)
  end

  specify "#get_service_name" do
    expect { Attributes.get_service_name([]) }.to raise_error(ValueError)
    expect { Attributes.get_service_name(["Property.Get(PropertyName)"]) }.to raise_error(ValueError)
    expect { Attributes.get_service_name(["Property.Set(PropertyName)"]) }.to raise_error(ValueError)
    expect(Attributes.get_service_name(["Class.Method(ServiceName.ClassName,MethodName)"])).to eq "ServiceName"
    expect(Attributes.get_service_name(["Class.StaticMethod(ServiceName.ClassName,MethodName)"])).to eq "ServiceName"
    expect(Attributes.get_service_name(["Class.Property.Get(ServiceName.ClassName,PropertyName)"])).to eq "ServiceName"
    expect(Attributes.get_service_name(["Class.Property.Set(ServiceName.ClassName,PropertyName)"])).to eq "ServiceName"
  end

  specify "#get_class_name" do
    expect { Attributes.get_class_name([]) }.to raise_error(ValueError)
    expect { Attributes.get_class_name(["Property.Get(PropertyName)"]) }.to raise_error(ValueError)
    expect { Attributes.get_class_name(["Property.Set(PropertyName)"]) }.to raise_error(ValueError)
    expect(Attributes.get_class_name(["Class.Method(ServiceName.ClassName,MethodName)"])).to eq "ClassName"
    expect(Attributes.get_class_name(["Class.StaticMethod(ServiceName.ClassName,MethodName)"])).to eq "ClassName"
    expect(Attributes.get_class_name(["Class.Property.Get(ServiceName.ClassName,PropertyName)"])).to eq "ClassName"
    expect(Attributes.get_class_name(["Class.Property.Set(ServiceName.ClassName,PropertyName)"])).to eq "ClassName"
  end

  specify "#get_class_method_or_property_name" do
    expect { Attributes.get_class_method_or_property_name([]) }.to raise_error(ValueError)
    expect { Attributes.get_class_method_or_property_name(["Property.Get(PropertyName)"]) }.to raise_error(ValueError)
    expect { Attributes.get_class_method_or_property_name(["Property.Set(PropertyName)"]) }.to raise_error(ValueError)
    expect(Attributes.get_class_method_or_property_name(["Class.Method(ServiceName.ClassName,MethodName)"])).to eq "MethodName"
    expect(Attributes.get_class_method_or_property_name(["Class.StaticMethod(ServiceName.ClassName,MethodName)"])).to eq "MethodName"
    expect(Attributes.get_class_method_or_property_name(["Class.Property.Get(ServiceName.ClassName,PropertyName)"])).to eq "PropertyName"
    expect(Attributes.get_class_method_or_property_name(["Class.Property.Set(ServiceName.ClassName,PropertyName)"])).to eq "PropertyName"
  end

  specify "#get_return_type_attributes" do
    expect(Attributes.get_return_type_attrs([])).to eq []
    expect(Attributes.get_return_type_attrs(["Class.Method(ServiceName.ClassName,MethodName)"])).to eq []
    expect(Attributes.get_return_type_attrs(["ReturnType.Class(ServiceName.ClassName)"])).to eq ["Class(ServiceName.ClassName)"]
    expect(Attributes.get_return_type_attrs(["Class.Method(ServiceName.ClassName,MethodName)", "ReturnType.Class(ServiceName.ClassName)"])).to eq ["Class(ServiceName.ClassName)"]
    expect(Attributes.get_return_type_attrs(["ReturnType.List(string)"])).to eq ["List(string)"]
    expect(Attributes.get_return_type_attrs(["ReturnType.Dictionary(int32,string)"])).to eq ["Dictionary(int32,string)"]
    expect(Attributes.get_return_type_attrs(["ReturnType.Set(string)"])).to eq ["Set(string)"]
    expect(Attributes.get_return_type_attrs(["ReturnType.List(Dictionary(int32,string))"])).to eq ["List(Dictionary(int32,string))"]
    expect(Attributes.get_return_type_attrs(["ReturnType.Dictionary(int32,List(ServiceName.ClassName))"])).to eq ["Dictionary(int32,List(ServiceName.ClassName))"]
  end

  specify "#get_parameter_type_attributes" do
    expect(Attributes.get_parameter_type_attrs(0, [])).to eq []
    expect(Attributes.get_parameter_type_attrs(0, ["Class.Method(ServiceName.ClassName,MethodName)"])).to eq []
    expect(Attributes.get_parameter_type_attrs(0, ["ReturnType.Class(ServiceName.ClassName)"])).to eq []
    expect(Attributes.get_parameter_type_attrs(0, ["Class.Method(ServiceName.ClassName,MethodName)", "ReturnType.Class(ServiceName.ClassName)"])).to eq []
    expect(Attributes.get_parameter_type_attrs(1, ["ParameterType(2).Class(ServiceName.ClassName)"])).to eq []
    expect(Attributes.get_parameter_type_attrs(2, ["ParameterType(2).Class(ServiceName.ClassName)"])).to eq ["Class(ServiceName.ClassName)"]
    expect(Attributes.get_parameter_type_attrs(2, ["ParameterType(0).Class(ServiceName.ClassName1)", "ParameterType(2).Class(ServiceName.ClassName2)"])).to eq ["Class(ServiceName.ClassName2)"]
    expect(Attributes.get_parameter_type_attrs(1, ["Class.Method(ServiceName.ClassName,MethodName)", "ParameterType(1).Class(ServiceName.ClassName)"])).to eq ["Class(ServiceName.ClassName)"]
    expect(Attributes.get_parameter_type_attrs(1, ["ParameterType(1).List(string)"])).to eq ["List(string)"]
    expect(Attributes.get_parameter_type_attrs(1, ["ParameterType(1).Dictionary(int32,string)"])).to eq ["Dictionary(int32,string)"]
    expect(Attributes.get_parameter_type_attrs(1, ["ParameterType(1).Set(string)"])).to eq ["Set(string)"]
    expect(Attributes.get_parameter_type_attrs(1, ["ParameterType(1).List(Dictionary(int32,string))"])).to eq ["List(Dictionary(int32,string))"]
    expect(Attributes.get_parameter_type_attrs(1, ["ParameterType(1).Dictionary(int32,List(ServiceName.ClassName))"])).to eq ["Dictionary(int32,List(ServiceName.ClassName))"]
  end

end
