# frozen_string_literal: true

require_relative "null"

module El
  class Base
    def self.inherited(klass)
      super
      klass.extend(CommonMethods)
      klass.include(CommonMethods)
    end
    
    module CommonMethods
      def null
        Null
      end
    end
  end
end
