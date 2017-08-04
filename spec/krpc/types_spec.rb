RSpec.describe KRPC::Types do
  include_context "test client support"

  describe KRPC::Types::TypeStore do

    let(:cache_values_by_type_code) {
      KRPC::Types::TypeStore.instance_variable_get(:@cache)
                            .values.group_by {|t| t.protobuf_type.code }
    }

    it "stores at most one ValueType instance per value type" do
      value_types_codes = [ :DOUBLE, :FLOAT, :SINT32, :SINT64, :UINT32, :UINT64, :BOOL, :STRING, :BYTES ]

      value_types_codes.each do |code|
        group = cache_values_by_type_code[code] || []
        if group.any?
          expect(group.size).to eq(1), "expected group.size to be 1, but got #{group.size}.\ngroup: #{group.inspect}"
          expect(group.first).to be_an_instance_of KRPC::Types::ValueType
        end
      end
    end

    it "stores at most one MessageType instance per message type" do
      message_types_codes = [ :PROCEDURE_CALL, :STREAM, :STATUS, :SERVICES ]

      message_types_codes.each do |code|
        group = cache_values_by_type_code[code] || []
        if group.any?
          expect(group.size).to eq(1), "expected group.size to be 1, but got #{group.size}.\ngroup: #{group.inspect}"
          expect(group.first).to be_an_instance_of KRPC::Types::MessageType
        end
      end
    end

    it "stores exactly one ClassType instance per (code, service_name, class_name) tuple" do
      cache_values_by_type_code[:CLASS]
        .group_by {|t| [t.protobuf_type.service, t.protobuf_type.name]}.values.each do |group|
          expect(group.size).to eq(1), "expected group.size to be 1, but got #{group.size}.\ngroup: #{group.inspect}"
          expect(group.first).to be_an_instance_of KRPC::Types::ClassType
        end
    end

    it "stores exactly one EnumType instance per (code, service_name, class_name) tuple" do
      cache_values_by_type_code[:ENUMERATION]
        .group_by {|t| [t.protobuf_type.service, t.protobuf_type.name]}.values.each do |group|
          expect(group.size).to eq(1), "expected group.size to be 1, but got #{group.size}.\ngroup: #{group.inspect}"
          expect(group.first).to be_an_instance_of KRPC::Types::EnumType
        end
    end

  end

end