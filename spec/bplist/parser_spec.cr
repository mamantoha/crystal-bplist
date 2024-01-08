require "../spec_helper"

describe Bplist::Parser do
  it ".parse" do
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

    expected_result = Bplist::Any.convert(hash)

    bplist = Bplist::Parser.new("#{__DIR__}/../../assets/example.plist")

    result = bplist.parse

    result.should eq(expected_result)
  end
end
