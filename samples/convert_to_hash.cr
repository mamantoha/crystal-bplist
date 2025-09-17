require "../src/bplist"

# Parse a bplist file
bplist = Bplist::Parser.new("#{__DIR__}/../assets/example.plist")
result = bplist.parse

puts "Original Bplist::Any result:"
pp result

puts "\n" + "="*50 + "\n"

# Convert to a modifiable Crystal Hash
modifiable_hash = result.to_hash

puts "Converted to modifiable Hash:"
pp modifiable_hash

# Add a new key
modifiable_hash["NewKey"] = "NewValue"

# Modify an existing value
modifiable_hash["ExampleString"] = "Modified string!"

# Access nested data and modify it
if modifiable_hash["ExampleDictionary"]?.is_a?(Hash)
  nested = modifiable_hash["ExampleDictionary"].as(Hash)
  nested["NewNestedKey"] = "Nested value"
  nested["ExampleDate"] = "Modified date"
end

puts "\n" + "="*50 + "\n"

# We can also convert arrays
if modifiable_hash["ExampleDictionary"]?.is_a?(Hash)
  nested = modifiable_hash["ExampleDictionary"].as(Hash)
  if nested["ExampleArray"]?.is_a?(Array)
    modifiable_array = nested["ExampleArray"].as(Array)
    modifiable_array << "New array item"
  end
end

puts "After modifications:"
pp modifiable_hash
