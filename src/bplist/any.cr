class Bplist::Any
  # All possible Bplist types.
  alias Type = ValueType | Array(Bplist::Any) | Hash(String, Bplist::Any)

  alias ValueType = Nil |
                    Bool |
                    Int8 |
                    Int16 |
                    Int32 |
                    Int64 |
                    Int128 |
                    Float32 |
                    Float64 |
                    String |
                    Time |
                    Slice(UInt8)

  # Returns the raw underlying value.
  getter raw : Type

  # Creates a `Bplist::Any` that wraps the given value.
  def initialize(@raw : Type)
  end

  # Method to convert a value to the `Bplist::Any` type
  def self.convert(value : _) : Bplist::Any
    case value
    when Array
      # Convert each element of the array
      converted_array = value.map do |item|
        convert(item)
      end

      Bplist::Any.new(converted_array)
    when Hash
      # Convert each key-value pair of the hash
      converted_hash = Hash(String, Bplist::Any).new
      value.each do |key, val|
        converted_hash[key] = convert(val)
      end

      Bplist::Any.new(converted_hash)
    when Bplist::Any::ValueType
      Bplist::Any.new(value)
    when Bplist::Any
      value
    else
      raise Bplist::Error.new("Unsupported type: #{value.class}")
    end
  end

  # Assumes the underlying value is an `Array` and returns the element
  # at the given index.
  # Raises if the underlying value is not an `Array`.
  def [](index : Int) : Bplist::Any
    case object = @raw
    when Array
      object[index]
    else
      raise Bplist::Error.new("Expected Array for #[](index : Int), not #{object.class}")
    end
  end

  # Assumes the underlying value is an `Array` and returns the element
  # at the given index, or `nil` if out of bounds.
  # Raises if the underlying value is not an `Array`.
  def []?(index : Int) : Bplist::Any?
    case object = @raw
    when Array
      object[index]?
    else
      raise Bplist::Error.new("Expected Array for #[]?(index : Int), not #{object.class}")
    end
  end

  # Assumes the underlying value is a `Hash` and returns the element
  # with the given key.
  # Raises if the underlying value is not a `Hash`.
  def [](key : String) : Bplist::Any
    case object = @raw
    when Hash
      object[key]
    else
      raise Bplist::Error.new("Expected Hash for #[](key : String), not #{object.class}")
    end
  end

  # Assumes the underlying value is a `Hash` and returns the element
  # with the given key, or `nil` if the key is not present.
  # Raises if the underlying value is not a `Hash`.
  def []?(key : String) : Bplist::Any?
    case object = @raw
    when Hash
      object[key]?
    else
      raise Bplist::Error.new("Expected Hash for #[]?(key : String), not #{object.class}")
    end
  end

  # Traverses the depth of a structure and returns the value.
  # Returns `nil` if not found.
  def dig?(index_or_key : String | Int, *subkeys) : Bplist::Any?
    self[index_or_key]?.try &.dig?(*subkeys)
  end

  # :nodoc:
  def dig?(index_or_key : String | Int) : Bplist::Any?
    case @raw
    when Hash, Array
      self[index_or_key]?
    else
      nil
    end
  end

  # Traverses the depth of a structure and returns the value, otherwise raises.
  def dig(index_or_key : String | Int, *subkeys) : Bplist::Any
    self[index_or_key].dig(*subkeys)
  end

  # :nodoc:
  def dig(index_or_key : String | Int) : Bplist::Any
    self[index_or_key]
  end

  def as_s : String
    @raw.as(String)
  end

  # Checks that the underlying value is `Hash`, and returns its value.
  # Raises otherwise.
  def as_h : Hash(String, Bplist::Any)
    @raw.as(Hash)
  end

  # Checks that the underlying value is `Array`, and returns its value.
  # Raises otherwise.
  def as_a : Array(Bplist::Any)
    @raw.as(Array)
  end

  # Checks that the underlying value is `Array`, and returns its value.
  # Returns `nil` otherwise.
  def as_a? : Array(Bplist::Any)?
    @raw.as?(Array)
  end

  def inspect(io : IO) : Nil
    @raw.inspect(io)
  end

  def to_s(io : IO) : Nil
    @raw.to_s(io)
  end

  def pretty_print(pp)
    @raw.pretty_print(pp)
  end

  # Returns `true` if both `self` and *other*'s raw object are equal.
  def ==(other : Bplist::Any)
    raw == other.raw
  end

  # Returns `true` if the raw object is equal to *other*.
  def ==(other)
    raw == other
  end

  def_hash raw
end
