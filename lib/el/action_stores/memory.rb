module El
  module ActionStores
    class Memory
      def initialize
        @actions = {}
      end

      def set(action)
        @actions[action.id] = action
      end

      def get(id)
        @actions[id]
      end

      def list
        @actions.values
      end
    end
  end
end