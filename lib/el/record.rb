require 'hash_delegator'

module El
  class Record < HashDelegator
    transform_keys(&:to_sym)

    class << self
      def [](attributes)
        new(attributes)
      end
    end
  end
end
