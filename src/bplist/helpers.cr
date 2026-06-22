module Bplist
  module Helpers
    extend self

    def debug_print(object)
      debug!(object) if self.class.debug?
    end
  end
end
