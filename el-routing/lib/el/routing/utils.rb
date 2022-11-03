module El
  module Routing
    module Utils
      module_function

      def controller_action?(action)
        action.is_a?(Array) && action[0].is_a?(Class) && action[1].is_a?(Symbol)
      end

      def call_controller_action(action, request, context = nil)
        action[0].call(context, request).call(action[1])
      end
    end
  end
end