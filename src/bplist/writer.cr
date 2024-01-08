module Bplist
  class Writer
    @offset_table_offset_size : Int32
    @object_ref_size : Int32

    getter io : IO::Memory

    class_property? debug = false

    # Initialize with a hash
    def initialize(hash : Hash, @compress = false)
      @io = IO::Memory.new

      # Write header
      @io.write("bplist00".to_slice)

      @offsets = [] of Int64
      @object_lookup = {} of Bplist::Any => Int32

      @indexed_list = [] of Bplist::Any
      @linked_elements = Hash(Int32, Array(Int32)).new { |hsh, k| hsh[k] = [] of Int32 }

      index = parent_index = 0

      traverse(hash, index, parent_index)

      # Size of object references in serialized containers
      # depends on the number of objects in the plist.
      @object_ref_size = count_to_size(@offsets.size)
      p! @object_ref_size if self.class.debug?

      @indexed_list.each_with_index do |element, i|
        serialize_element(element.as(Bplist::Any), i)
      end

      p! @offsets if self.class.debug?

      @offset_table_offset_size = count_to_size(@offsets.max)
      p! @offset_table_offset_size if self.class.debug?

      @offset_table_start = @io.pos

      @offsets.each do |offset|
        write_offset(@io, offset, @offset_table_offset_size)
      end

      write_trailer
    end

    private def traverse(element, index : Int32, parent_index : Int32) : Int32
      element = element.raw if element.is_a?(Bplist::Any)

      object = Bplist::Any.convert(element)

      case element
      when Hash
        @linked_elements[parent_index] << index unless parent_index == index

        @indexed_list << object

        parent_index = index

        index += 1

        # Handle all keys in the hash
        element.each_key do |key|
          object = Bplist::Any.convert(key)

          if @compress && (idx = @object_lookup[object]?)
            @linked_elements[parent_index] << idx
          else
            @object_lookup[object] = index

            @linked_elements[parent_index] << index

            @indexed_list << object

            index += 1
          end
        end

        # Handle all values in the hash
        element.each_value do |value|
          index = traverse(value, index, parent_index)
        end
      when Array
        @linked_elements[parent_index] << index

        @indexed_list << object

        parent_index = index

        index += 1

        # Handle each element in the array
        element.each do |elem|
          index = traverse(elem, index, parent_index)
        end
      else
        if @compress && (idx = @object_lookup[object]?)
          @linked_elements[parent_index] << idx
        else
          @object_lookup[object] = index

          @linked_elements[parent_index] << index

          @indexed_list << object

          index += 1
        end
      end

      index
    end

    private def serialize_element(element : Bplist::Any, index)
      @offsets << @io.pos

      object = element.raw

      case object
      when Nil
        serialize_nil(object)
      when Bool
        serialize_bool(object)
      when Int
        serialize_int(object)
      when Float
        serialize_float(object)
      when Time
        serialize_time(object)
      when Slice(UInt8)
        serialize_data(object)
      when String
        serialize_string(object)
      when Array
        serialize_array(object, index)
      when Hash
        serialize_hash(object, index)
      else
        raise Bplist::Error.new("Unsupported object type: #{object.class}")
      end
    end

    def write_to_file(file_path : String)
      File.open(file_path, "wb") do |file|
        file.write(@io.to_slice)
      end
    end

    private def serialize_nil(_nil : Nil)
      type_marker = 0x00.to_u8

      @io.write_byte(type_marker)
    end

    private def serialize_bool(bool : Bool)
      type_marker =
        case bool
        in true  then 0x09.to_u8
        in false then 0x08.to_u8
        end

      @io.write_byte(type_marker)
    end

    private def serialize_int(value : Int)
      type_marker, int =
        case value
        when Int8::MIN..Int8::MAX
          {0x10.to_u8, value.to_i8}
        when Int16::MIN..Int16::MAX
          {0x11.to_u8, value.to_i16}
        when Int32::MIN..Int32::MAX
          {0x12.to_u8, value.to_i32}
        when Int64::MIN..Int64::MAX
          {0x13.to_u8, value.to_i64}
        when Int128::MIN..Int128::MAX
          {0x14.to_u8, value.to_i128}
        else
          raise Bplist::Error.new("Integer size not supported")
        end

      @io.write_byte(type_marker)
      @io.write(int.to_be_bytes)
    end

    private def serialize_float(value : Float)
      type_marker =
        case value
        in Float32 then 0x22.to_u8
        in Float64 then 0x23.to_u8
        end

      @io.write_byte(type_marker)
      @io.write(value.to_be_bytes)
    end

    private def serialize_time(time : Time)
      type_marker = 0x33 # Standard type marker for date/time in binary plist

      # Convert the time to the number of seconds since the reference date
      reference_date = Time.utc(2001, 1, 1, 0, 0, 0)
      time_interval = (time.to_utc.to_unix - reference_date.to_unix).to_f64

      @io.write_byte(type_marker.to_u8)
      @io.write(time_interval.to_be_bytes)
    end

    private def serialize_data(data : Slice(UInt8))
      # Define base type marker for short data and marker for extended data length
      base_type_marker = 0x40 # Marker for short data
      long_data_marker = 0x4F # Marker for long data

      data_length = data.size

      if data_length < 15
        # For data with up to 15 bytes, encode the length in the type marker
        type_marker = (base_type_marker + data_length).to_u8
        @io.write_byte(type_marker)
      else
        # For longer data, use the long data marker and encode length separately
        @io.write_byte(long_data_marker.to_u8)

        # Write the length of the data
        length_bytes = calculate_length_bytes(data_length)
        @io.write(length_bytes)
      end

      # Write the actual data
      @io.write(data)
    end

    private def serialize_string(str : String)
      base_type_marker = 0x50   # Marker for short strings
      long_string_marker = 0x5F # Marker for long strings

      str_length = str.bytesize

      if str_length < 15
        # For short strings, encode the length in the type marker
        type_marker = (base_type_marker + str_length).to_u8
        @io.write_byte(type_marker)
      else
        # For longer strings, use the long string marker and encode length separately
        @io.write_byte(long_string_marker.to_u8)

        # Write the length of the string
        length_bytes = calculate_length_bytes(str_length)
        @io.write(length_bytes)
      end

      # Write the string data
      @io.write(str.to_slice)
    end

    private def serialize_array(array : Array, index)
      # Base type marker for a short array is 0xA0
      base_type_marker = 0xA0

      # Separate type marker for a long array
      long_array_marker = 0xAF

      array_size = array.size

      if array_size < 0x0F
        # For arrays with up to 15 elements, encode the count in the type marker
        type_marker = (base_type_marker + array_size).to_u8
        @io.write_byte(type_marker)
      else
        # For longer arrays, use a specific marker and encode the count separately
        type_marker = long_array_marker.to_u8
        @io.write_byte(type_marker)

        # Write the count of the array
        count_bytes = calculate_length_bytes(array_size)
        @io.write(count_bytes)
      end

      @linked_elements[index].each do |offset|
        write_offset(@io, offset, @object_ref_size)
      end
    end

    private def serialize_hash(hash : Hash, index)
      # Base type marker for a short dict is 0xD0
      base_type_marker = 0xD0

      # Separate type marker for a long dict
      long_dict_marker = 0xDF

      # Calculate the count of key-value pairs in the hash
      pair_count = hash.size

      if pair_count < 0x0F
        # For dictionaries with up to 15 key-value pairs, encode the count in the type marker
        type_marker = (base_type_marker + pair_count).to_u8
        @io.write_byte(type_marker)
      else
        # For longer dictionaries, use a specific marker and encode the count separately
        type_marker = long_dict_marker.to_u8
        @io.write_byte(type_marker)

        # Write the count of the dict
        count_bytes = calculate_length_bytes(pair_count)
        @io.write(count_bytes)
      end

      # Write the indices of each key and value in the hash
      @linked_elements[index].each do |offset|
        write_offset(@io, offset, @object_ref_size)
      end
    end

    private def calculate_length_bytes(length : Int32) : Bytes
      if length <= 0xFF
        Bytes[0x10, length.to_u8]
      elsif length <= 0xFFFF
        Bytes[0x10, (length >> 8).to_u8, (length & 0xFF).to_u8]
      else
        raise Bplist::Error.new("length too long to encode")
      end
    end

    # Helper method to calculate the number of bytes needed for the maximum offset
    private def count_to_size(count)
      case count
      when 0..0xFF_u64                 then 1
      when 0x100_u64..0xFFFF_u64       then 2
      when 0x10000_u64..0xFFFFFFFF_u64 then 4
      else                                  8
      end
    end

    private def write_trailer
      # Bytes 0-5: Unused and sort version
      @io.write(Bytes.new(6, 0_u8)) # Fill with zeros

      # Byte 6: Offset table offset size (assuming 64-bit offsets)
      @io.write_byte(@offset_table_offset_size.to_u8)

      # Byte 7: Object reference size (assuming 64-bit references)
      @io.write_byte(@object_ref_size.to_u8)

      # Bytes 8-15: Number of objects
      @io.write(@offsets.size.to_u64.to_be_bytes)

      # Bytes 16-23: Top object offset (usually zero)
      @io.write(0_u64.to_be_bytes)

      # Bytes 24-31: Offset table start
      @io.write(@offset_table_start.to_u64.to_be_bytes)
    end

    # Helper method to write the offset with the correct byte size
    private def write_offset(io : IO, offset : Int, size : Int32)
      offset =
        case size
        when 1 then offset.to_u8
        when 2 then offset.to_u16
        when 4 then offset.to_u32
        when 8 then offset.to_u64
        else
          raise Bplist::Error.new("Unsupported offset size `#{size}`")
        end

      io.write(offset.to_be_bytes)
    end

    def print_objects
      @indexed_list.each_with_index do |element, i|
        if element.raw.is_a?(Bplist::Any::ValueType)
          puts "Object #{i + 1} - #{element.raw.class}: `#{element.inspect}`"
        elsif element.raw.is_a?(Hash)
          puts "Object #{i + 1} - #{element.raw.class}: `#{element.as_h.keys}`"
        else
          puts "Object #{i + 1} - #{element.raw.class}"
        end
      end
    end
  end
end
