# frozen_string_literal: true

class Hash
  if RUBY_VERSION.to_f < 3
    def except(*keys)
      h = dup
      keys.each do |key|
        h.delete(key)
      end
      h
    end
  end

  def deep_merge(other_hash, &block)
    dup.deep_merge!(other_hash, &block)
  end

  def deep_merge!(other_hash, &block)
    merge!(other_hash) do |key, this_val, other_val|
      if this_val.is_a?(Hash) && other_val.is_a?(Hash)
        this_val.deep_merge(other_val, &block)
      elsif block_given?
        block.call(key, this_val, other_val)
      else
        other_val
      end
    end
  end
end
