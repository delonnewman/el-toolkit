module El
  module Memoize
    def self.included(base)
      base.extend(ClassMethods)
    end

    def self.init_memoize_state!(obj)
      obj.instance_variable_set(:@__memos__, {}) unless obj.instance_variable_get(:@__memos__)
      obj
    end

    module ClassMethods
      def memoize(method_name)
        alias_method :"#{method_name}_unmemoized", method_name
        define_method method_name do |*args|
          @__memos__ ||= {}
          @__memos__[method_name] ||= {}
          @__memos__[method_name][args.hash] ||= send(:"#{method_name}_unmemoized", *args)
        end
      end
    end
  end
end
