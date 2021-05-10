module Ext; end

module Ext::Integer
  refine Integer do
    # Assumes value is # of secs since epoch
    def to_time
      Time.at(self).strftime '%F'
    end
  end
end
