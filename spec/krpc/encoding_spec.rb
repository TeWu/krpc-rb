require "krpc/encoder"
require "krpc/decoder"

RSpec.describe "protocol buffer encoding" do
  Encoder = KRPC::Encoder
  Decoder = KRPC::Decoder
  TypeStore = KRPC::TypeStore


  it "encodes float" do
    t = get_type :FLOAT
    check_close 0, "00000000", t
    check_close -1.0, "000080bf", t
    check_close 3.14159265359, "db0f4940", t
  end

  it "encodes double" do
    t = get_type :DOUBLE
    check_close 0.0, "0000000000000000", t
    check_close -1.0, "000000000000f0bf", t
    check_close 3.14159265359, "ea2e4454fb210940", t
  end

  it "encodes sint32" do
    t = get_type :SINT32
    check_equal 0, "00", t
    check_equal 1, "02", t
    check_equal 42, "54", t
    check_equal 1108, "a811", t
    check_equal -1, "01", t
    check_equal -33, "41", t
    check_equal -1621, "a919", t
  end

  it "encodes sint64" do
    t = get_type :SINT64
    check_equal 0, "00", t
    check_equal 1, "02", t
    check_equal 42, "54", t
    check_equal 1108, "a811", t
    check_equal -1, "01", t
    check_equal -33, "41", t
    check_equal -1621, "a919", t
    check_equal 1234567890000, "a091d89fee47", t
  end

  it "encodes uint32" do
    t = get_type :UINT32
    check_equal 0, "00", t
    check_equal 1, "01", t
    check_equal 42, "2a", t
    check_equal 300, "ac02", t
  end

  it "encodes uint64" do
    t = get_type :UINT64
    check_equal 0, "00", t
    check_equal 1, "01", t
    check_equal 42, "2a", t
    check_equal 300, "ac02", t
    check_equal 1234567890000, "d088ec8ff723", t
  end

  it "encodes bool" do
    t = get_type :BOOL
    check_equal true, "01", t
    check_equal false, "00", t
  end

  it "encodes string" do
    t = get_type :STRING
    check_equal "", "00", t
    check_equal "testing", "0774657374696e67", t
    check_equal "One small step for Kerbal-kind!", "1f4f6e6520736d616c6c207374657020666f72204b657262616c2d6b696e6421", t
    check_equal "\xe2\x84\xa2", "03e284a2", t
    check_equal "Mystery Goo\xe2\x84\xa2 Containment Unit", "1f4d79737465727920476f6fe284a220436f6e7461696e6d656e7420556e6974", t
  end

  it "encodes bytes" do
    t = get_type :BYTES
    check_equal [], "00", t
    check_equal [0xBA,0xDA,0x55], "03bada55", t
    check_equal [0xDE,0xAD,0xBE,0xEF], "04deadbeef", t
  end

  it "encodes list" do
    t = get_type :LIST, type_codes: [:SINT32]
    check_equal [], "", t
    check_equal [1], "0a0102", t
    check_equal [1,2,3,4], "0a01020a01040a01060a0108", t
  end

  it "encodes dictionary" do
    t = get_type :DICTIONARY, type_codes: [:STRING, :SINT32]
    check_equal({}, "", t)
    check_equal({"" => 0}, "0a060a0100120100", t)
    check_equal({"foo" => 42, "bar" => 365, "baz" => 3}, "0a090a0403666f6f1201540a0a0a04036261721202da050a090a040362617a120106", t)
  end

  it "encodes set" do
    t = get_type :SET, type_codes: [:UINT32]
    check_equal [].to_set, "", t
    check_equal [1].to_set, "0a0101", t
    check_equal [1,2,3,4].to_set, "0a01010a01020a01030a0104", t
  end

  it "encodes tuple" do
    t1 = get_type :TUPLE, type_codes: [:UINT32]
    check_equal [1], "0a0101", t1

    t2 = get_type :TUPLE, type_codes: [:UINT32, :STRING, :BOOL]
    check_equal [1,"jeb",false], "0a01010a04036a65620a0100", t2
  end

  it "encodes message" do
    t = get_type :PROCEDURE_CALL
    msg = PB::ProcedureCall.new(service: "ServiceName", procedure: "ProcedureName")
    data = "0a0b536572766963654e616d65120d50726f6365647572654e616d65"
    check_equal msg, data, t

    t2 = get_type :STATUS
    msg2 = PB::Status.new(
      version: "one",
      bytes_read: 2,
      bytes_read_rate: 4.5,
      bytes_written_rate: 6.7,
      rpcs_executed: 8,
      rpc_rate: 9.10,
      one_rpc_per_update: true,
      max_time_per_update: 11,
      adaptive_rate_control: false,
      blocking_recv: true,
      stream_rpcs: 19
    )
    data2 = "0a036f6e65100225000090402d6666d64030083d9a9911414001480b5801800113"
    check_equal msg2, data2, t2
  end

  it "encodes message with size" do
    msg = PB::Request.new(
      calls: [PB::ProcedureCall.new(service: "ServiceName", procedure: "ProcedureName")]
    )
    data = "1e0a1c0a0b536572766963654e616d65120d50726f6365647572654e616d65"
    expect(hexlify(Encoder.encode_message_with_size(msg))).to eq data
  end


  def get_type(code, service: "", name: "", type_codes: [])
    types = type_codes.map {|tc| PB::Type.new(code: tc) }
    TypeStore[PB::Type.new(code: code, service: service, name: name, types: types)]
  end

  def hexlify(s)
    s.each_byte.map { |b| sprintf("%02x",b) }.join
  end

  def unhexlify(s)
    s.scan(/../).map { |x| x.hex.chr }.join
  end

  def check_close(value, data, type, delta = 0.0001)
    expect(hexlify(Encoder.encode(value, type))).to eq data
    expect(Decoder.decode(unhexlify(data), type, :clientless)).to be_within(delta).of(value)
  end

  def check_equal(value, data, type)
    expect(hexlify(Encoder.encode(value, type))).to eq data
    expect(Decoder.decode(unhexlify(data), type, :clientless)).to eq value
  end

end
