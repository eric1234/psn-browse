module Ext; end

module Ext::String
  refine String do
    # Like String#strip only also includes other whitespace such as non-breaking
    # space.
    def strip_all
      sub(/\A[[:space:]]/, '').sub(/[[:space:]]\z/, '')
    end

    # String is either a single uppercase letter or the string literal 0-9
    def alpha_header?
      self =~ /\A(?:[A-Z]|0-9)\z/
    end
  end
end
