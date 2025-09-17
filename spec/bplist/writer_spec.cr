require "../spec_helper"

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
end
