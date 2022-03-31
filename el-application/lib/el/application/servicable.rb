module El
  module Application
    module Servicable
      def app
        raise 'An app method must be defined'
      end

      def load!
        raise 'A load! method must be defined'
      end

      def loaded?
        @loaded
      end

      protected

      def loaded!
        @loaded = true
      end
    end
  end
end
