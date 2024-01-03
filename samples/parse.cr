require "../src/bplist"

Bplist::Parser.debug = true

# diff -y <(xxd assets/example.plist) <(xxd assets/example_mod.plist)

# bplist = Bplist::Parser.new("#{__DIR__}/../assets/example.plist")
bplist = Bplist::Parser.new("#{__DIR__}/../assets/example_mod.plist")

begin
  bplist.print_objects
  result = bplist.parse
  pp result
  # pp result.as_h.keys
ensure
  # bplist.close
end
