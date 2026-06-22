require "../spec_helper"

private def round_trip(hash)
  writer = Bplist::Writer.new(hash)
  Bplist::Parser.parse(writer.io.to_slice).to_h
end

describe Bplist::Writer do
  it "writes" do
    hash = {
      "ExampleDictionary" => {
        "ExampleDate"  => Time.parse("2023-04-01 12:00:00 +00:00", "%Y-%m-%d %H:%M:%S %z", Time::Location::UTC),
        "ExampleArray" => [
          "Item 1",
          "Item 2",
          "Item 3",
        ],
      },
      "ExampleString"  => "Hello, world!",
      "ExampleInteger" => 42,
      "ExampleBoolean" => true,
    }

    writer = Bplist::Writer.new(hash)

    io = IO::Memory.new

    File.open("#{__DIR__}/../../assets/example.plist", "r") do |file|
      IO.copy(file, io)
    end

    bytes = writer.io.to_slice

    bytes.should eq(io.to_slice)
  end

  it "round-trips string length boundaries" do
    hash = {
      "string_14"  => "a" * 14,
      "string_15"  => "b" * 15,
      "string_255" => "c" * 255,
      "string_256" => "d" * 256,
    }

    round_trip(hash).should eq(hash)
  end

  it "round-trips data length boundaries" do
    hash = {
      "data_14"  => Bytes.new(14, 0x14_u8),
      "data_15"  => Bytes.new(15, 0x15_u8),
      "data_255" => Bytes.new(255, 0x25_u8),
      "data_256" => Bytes.new(256, 0x26_u8),
    }

    result = round_trip(hash)

    result["data_14"].should eq(hash["data_14"])
    result["data_15"].should eq(hash["data_15"])
    result["data_255"].should eq(hash["data_255"])
    result["data_256"].should eq(hash["data_256"])
  end

  it "round-trips array and dict length boundaries" do
    hash = {
      "array_14" => (1..14).to_a,
      "array_15" => (1..15).to_a,
      "dict_14"  => (1..14).to_h { |i| {"key_#{i}", i} },
      "dict_15"  => (1..15).to_h { |i| {"key_#{i}", i} },
    }

    round_trip(hash).should eq(hash)
  end

  it "uses two-byte object references when object count exceeds 255" do
    hash = (1..130).to_h { |i| {"key_#{i}", i} }

    round_trip(hash).should eq(hash)
  end

  it "uses two-byte offset table entries when object offsets exceed 255" do
    hash = {
      "padding" => "x" * 260,
      "value"   => 42,
    }

    round_trip(hash).should eq(hash)
  end
end
