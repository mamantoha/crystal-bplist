require "../src/bplist"

Bplist::Writer.debug = true

#      1
hash = {
  # 2                    6
  "ExampleDictionary" => {
    # 7              9
    "ExampleDate" => Time.parse("2023-04-01 12:00:00 +00:00", "%Y-%m-%d %H:%M:%S %z", Time::Location::UTC),
    # 8               10
    "ExampleArray" => [
      # 11
      "Item 1",
      # 12
      "Item 2",
      # 13
      "Item 3",
    ],
  },
  # 3                14
  "ExampleString" => "Hello, world!",
  # 4                 15
  "ExampleInteger" => 42,
  # 5                 16
  "ExampleBoolean" => true,
}

writer = Bplist::Writer.new(hash)
writer.print_objects
writer.write_to_file("#{__DIR__}/../assets/example_mod.plist")
