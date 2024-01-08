module Bplist
  class Parser
    HEADER_SIZE                    =  8
    TRAILER_SIZE                   = 32
    TRAILER_OFFSET_SIZE_OFFSET     =  6
    TRAILER_OBJECT_REF_SIZE_OFFSET =  7
    TRAILER_NUM_OBJECTS_OFFSET     =  8
    TRAILER_TOP_OBJECT_OFFSET      = 16
    TRAILER_OFFSET_TABLE_OFFSET    = 24

    @trailer_info : NamedTuple(
      offset_size: UInt8,
      object_ref_size: UInt8,
      num_objects: UInt64,
      top_object: UInt64,
      offset_table_offset: UInt64)

    @offsets : Array(UInt64)

    class_property? debug = false

    def initialize(@io : IO)
      buffer = Bytes.new(HEADER_SIZE)
      @io.read(buffer)

      raise Bplist::Error.new("Invalid format") unless buffer == "bplist00".to_slice

      # Read and parse the trailer
      @trailer_info = read_trailer
      p! @trailer_info if self.class.debug?

      # Read the offset table based on the trailer information and store it as an instance variable
      @offsets = read_offset_table

      p! @offsets if self.class.debug?
    end

    def self.new(file_path : String)
      file = File.open(file_path, "r")

      new(file)
    end

    def parse
      # Fetch the offset of the top object
      top_object_offset = @offsets[@trailer_info[:top_object].to_i]

      # Parse the top object
      parse_object_at_index(top_object_offset)
    end

    private def read_trailer
      @io.seek(-TRAILER_SIZE, IO::Seek::End)
      trailer = Bytes.new(TRAILER_SIZE)
      @io.read(trailer)

      offset_size = trailer[TRAILER_OFFSET_SIZE_OFFSET].to_u8
      object_ref_size = trailer[TRAILER_OBJECT_REF_SIZE_OFFSET].to_u8

      num_objects = UInt64.from_be_bytes(trailer[TRAILER_NUM_OBJECTS_OFFSET, 8])
      top_object = UInt64.from_be_bytes(trailer[TRAILER_TOP_OBJECT_OFFSET, 8])
      offset_table_offset = UInt64.from_be_bytes(trailer[TRAILER_OFFSET_TABLE_OFFSET, 8])

      {
        offset_size:         offset_size,
        object_ref_size:     object_ref_size,
        num_objects:         num_objects,
        top_object:          top_object,
        offset_table_offset: offset_table_offset,
      }
    end

    private def read_offset_table : Array(UInt64)
      @io.seek(@trailer_info[:offset_table_offset].to_i64)

      offsets = Array(UInt64).new(@trailer_info[:num_objects].to_i, 0_u64)
      buffer = Bytes.new(@trailer_info[:offset_size])

      @trailer_info[:num_objects].to_i.times do |i|
        @io.read(buffer)
        offsets[i] = big_endian_to_uint64(buffer, @trailer_info[:offset_size])
      end

      offsets
    end

    private def parse_object(type_byte : UInt8) : Bplist::Any
      value =
        case type_byte
        when 0x00 # null
          nil
        when 0x08 # bool (false)
          false
        when 0x09 # bool (true)
          true
        when 0x10..0x1F # int
          read_int(type_byte)
        when 0x22, 0x23 # real
          read_real(type_byte)
        when 0x33 # date
          read_date(type_byte)
        when 0x40..0x4F # data
          read_data(type_byte)
        when 0x50..0x5F # string (ASCII String)
          read_ascii_string(type_byte)
        when 0xA0..0xAF # array
          read_array(type_byte)
        when 0xD0..0xDF # dict
          read_dict(type_byte)
        else
          raise Bplist::Error.new("Can't parse object type `#{type_byte}`")
        end

      Bplist::Any.new(value)
    end

    private def read_int(type_byte : UInt8) : Int
      bytes, klass =
        case type_byte
        when 0x10
          {Bytes.new(1), Int8}
        when 0x11
          {Bytes.new(2), Int16}
        when 0x12
          {Bytes.new(4), Int32}
        when 0x13
          {Bytes.new(8), Int64}
        when 0x14
          {Bytes.new(16), Int128}
        else
          raise Bplist::Error.new("Invalid integer number type byte: `#{type_byte}`")
        end

      @io.read(bytes)
      klass.from_be_bytes(bytes)
    end

    private def read_real(type_byte : UInt8) : Float
      bytes, klass =
        case type_byte
        when 0x22
          {Bytes.new(4), Float32}
        when 0x23
          {Bytes.new(8), Float64}
        else
          raise Bplist::Error.new("Invalid real number type byte: `#{type_byte}`")
        end

      @io.read(bytes)
      klass.from_be_bytes(bytes)
    end

    private def read_date(type_byte : UInt8) : Time
      # Ensure the type byte indicates a date object
      raise Bplist::Error.new("Expected date type byte, got `#{type_byte}`") unless type_byte & 0xF0 == 0x30

      # Read the 8-byte floating-point number representing the date
      date_bytes = Bytes.new(8)
      @io.read(date_bytes)

      # Convert the bytes to a double (64-bit float) in big-endian format
      seconds_since_reference = Float64.from_be_bytes(date_bytes)

      # Cocoa reference date (1st January 2001)
      reference_date = Time.utc(2001, 1, 1, 0, 0, 0)

      # Add the seconds to the reference date
      reference_date + seconds_since_reference.seconds
    end

    private def read_data(type_byte : UInt8) : Bytes
      length = type_byte & 0x0F # Low nibble for length
      length = read_extended_length if length == 0x0F

      data_bytes = Bytes.new(length.to_i)
      @io.read(data_bytes)

      data_bytes
    end

    private def read_ascii_string(type_byte : UInt8) : String
      length = type_byte & 0x0F # Low nibble for length
      length = read_extended_length if length == 0x0F

      string_bytes = Bytes.new(length.to_i)
      @io.read(string_bytes)

      String.new(string_bytes)
    end

    private def read_array(type_byte : UInt8) : Array(Bplist::Any)
      count = type_byte & 0x0F # Low nibble for count
      count = read_extended_length if count == 0x0F

      ary = [] of Bplist::Any

      count.to_i.times do
        ref_bytes = Bytes.new(@trailer_info[:object_ref_size])
        @io.read(ref_bytes)

        ref_index = calculate_ref_index(ref_bytes)
        raise IndexError.new("Reference index out of bounds") if ref_index >= @offsets.size

        # Get the actual offset from the offsets array
        element_offset = @offsets[ref_index.to_i]

        # Save the current position
        current_position = @io.pos

        # Parse the object at the found offset
        element = parse_object_at_index(element_offset)
        ary << element

        # Reset the position to the next set of reference bytes
        @io.seek(current_position)
      end

      ary
    end

    private def read_dict(type_byte : UInt8) : Hash(String, Bplist::Any)
      count = type_byte & 0x0F # Low nibble for count
      count = read_extended_length if count == 0x0F

      hsh = {} of String => Bplist::Any

      key_refs = Array(UInt64).new(count.to_i, 0_u64)
      value_refs = Array(UInt64).new(count.to_i, 0_u64)

      # Read key references
      count.to_i.times do |i|
        key_ref_bytes = Bytes.new(@trailer_info[:object_ref_size])
        @io.read(key_ref_bytes)
        key_refs[i] = calculate_ref_index(key_ref_bytes)
      end

      # Read value references
      count.to_i.times do |i|
        value_ref_bytes = Bytes.new(@trailer_info[:object_ref_size])
        @io.read(value_ref_bytes)
        value_refs[i] = calculate_ref_index(value_ref_bytes)
      end

      # Parse keys and values
      count.to_i.times do |i|
        key_offset = @offsets[key_refs[i].to_i]
        value_offset = @offsets[value_refs[i].to_i]

        @io.seek(key_offset.to_i64)
        key_type_byte = Bytes.new(1)
        @io.read(key_type_byte)
        key = parse_object(key_type_byte[0]).as_s

        value = parse_object_at_index(value_offset)

        hsh[key] = value
      end

      hsh
    end

    private def parse_object_at_index(offset : UInt64) : Bplist::Any
      @io.seek(offset.to_i64)
      type_byte = Bytes.new(1)
      @io.read(type_byte)

      parse_object(type_byte[0])
    end

    private def calculate_ref_index(ref_bytes : Bytes) : UInt64
      ref_bytes.reduce(0_u64) do |ref_index, byte|
        (ref_index << 8) | byte.to_u64
      end
    end

    private def read_extended_length : UInt64
      # Read the next byte, which contains the marker for length.
      marker_byte = Bytes.new(1)
      @io.read(marker_byte)

      # Extract the lower 4 bits (nibble) which indicate the length.
      additional_length_bytes = (marker_byte[0] & 0x0F)

      # The actual length is encoded in the following bytes.
      # The number of these bytes is one more than the value in additional_length_bytes.
      length_bytes = Bytes.new(additional_length_bytes.to_i + 1)

      # Read the actual length bytes.
      @io.read(length_bytes)

      # Combine the length bytes to form the actual length.
      # The bytes are combined in a big-endian fashion: shifting each byte and OR-ing it to the total length.
      length_bytes.reduce(0_u64) do |length, byte|
        (length << 8) | byte.to_u64
      end
    end

    private def big_endian_to_uint64(bytes : Bytes, size : UInt8) : UInt64
      bytes.each_with_index.reduce(0_u64) do |total, (byte, index)|
        total | (byte.to_u64 << (8 * (size - 1 - index)))
      end
    end

    def print_objects
      @offsets.each_with_index do |offset, index|
        @io.seek(offset.to_i64)
        type_byte = Bytes.new(1)
        @io.read(type_byte)

        object = parse_object(type_byte[0])

        if object.raw.is_a?(Bplist::Any::ValueType)
          puts "Object #{index + 1} - #{object.raw.class}: `#{object.inspect}`"
        elsif object.raw.is_a?(Hash)
          puts "Object #{index + 1} - #{object.raw.class}: `#{object.as_h.keys}`"
        else
          puts "Object #{index + 1} - #{object.raw.class}:"
        end
      end
    end
  end
end
