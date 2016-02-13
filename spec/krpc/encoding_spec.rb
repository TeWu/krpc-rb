require_relative '../spec_helpers'

require "krpc/encoder"
require "krpc/decoder"

describe "protocol buffer encoding" do

  Encoder = KRPC::Encoder
  Decoder = KRPC::Decoder
  TypeStore = KRPC::Types::TypeStore

  def hexlify(s)
    s.each_byte.map { |b| sprintf("%02x",b) }.join
  end

  def unhexlify(s)
    s.scan(/../).map { |x| x.hex.chr }.join
  end

  def check_close (value, data, type, delta = 0.0001)
    expect(hexlify(Encoder.encode(value, type))).to eq data
    expect(Decoder.decode(unhexlify(data), type, :clientless)).to be_within(delta).of(value)
  end

  def check_equal (value, data, type)
    expect(hexlify(Encoder.encode(value, type))).to eq data
    expect(Decoder.decode(unhexlify(data), type, :clientless)).to eq value
  end

  it "encodes float" do
    t = TypeStore["float"]
    check_close(0, "00000000", t)
    check_close(-1.0, "000080bf", t)
    check_close(3.14159265359, "db0f4940", t)
  end

  it "encodes double" do
    t = TypeStore["double"]
    check_close(0.0, "0000000000000000", t)
    check_close(-1.0, "000000000000f0bf", t)
    check_close(3.14159265359, "ea2e4454fb210940", t)
  end

  it "encodes int32" do
    t = TypeStore["int32"]
    check_equal(0, "00", t)
    check_equal(1, "01", t)
    check_equal(42, "2a", t)
    check_equal(300, "ac02", t)
    check_equal(-33, "dfffffffffffffffff01", t)
  end

  it "encodes int64" do
    t = TypeStore["int64"]
    check_equal(0, "00", t)
    check_equal(1, "01", t)
    check_equal(42, "2a", t)
    check_equal(300, "ac02", t)
    check_equal(-33, "dfffffffffffffffff01", t)
    check_equal(1234567890000, "d088ec8ff723", t)
  end

  it "encodes uint32" do
    t = TypeStore["uint32"]
    check_equal(0, "00", t)
    check_equal(1, "01", t)
    check_equal(42, "2a", t)
    check_equal(300, "ac02", t)
  end

  it "encodes uint64" do
    t = TypeStore["uint64"]
    check_equal(0, "00", t)
    check_equal(1, "01", t)
    check_equal(42, "2a", t)
    check_equal(300, "ac02", t)
    check_equal(1234567890000, "d088ec8ff723", t)
  end

  it "encodes bool" do
    t = TypeStore["bool"]
    check_equal(true, "01", t)
    check_equal(false, "00", t)
  end

  it "encodes string" do
    t = TypeStore["string"]
    check_equal("", "00", t)
    check_equal("testing", "0774657374696e67", t)
    check_equal("One small step for Kerbal-kind!", "1f4f6e6520736d616c6c207374657020666f72204b657262616c2d6b696e6421", t)
    check_equal("\xe2\x84\xa2", "03e284a2", t)
    check_equal("Mystery Goo\xe2\x84\xa2 Containment Unit", "1f4d79737465727920476f6fe284a220436f6e7461696e6d656e7420556e6974", t)
  end

  it "encodes bytes" do
    t = TypeStore["bytes"]
    check_equal([], "00", t)
    check_equal([0xBA,0xDA,0x55], "03bada55", t)
    check_equal([0xDE,0xAD,0xBE,0xEF], "04deadbeef", t)
  end

  it "encodes list" do
    t = TypeStore["List(int32)"]
    check_equal([], "", t)
    check_equal([1], "0a0101", t)
    check_equal([1,2,3,4], "0a01010a01020a01030a0104", t)
  end

  it "encodes dictionary" do
    t = TypeStore["Dictionary(string,int32)"]
    check_equal({}, "", t)
    check_equal({"" => 0}, "0a060a0100120100", t)
    check_equal({"foo" => 42, "bar" => 365, "baz" => 3}, "0a090a0403666f6f12012a0a0a0a04036261721202ed020a090a040362617a120103", t)
  end

  it "encodes set" do
    t = TypeStore["Set(int32)"]
    check_equal([].to_set, "", t)
    check_equal([1].to_set, "0a0101", t)
    check_equal([1,2,3,4].to_set, "0a01010a01020a01030a0104", t)
  end

  it "encodes tuple" do
    check_equal([1], "0a0101", TypeStore["Tuple(int32)"])
    check_equal([1,"jeb",false], "0a01010a04036a65620a0100", TypeStore["Tuple(int32,string,bool)"])
  end

  it "encodes message" do
    msg = KRPC::PB::Request.new(:service => "ServiceName", :procedure => "ProcedureName")
    data = "0a0b536572766963654e616d65120d50726f6365647572654e616d65"
    check_equal(msg, data, TypeStore["KRPC.Request"])
  end

end
