require_relative '../spec_helpers'


describe KRPC::ProcedureNameParser do
  ValueError = KRPC::ValueError
  ProcedureNameParserError = KRPC::ProcedureNameParserError


  def check(procedure_name:, type:, setter:, class_member:, member_name:, class_name: nil)
    p = PB::Procedure.new(name: procedure_name)
    expect( p.type ).to eq type
    expect( p.setter? ).to eq setter
    expect( p.class_member? ).to eq class_member
    expect( p.member_name ).to eq member_name
    if class_name
      expect( p.class_name ).to eq class_name
    else
      expect{ p.class_name }.to raise_error(ValueError)
    end
  end


  specify "empty procedure name" do
    expect { PB::Procedure.new(name: "").type }.to raise_error(ProcedureNameParserError, "Procedure name is empty")
  end

  specify "invalid procedure name" do
    expected_err = [ProcedureNameParserError, "Invalid procedure name"]
    expect { PB::Procedure.new(name: "ClassName_PropertyName_new_version").setter? }.to raise_error(*expected_err)
    expect { PB::Procedure.new(name: "ClassName_invalid_PropertyName").class_member? }.to raise_error(*expected_err)
    expect { PB::Procedure.new(name: "ClassName_StaticMethodName_static").member_name }.to raise_error(*expected_err)
  end

  specify "plain procedure" do
    check procedure_name: "ProcedureName",
          type:         :plain_procedure,
          setter:       false,
          class_member: false,
          member_name:  "ProcedureName"
  end

  specify "service property getter" do
    check procedure_name: "get_PropertyName",
          type:         :service_property_getter,
          setter:       false,
          class_member: false,
          member_name:  "PropertyName"
  end

  specify "service property setter" do
    check procedure_name: "set_PropertyName",
          type:         :service_property_setter,
          setter:       true,
          class_member: false,
          member_name:  "PropertyName"
  end

  specify "class method" do
    check procedure_name: "ClassName_MethodName",
          type:         :class_method,
          setter:       false,
          class_member: true,
          member_name:  "MethodName",
          class_name:   "ClassName"
  end

  specify "class static method" do
    check procedure_name: "ClassName_static_StaticMethodName",
          type:         :class_static_method,
          setter:       false,
          class_member: true,
          member_name:  "StaticMethodName",
          class_name:   "ClassName"
  end

  specify "class property getter" do
    check procedure_name: "ClassName_get_PropertyName",
          type:         :class_property_getter,
          setter:       false,
          class_member: true,
          member_name:  "PropertyName",
          class_name:   "ClassName"
  end

  specify "class property setter" do
    check procedure_name: "ClassName_set_PropertyName",
          type:         :class_property_setter,
          setter:       true,
          class_member: true,
          member_name:  "PropertyName",
          class_name:   "ClassName"
  end

end
