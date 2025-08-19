module Bplist
  module Helpers
    extend self

    def debug_print(object)
      p! object if self.class.debug?
    end
  end
end
