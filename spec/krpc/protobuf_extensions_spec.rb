require 'google/protobuf'


RSpec.describe KRPC::ProtobufExtensions do

  describe KRPC::ProtobufExtensions::SafeEquals do
    specify "#==" do
      class_type_msg_1a = PB::Type.new(code: :CLASS, service: "ServiceNameT", name: "ClassNameT1")
      class_type_msg_1b = PB::Type.new(code: :CLASS, service: "ServiceNameT", name: "ClassNameT1")
      class_type_msg_2a = PB::Service.new(name: "ServiceName", classes: [PB::Class.new(name: "ClassNameC1"), PB::Class.new(name: "ClassNameC2"), PB::Class.new(name: "ClassNameC3")])
      class_type_msg_2b = PB::Service.new(name: "ServiceName", classes: [PB::Class.new(name: "ClassNameC1"), PB::Class.new(name: "ClassNameC2"), PB::Class.new(name: "ClassNameC3")])
      repeated_field_1a = Google::Protobuf::RepeatedField.new(:int32, [1, 2, 3])
      repeated_field_1b = Google::Protobuf::RepeatedField.new(:int32, [1, 2, 3])
      distinct_messages_and_fields = [
        class_type_msg_1a, class_type_msg_2a, repeated_field_1a,
        PB::Type.new(code: :STRING),
        PB::Type.new(code: :CLASS, service: "ServiceNameT", name: "ClassNameT2"),
        PB::Class.new(name: "ClassName1"),
        PB::Class.new(name: "ClassName2"),
        PB::Service.new(name: "ServiceName"),
        Google::Protobuf::RepeatedField.new(:int32, [4, 5, 6])
      ]
      distinct_objects =  distinct_messages_and_fields + ["", [], nil, "test", ['a',:b,3], Object.new, :testing, 53, 5.3, true, false, {a: 1, b: 2, c: 3}]

      distinct_messages_and_fields.each do |msg|
        expect(msg == msg).to eq true
      end
      distinct_objects.permutation(2).each do |pair|
        expect(pair[0] == pair[1]).to eq false
      end
      expect(class_type_msg_1a == class_type_msg_1b).to eq true
      expect(class_type_msg_1a == class_type_msg_2b).to eq false
      expect(class_type_msg_2a == class_type_msg_2b).to eq true
      expect(class_type_msg_2a == class_type_msg_1b).to eq false
      expect(repeated_field_1a == repeated_field_1b).to eq true
      expect(repeated_field_1a == [1,2,3]).to eq true
      expect([1,2,3] == repeated_field_1a).to eq true
    end
  end


  describe KRPC::ProtobufExtensions::MessageExtensions do
    specify "#field_empty?" do
      type_msg1 = PB::Type.new(code: :CLASS, service: "ServiceNameT", name: "ClassNameT1")
      expect(type_msg1.field_empty? :code).to eq false
      expect(type_msg1.field_empty? :service).to eq false
      expect(type_msg1.field_empty? :types).to eq true

      type_msg2 = PB::Type.new
      expect(type_msg2.field_empty? :code).to eq false
      expect(type_msg2.field_empty? :service).to eq true
      expect(type_msg2.field_empty? :types).to eq true

      service_msg = PB::Service.new(name: "ServiceName", classes: [PB::Class.new(name: "ClassNameC1")])
      expect(service_msg.field_empty? :name).to eq false
      expect(service_msg.field_empty? :procedures).to eq true
      expect(service_msg.field_empty? :classes).to eq false

      stream_msg1 = PB::StreamResult.new(id: 123)
      expect(stream_msg1.field_empty? :id).to eq false
      expect(stream_msg1.field_empty? :result).to eq true

      stream_msg2 = PB::StreamResult.new(result: PB::ProcedureResult.new)
      expect(stream_msg2.field_empty? :id).to eq false
      expect(stream_msg2.field_empty? :result).to eq false
    end
  end


  describe KRPC::ProtobufExtensions::MessageExtensions do
    specify "delegation to #info" do
      proc = PB::Procedure.new(name: "ClassName_static_StaticMethodName")

      %i[ type setter? class_member? member_name class_name ].each do |method_name|
        expect(proc.send(method_name).nil?).to eq false
        expect(proc.send(method_name)).to eq proc.info.send(method_name)
      end
    end
  end

end
