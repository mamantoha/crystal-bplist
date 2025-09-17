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

  # Checks that the underlying value is `Int`, and returns its value as an `Int32`.
  # Raises otherwise.
  def as_i : Int32
    @raw.as(Int).to_i
  end

  # Checks that the underlying value is `Int`, and returns its value as an `Int32`.
  # Returns `nil` otherwise.
  def as_i? : Int32?
    as_i if @raw.is_a?(Int)
  end

  # Checks that the underlying value is `Int`, and returns its value as an `Int64`.
  # Raises otherwise.
  def as_i64 : Int64
    @raw.as(Int).to_i64
  end

  # Checks that the underlying value is `Int`, and returns its value as an `Int64`.
  # Returns `nil` otherwise.
  def as_i64? : Int64?
    as_i64 if @raw.is_a?(Int64)
  end

  # Checks that the underlying value is `Float` (or `Int`), and returns its value as an `Float64`.
  # Raises otherwise.
  def as_f : Float64
    case raw = @raw
    when Int
      raw.to_f
    else
      raw.as(Float64)
    end
  end

  # Checks that the underlying value is `Float` (or `Int`), and returns its value as an `Float64`.
  # Returns `nil` otherwise.
  def as_f? : Float64?
    case raw = @raw
    when Int
      raw.to_f
    else
      raw.as?(Float64)
    end
  end

  # Checks that the underlying value is `Float` (or `Int`), and returns its value as an `Float32`.
  # Raises otherwise.
  def as_f32 : Float32
    case raw = @raw
    when Int
      raw.to_f32
    else
      raw.as(Float).to_f32
    end
  end

  # Checks that the underlying value is `Float` (or `Int`), and returns its value as an `Float32`.
  # Returns `nil` otherwise.
  def as_f32? : Float32?
    case raw = @raw
    when Int
      raw.to_f32
    when Float
      raw.to_f32
    else
      nil
    end
  end

  # Checks that the underlying value is `String`, and returns its value.
  # Raises otherwise.
  def as_s : String
    @raw.as(String)
  end

  # Checks that the underlying value is `String`, and returns its value.
  # Returns `nil` otherwise.
  def as_s? : String?
    as_s if @raw.is_a?(String)
  end

  # Checks that the underlying value is `Slice(UInt8)`, and returns its value.
  # Raises otherwise.
  def as_bytes : Slice(UInt8)
    @raw.as(Slice(UInt8))
  end

  # Checks that the underlying value is `Slice(UInt8)`, and returns its value.
  # Returns `nil` otherwise.
  def as_bytes? : Slice(UInt8)?
    as_bytes if @raw.is_a?(Slice(UInt8))
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
