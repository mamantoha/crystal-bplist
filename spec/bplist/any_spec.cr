require "../spec_helper"

describe Bplist::Any do
  describe "#to_hash" do
    it "converts a hash to a modifiable Crystal Hash" do
      original_hash = {
        "string"  => "value",
        "number"  => 42,
        "boolean" => true,
        "nested"  => {
          "inner" => "data",
        },
      }

      bplist_any = Bplist::Any.convert(original_hash)
      converted_hash = bplist_any.to_hash

      # Should contain the same data
      converted_hash["string"].should eq("value")
      converted_hash["number"].should eq(42)
      converted_hash["boolean"].should eq(true)
      converted_hash["nested"].should_not be_nil

      # Should be modifiable
      converted_hash["new_key"] = "new_value"
      converted_hash["new_key"].should eq("new_value")

      # Nested hash should also be modifiable
      nested = converted_hash["nested"].as(Hash)
      nested["another_key"] = "another_value"
      nested["another_key"].should eq("another_value")
    end

    it "raises error when called on non-hash" do
      bplist_any = Bplist::Any.convert("not a hash")

      expect_raises(Bplist::Error, "Expected Hash for #to_hash, not String") do
        bplist_any.to_hash
      end
    end
  end

  describe "#to_array" do
    it "converts an array to a modifiable Crystal Array" do
      original_array = [
        "string",
        42,
        true,
        ["nested", "array"],
      ]

      bplist_any = Bplist::Any.convert(original_array)
      converted_array = bplist_any.to_array

      # Should contain the same data
      converted_array[0].should eq("string")
      converted_array[1].should eq(42)
      converted_array[2].should eq(true)
      converted_array[3].should_not be_nil

      # Should be modifiable
      converted_array << "new_item"
      converted_array.last.should eq("new_item")

      # Nested array should also be modifiable
      nested = converted_array[3].as(Array)
      nested << "another_item"
      nested.last.should eq("another_item")
    end

    it "raises error when called on non-array" do
      bplist_any = Bplist::Any.convert("not an array")

      expect_raises(Bplist::Error, "Expected Array for #to_array, not String") do
        bplist_any.to_array
      end
    end
  end

  describe "#to_any" do
    it "converts to native Crystal types recursively" do
      original_data = {
        "array"  => [1, 2, {"nested" => "value"}],
        "string" => "test",
        "number" => 42,
      }

      bplist_any = Bplist::Any.convert(original_data)
      converted = bplist_any.to_any

      # Array should be converted
      converted.as(Hash)["array"].should_not be_nil
      array = converted.as(Hash)["array"].as(Array)
      array[0].should eq(1)
      array[1].should eq(2)
      array[2].should_not be_nil

      # Nested hash should be converted
      nested = array[2].as(Hash)
      nested["nested"].should eq("value")

      # Other values should be native types
      converted.as(Hash)["string"].should eq("test")
      converted.as(Hash)["number"].should eq(42)
    end

    it "converts simple values to themselves" do
      Bplist::Any.convert("string").to_any.should eq("string")
      Bplist::Any.convert(42).to_any.should eq(42)
      Bplist::Any.convert(true).to_any.should eq(true)
      Bplist::Any.convert(nil).to_any.should eq(nil)
    end
  end
end
