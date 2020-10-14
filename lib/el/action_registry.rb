module El
  class ActionRegistry
    def initialize(store = InMemory.new)
      @store = store
    end

    def register(action)
      @store.set(action)
    end

    def find(id)
      @store.get(id)
    end

    def actions
      @store.list
    end

    class InMemory
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