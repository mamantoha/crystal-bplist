require "bytes_ext"
require "./bplist/*"

module Bplist
  VERSION = "0.1.0"

  # Generic Bplist error.
  class Error < Exception
  end

  def self.parse(input)
    Parser.new(input).parse
  end
end
