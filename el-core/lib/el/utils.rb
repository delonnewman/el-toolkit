module El
  module Utils
    def self.hash_combine(seed, hash)
      # a la boost, a la clojure
      seed ^= hash + 0x9e3779b9 + (seed << 6) + (seed >> 2)
      seed
    end
  end
end
