require "../spec_helper"

private def run_debug_code(code : String) : String
  result = Process.capture_result(
    ["crystal", "eval", code],
    env: {"DEBUG" => "1"},
    chdir: "#{__DIR__}/../.."
  )

  result.status.success?.should be_true, result.error
  result.output + result.error
end

describe "debug output" do
  it "does not print from writer when debug is disabled" do
    output = run_debug_code(<<-CRYSTAL)
      require "./src/bplist"

      Debug.enabled = true
      Bplist::Writer.debug = false
      Bplist::Writer.new({"value" => 42})
      CRYSTAL

    output.should eq("")
  end

  it "prints from writer when debug is enabled" do
    output = run_debug_code(<<-CRYSTAL)
      require "./src/bplist"

      Debug.enabled = true
      Bplist::Writer.debug = true
      Bplist::Writer.new({"value" => 42})
      CRYSTAL

    output.should contain("src/bplist/helpers.cr")
    output.should contain("object")
  end

  it "prints from parser when debug is enabled" do
    output = run_debug_code(<<-CRYSTAL)
      require "./src/bplist"

      writer = Bplist::Writer.new({"value" => 42})

      Debug.enabled = true
      Bplist::Parser.debug = true
      Bplist::Parser.parse(writer.io.to_slice)
      CRYSTAL

    output.should contain("src/bplist/helpers.cr")
    output.should contain("offset_size")
  end
end
