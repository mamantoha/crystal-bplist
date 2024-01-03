require "../src/bplist"

Bplist::Writer.debug = true

hash = {
  "ExampleDictionary" => {
    "ExampleDate"  => Time.parse("2023-04-01 12:00:00 +00:00", "%Y-%m-%d %H:%M:%S %z", Time::Location::UTC),
    "ExampleArray" => [
      "Item 1",
      "Item 2",
      "Item 3",
      "Item 1",
    ],
  },
  "DuplicatedDictionary" => {
    "ExampleDate"  => Time.parse("2023-04-01 12:00:00 +00:00", "%Y-%m-%d %H:%M:%S %z", Time::Location::UTC),
    "ExampleArray" => [
      "Item 1",
      "Item 2",
      "Item 3",
      "Item 1",
    ],
  },
  "DuplicatedArray" => [
    "Item 1",
    "Item 2",
    "Item 3",
    "Item 1",
  ],
  "ExampleString"       => "Hello, world!",
  "DuplicateString"     => "Hello, world!",
  "ExampleInteger"      => 42,
  "ExampleTrueBoolean"  => true,
  "ExampleFalseBoolean" => false,
  "ExampleNil"          => nil,
}

# 35 objects without compress
# writer = Bplist::Writer.new(hash, false)
writer = Bplist::Writer.new(hash, true)
writer.print_objects

writer.write_to_file("#{__DIR__}/../assets/example_mod.plist")
