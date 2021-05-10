module Ext; end

module Ext::Hash
  refine Hash do
    # Dig to the given key and field using the value as the value for key
    def dig_and_replace key, field
      return unless self[key]

      self[key] = self[key][field]
    end

    # Same as `dig_and_replace` only assumes list of items
    def dig_and_replace_all key, field
      return unless self[key]

      self[key] = self[key].collect { _1[field] }
    end
  end
end
