require "../src/bplist"

# Bplist::Parser.debug = true

path = "#{Path.home}/Library/Application Support/com.apple.wallpaper/Store/Index.plist"
bplist = Bplist::Parser.new(path)

# bplist.print_objects
result = bplist.parse

# pp result

def rebuild_and_modify_bplist_any(value : Bplist::Any, path = [] of String) : Bplist::Any
  value = value.raw

  case value
  when Array
    # Convert each element of the array
    converted_array = value.map_with_index do |item, index|
      new_path = path + ["[#{index}]"]

      rebuild_and_modify_bplist_any(item, new_path)
    end

    Bplist::Any.new(converted_array)
  when Hash
    # Convert each key-value pair of the hash
    converted_hash = Hash(String, Bplist::Any).new
    value.each do |key, val|
      new_path = path + [key]

      converted_hash[key] = rebuild_and_modify_bplist_any(val, new_path)
    end

    Bplist::Any.new(converted_hash)
  when Bplist::Any::ValueType
    if path.last(3) == ["Files", "[0]", "relative"]
      value = "file:///path/to/something"
    end

    Bplist::Any.new(value)
  else
    raise Bplist::Error.new("Unsupported type: #{value.class}")
  end
end

modified_result = rebuild_and_modify_bplist_any(result)

p! modified_result
