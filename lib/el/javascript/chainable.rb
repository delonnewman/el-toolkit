module El
  class JavaScript
    module Chainable
      def method_missing(method, *args)
        method_    = method.to_s
        assignment = false

        if method_.end_with?('!')
          assignment = true
          method = method_.slice(0, method_.size - 1).to_sym
        end

        if method === :[]
          raise 'An argument is required for assignment' if args.size < 1
          return Proxy.new(UninternedPropertyAccess.new(self, args[0]))
        end

        prop = PropertyAccess.new(self, Ident[method])

        if assignment
          raise 'An argument is required for assignment' if args.size < 1
          Proxy.new(Assignment.new(prop, args[0]))
        elsif args.empty?
          Proxy.new(prop)
        else
          Proxy.new(FunctionCall.new(prop, args))
        end
      end

      def respond_to?(_)
        true
      end
    end
  end
end
