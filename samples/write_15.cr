require "../src/bplist"

Bplist::Writer.debug = true

hash = {
  "5zzzz"                                    => 5,
  "10zzzzzzzz"                               => 10,
  "14zzzzzzzzzzzz"                           => 14,
  "15zzzzzzzzzzzzz"                          => 15,
  "20zzzzzzzzzzzzzzzzzz"                     => 20,
  "30zzzzzzzzzzzzzzzzzzzzzzzzzzzz"           => 30,
  "40zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz" => 40,
  "ExampleArray"                             => [
    "Item 1",
    "Item 2",
    "Item 3",
    "Item 4",
    "Item 5",
    "Item 6",
    "Item 7",
    "Item 8",
    "Item 9",
    "Item 10",
    "Item 11",
    "Item 12",
    "Item 13",
    "Item 14",
    "Item 15",
  ],
  "ExampleHash" => {
    "Item 1"  => 1,
    "Item 2"  => 2,
    "Item 3"  => 3,
    "Item 4"  => 4,
    "Item 5"  => 5,
    "Item 6"  => 6,
    "Item 7"  => 7,
    "Item 8"  => 8,
    "Item 9"  => 9,
    "Item 10" => 10,
    "Item 11" => 11,
    "Item 12" => 12,
    "Item 13" => 13,
    "Item 14" => 14,
    "Item 15" => 15,

  },
}

writer = Bplist::Writer.new(hash)
writer.print_objects
writer.write_to_file("#{__DIR__}/../assets/example_mod.plist")
