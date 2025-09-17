require "bytes_ext"
require "./bplist/*"

module Bplist
  VERSION = {{ `shards version #{__DIR__}`.chomp.stringify }}

  # Generic Bplist error.
  class Error < Exception
  end

  def self.parse(input)
    Parser.new(input).parse
  end
end
