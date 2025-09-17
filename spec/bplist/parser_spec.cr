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

  it "parses from Bytes" do
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

    # Read the file as bytes
    file_path = "#{__DIR__}/../../assets/example.plist"
    bytes = File.read(file_path).to_slice

    # Parse from bytes
    result = Bplist::Parser.parse(bytes)

    result.should eq(expected_result)
  end

  it "reads, modifies, writes, and reads again" do
    # Step 1: Read the original plist file
    original_file = "#{__DIR__}/../../assets/example.plist"
    bplist = Bplist::Parser.new(original_file)
    original_result = bplist.parse

    # Step 2: Convert to modifiable data
    data = original_result.to_h

    # Step 3: Modify the data
    data["ModifiedString"] = "This was modified!"
    data["NewInteger"] = 999
    data["NewBoolean"] = false
    data["NewTime"] = Time.utc(2024, 1, 1, 12, 0, 0)

    # Modify nested data
    if data["ExampleDictionary"]?.is_a?(Hash)
      nested = data["ExampleDictionary"].as(Hash)
      nested["ModifiedNestedKey"] = "Nested modification"
      nested["NewNestedValue"] = 123
    end

    # Step 4: Write to a temporary file
    tempfile = File.tempfile("test_modified", ".plist") do |file|
      writer = Bplist::Writer.new(data)
      writer.write_to_file(file.path)
    end

    # Step 5: Read the modified file back
    modified_bplist = Bplist::Parser.new(tempfile.path)
    modified_result = modified_bplist.parse

    # Step 6: Verify the modifications exist
    modified_data = modified_result.to_h

    # Check top-level modifications
    modified_data["ModifiedString"].should eq("This was modified!")
    modified_data["NewInteger"].should eq(999)
    modified_data["NewBoolean"].should eq(false)
    modified_data["NewTime"].should eq(Time.utc(2024, 1, 1, 12, 0, 0))

    # Check nested modifications
    modified_data["ExampleDictionary"].should be_a(Hash(String, Bplist::Any::NativeType))
    nested = modified_data["ExampleDictionary"].as(Hash(String, Bplist::Any::NativeType))
    nested["ModifiedNestedKey"].should eq("Nested modification")
    nested["NewNestedValue"].should eq(123)

    # Check that original data is still there
    modified_data["ExampleString"].should eq("Hello, world!")
    modified_data["ExampleInteger"].should eq(42)
    modified_data["ExampleBoolean"].should eq(true)

    # Clean up
    tempfile.delete
  end
end
