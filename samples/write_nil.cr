require "../src/bplist"

# Xcode can't open generated file
Bplist::Writer.debug = true

hash = {
  "ExampleNil" => nil,
  "ExampleString" => "nil",
}

writer = Bplist::Writer.new(hash)
writer.print_objects
writer.write_to_file("#{__DIR__}/../assets/example_mod.plist")

# plutil -convert json assets/example_mod.plist && cat assets/example_mod.plist
# {"ExampleString":"nil","ExampleNil":null}
