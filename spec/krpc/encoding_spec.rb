# encoding: utf-8

require "krpc/encoder"
require "krpc/decoder"

RSpec.describe "protocol buffer encoding" do
  SERVER_STRING_ENCODING = Encoding::UTF_8
  NOT_SERVER_STRING_ENCODING_1 = Encoding::UTF_16
  NOT_SERVER_STRING_ENCODING_2 = Encoding::UTF_32

  Encoder = KRPC::Encoder
  Decoder = KRPC::Decoder
  TypeStore = KRPC::TypeStore


  it "encodes float" do
    c = create_checker :check_close, :FLOAT
    c.( 0, "00000000" )
    c.( -1.0, "000080bf" )
    c.( 3.14159265359, "db0f4940" )
  end

  it "encodes double" do
    c = create_checker :check_close, :DOUBLE
    c.( 0.0, "0000000000000000" )
    c.( -1.0, "000000000000f0bf" )
    c.( 3.14159265359, "ea2e4454fb210940" )
  end

  it "encodes sint32" do
    c = create_checker :check_equal, :SINT32
    c.( 0, "00" )
    c.( 1, "02" )
    c.( 42, "54" )
    c.( 1108, "a811" )
    c.( -1, "01" )
    c.( -33, "41" )
    c.( -1621, "a919" )
  end

  it "encodes sint64" do
    c = create_checker :check_equal, :SINT64
    c.( 0, "00" )
    c.( 1, "02" )
    c.( 42, "54" )
    c.( 1108, "a811" )
    c.( -1, "01" )
    c.( -33, "41" )
    c.( -1621, "a919" )
    c.( 1234567890000, "a091d89fee47" )
  end

  it "encodes uint32" do
    c = create_checker :check_equal, :UINT32
    c.( 0, "00" )
    c.( 1, "01" )
    c.( 42, "2a" )
    c.( 300, "ac02" )
  end

  it "encodes uint64" do
    c = create_checker :check_equal, :UINT64
    c.( 0, "00" )
    c.( 1, "01" )
    c.( 42, "2a" )
    c.( 300, "ac02" )
    c.( 1234567890000, "d088ec8ff723" )
  end

  it "encodes bool" do
    c = create_checker :check_equal, :BOOL
    c.( true, "01" )
    c.( false, "00" )
  end

  it "encodes string" do
    c = create_checker :check_equal, :STRING
    c.( "", "00" )
    c.( "testing", "0774657374696e67" )
    c.( "One small step for Kerbal-kind!", "1f4f6e6520736d616c6c207374657020666f72204b657262616c2d6b696e6421" )
    c.( "ZaŻółć gęŚlą jaźń", "1a5a61c5bbc3b3c582c4872067c499c59a6cc485206a61c5bac584" )
    c.( "¡Un pequeño paso para Kerbal!", "1fc2a1556e207065717565c3b16f207061736f2070617261204b657262616c21" )
    c.( "ケルバ種のための小さな一歩！", "2ae382b1e383abe38390e7a8aee381aee3819fe38281e381aee5b08fe38195e381aae4b880e6ada9efbc81" )
    c.( "\xe2\x84\xa2", "03e284a2" )
    c.( "Mystery Goo\xe2\x84\xa2 Containment Unit", "1f4d79737465727920476f6fe284a220436f6e7461696e6d656e7420556e6974" )
    # Characters from ASCII charset below are important - they cause strings with different character encodings to have different String#bytesize (e.g "πćgß種↓…³€łəżvæś" string have the same bytesize in both UTF-8 and UTF-16)
    c.( "πćgß種↓…³6€łəżvæś ASCII chars are here", "36cf80c48767c39fe7a8aee28693e280a6c2b336e282acc582c999c5bc76c3a6c59b204153434949206368617273206172652068657265" )
    c.( "πćgß種↓…³6€łəżvæś ASCII chars are here".encode(NOT_SERVER_STRING_ENCODING_1), "36cf80c48767c39fe7a8aee28693e280a6c2b336e282acc582c999c5bc76c3a6c59b204153434949206368617273206172652068657265" )
    c.( "πćgß種↓…³6€łəżvæś ASCII chars are here".encode(NOT_SERVER_STRING_ENCODING_2), "36cf80c48767c39fe7a8aee28693e280a6c2b336e282acc582c999c5bc76c3a6c59b204153434949206368617273206172652068657265" )
  end

  it "encodes bytes" do
    c = create_checker :check_equal, :BYTES
    c.( [], "00" )
    c.( [0xBA,0xDA,0x55], "03bada55" )
    c.( [0xDE,0xAD,0xBE,0xEF], "04deadbeef" )
  end

  it "encodes list" do
    c = create_checker :check_equal, get_type(:LIST, type_codes: [:SINT32])
    c.( [], "" )
    c.( [1], "0a0102" )
    c.( [1,2,3,4], "0a01020a01040a01060a0108" )
  end

  it "encodes dictionary" do
    c = create_checker :check_equal, get_type(:DICTIONARY, type_codes: [:STRING, :SINT32])
    c.( {}, "" )
    c.( {"" => 0}, "0a060a0100120100" )
    c.( {"foo" => 42, "bar" => 365, "baz" => 3}, "0a090a0403666f6f1201540a0a0a04036261721202da050a090a040362617a120106" )
  end

  it "encodes set" do
    c = create_checker :check_equal, get_type(:SET, type_codes: [:UINT32])
    c.( [].to_set, "" )
    c.( [1].to_set, "0a0101" )
    c.( [1,2,3,4].to_set, "0a01010a01020a01030a0104" )
  end

  it "encodes tuple" do
    t1 = get_type :TUPLE, type_codes: [:UINT32]
    check_equal t1, [1], "0a0101"

    t2 = get_type :TUPLE, type_codes: [:UINT32, :STRING, :BOOL]
    check_equal t2, [1,"jeb",false], "0a01010a04036a65620a0100"
  end

  it "encodes message" do
    t = get_type :PROCEDURE_CALL
    msg = PB::ProcedureCall.new(service: "ServiceName", procedure: "ProcedureName")
    data = "0a0b536572766963654e616d65120d50726f6365647572654e616d65"
    check_equal t, msg, data

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
    check_equal t2, msg2, data2
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

  def pb(v)
    PB::Argument.new(value: v).value # Pass value through protobuf library for processing (e.g. string transcoding)
  end

  def create_checker(method_name, type)
    type = get_type(type) if type.is_a? Symbol
    method(method_name).to_proc.curry.(type)
  end

  def check_close(type, value, data, delta = 0.0001)
    encoded_value = pb Encoder.encode(value, type)
    expect(hexlify(encoded_value)).to eq data

    decoded_value = Decoder.decode(pb(unhexlify(data)), type, :clientless)
    expect(decoded_value).to be_within(delta).of(value)
  end

  def check_equal(type, value, data)
    encoded_value = pb Encoder.encode(value, type)
    expect(hexlify(encoded_value)).to eq data

    decoded_value = Decoder.decode(pb(unhexlify(data)), type, :clientless)
    expected_decoded_value = value.is_a?(String) ? value.encode(SERVER_STRING_ENCODING) : value
    expect(decoded_value).to eq expected_decoded_value
  end

end
