require "../src/bplist"

Bplist::Writer.debug = true

hash = {
  "ExampleDictionary" => {
    "ExampleArray" => [
      14.88,
      Float32::MIN,
      Float32::MAX,
      Float64::MIN,
      Float64::MAX,
      Int8::MIN,
      Int8::MAX,
      Int16::MIN,
      Int16::MAX,
      Int32::MIN,
      Int32::MAX,
      Int64::MIN,
      Int64::MAX,
      Int128::MIN,
      Int128::MAX,
    ],
  },
}

writer = Bplist::Writer.new(hash)
writer.print_objects
writer.write_to_file("#{__DIR__}/../assets/example_mod.plist")
