require "../spec_helper"

private def round_trip(hash)
  writer = Bplist::Writer.new(hash)
  Bplist::Parser.parse(writer.io.to_slice).to_h
end

private def object_count(bytes : Bytes) : UInt64
  UInt64.from_be_bytes(bytes[bytes.size - 24, 8])
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

  it "round-trips nil values" do
    hash = {
      "nil"    => nil,
      "nested" => {
        "nil" => nil,
      },
      "array" => [nil, "value", nil],
    }

    round_trip(hash).should eq(hash)
  end

  it "round-trips boolean values" do
    hash = {
      "true"   => true,
      "false"  => false,
      "nested" => {
        "true"  => true,
        "false" => false,
      },
      "array" => [true, false, true],
    }

    round_trip(hash).should eq(hash)
  end

  it "round-trips integer boundaries" do
    hash = {
      "int8_min"    => Int8::MIN,
      "int8_max"    => Int8::MAX,
      "int16_min"   => Int16::MIN,
      "int16_max"   => Int16::MAX,
      "int32_min"   => Int32::MIN,
      "int32_max"   => Int32::MAX,
      "int64_min"   => Int64::MIN,
      "int64_max"   => Int64::MAX,
      "int128_min"  => Int128::MIN,
      "int128_max"  => Int128::MAX,
      "nested_ints" => [Int8::MIN, Int16::MAX, Int32::MIN, Int64::MAX, Int128::MIN],
    }

    round_trip(hash).should eq(hash)
  end

  it "round-trips float values" do
    hash = {
      "float32_min" => Float32::MIN,
      "float32_max" => Float32::MAX,
      "float64_min" => Float64::MIN,
      "float64_max" => Float64::MAX,
      "nested"      => [0.0_f32, -12.5_f32, 14.88, -0.25],
    }

    round_trip(hash).should eq(hash)
  end

  it "round-trips time values as UTC" do
    utc_time = Time.utc(2024, 1, 1, 12, 30, 15)
    local_time = Time.parse("2024-01-01 14:30:15 +02:00", "%Y-%m-%d %H:%M:%S %z", Time::Location::UTC)

    hash = {
      "utc"    => utc_time,
      "offset" => local_time,
      "nested" => [utc_time],
    }

    result = round_trip(hash)

    result["utc"].should eq(utc_time)
    result["offset"].should eq(local_time.to_utc)
    result["nested"].should eq([utc_time])
  end

  it "round-trips nested mixed values" do
    time = Time.utc(2024, 2, 3, 4, 5, 6)
    data = Bytes[0x01, 0x02, 0x03]
    hash = {
      "metadata" => {
        "enabled" => true,
        "count"   => 3,
        "ratio"   => 0.75,
        "created" => time,
        "payload" => data,
      },
      "items" => [
        {
          "name"   => "first",
          "active" => false,
          "values" => [1, 2.5, nil],
        },
        {
          "name"   => "second",
          "active" => true,
          "values" => [data, time],
        },
      ],
    }

    round_trip(hash).should eq(hash)
  end

  it "round-trips deeply nested arrays and hashes" do
    hash = {
      "level1" => {
        "level2" => [
          {
            "level3" => [
              {
                "level4" => {
                  "string" => "value",
                  "int"    => 42,
                  "float"  => 12.5_f32,
                  "bool"   => true,
                  "nil"    => nil,
                  "bytes"  => Bytes[0x04, 0x05],
                  "time"   => Time.utc(2024, 6, 1, 0, 0, 0),
                },
              },
            ],
          },
        ],
      },
    }

    round_trip(hash).should eq(hash)
  end

  it "round-trips compressed output" do
    hash = {
      "first"  => "same value",
      "second" => "same value",
      "array"  => ["same value", "same value"],
    }

    writer = Bplist::Writer.new(hash, true)

    Bplist::Parser.parse(writer.io.to_slice).to_h.should eq(hash)
  end

  it "deduplicates repeated values in compressed output" do
    hash = {
      "first"  => "same value",
      "second" => "same value",
      "array"  => ["same value", "same value"],
    }

    uncompressed = Bplist::Writer.new(hash, false).io.to_slice
    compressed = Bplist::Writer.new(hash, true).io.to_slice

    object_count(compressed).should be < object_count(uncompressed)
  end

  it "round-trips repeated booleans in compressed output" do
    hash = {
      "true"   => true,
      "false"  => false,
      "nested" => {
        "true"  => true,
        "false" => false,
      },
      "array" => [true, true, false, false],
    }

    writer = Bplist::Writer.new(hash, true)

    Bplist::Parser.parse(writer.io.to_slice).to_h.should eq(hash)
  end

  it "round-trips compressed nested arrays and hashes" do
    hash = {
      "first" => {
        "name"  => "same value",
        "items" => ["same value", "same value", 42],
      },
      "second" => {
        "name"  => "same value",
        "items" => ["same value", "same value", 42],
      },
    }

    writer = Bplist::Writer.new(hash, true)

    Bplist::Parser.parse(writer.io.to_slice).to_h.should eq(hash)
  end

  it "deduplicates repeated nested scalar values in compressed output" do
    hash = {
      "first" => {
        "name"  => "same value",
        "items" => ["same value", "same value", 42],
      },
      "second" => {
        "name"  => "same value",
        "items" => ["same value", "same value", 42],
      },
    }

    uncompressed = Bplist::Writer.new(hash, false).io.to_slice
    compressed = Bplist::Writer.new(hash, true).io.to_slice

    object_count(compressed).should be < object_count(uncompressed)
  end

  it "round-trips compressed duplicate keys in nested hashes" do
    hash = {
      "first" => {
        "shared_key" => "first value",
      },
      "second" => {
        "shared_key" => "second value",
      },
    }

    writer = Bplist::Writer.new(hash, true)

    Bplist::Parser.parse(writer.io.to_slice).to_h.should eq(hash)
  end

  it "writes to a file" do
    hash = {
      "value" => "written",
    }

    tempfile = File.tempfile("bplist_writer", ".plist") do |file|
      writer = Bplist::Writer.new(hash)
      writer.write_to_file(file.path)
    end

    Bplist::Parser.new(tempfile.path).parse.to_h.should eq(hash)
  ensure
    tempfile.try &.delete
  end
end
