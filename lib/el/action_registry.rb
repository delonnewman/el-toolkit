require_relative 'action_stores/memory'

module El
  class ActionRegistry
    def initialize(store = ActionStores::Memory.new)
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
  end
end