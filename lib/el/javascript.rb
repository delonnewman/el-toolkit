# frozen_string_literal: true
module El
  module JavaScript
    extend Forwardable

    def_delegators :window, :alert, :confirm, :document

    def window
      Window.instance
    end

    module Utils
      # TODO: add more data types to serialize
      def to_javascript(value)
        if value.respond_to?(:to_js)
          value.to_js
        else
          case value
          when Date, Time, DateTime
            "new Date(#{value.to_time.to_i})"
          else
            value.to_json
          end
        end
      end

      module_function :to_javascript
    end

    class JSAction < Action
      def initialize(js, proc)
        super(proc)
        @js = js
        El.register_action(self)
      end

      def to_js
        "el.actions.call(#{id}, null, #{@js.to_js})"
      end
    end

    class Base
      # add server side actions to 
      def then(proc)
        JSAction.new(self, proc)
      end
    end

    module Chainable
      def method_missing(method, *args)
        method_    = method.to_s
        assignment = false

        if method_.end_with?('!')
          assignment = true
          method = method_.slice(0, method_.size - 1).to_sym
        end

        prop = PropertyAccess.new(self, Ident[method])

        if assignment
          raise 'An argument is require for assignment' if args.size < 1
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

      private

      def evaluate_method(method, args)
        method_ = method.to_s
        if method_.end_with?('!')
          Assignment.new()
        end
      end
    end

    class Proxy < Base
      include Chainable

      def initialize(expression)
        @expression = expression
      end

      def to_js
        Utils.to_javascript(@expression)
      end
    end

    class Document < Base
      include Singleton
      include Chainable

      def to_js
        'window.document'
      end
    end

    class Window < Base
      include Singleton
      include Chainable

      def document
        Document.instance
      end

      def alert(message)
        FunctionCall.new(Ident[:alert], [message])
      end

      def confirm(message)
        FunctionCall.new(Ident[:confirm], [message])
      end

      def prompt(*args)
        FunctionCall.new(Ident[:prompt], args)
      end

      def to_js
        'window'
      end
    end

    class Ident < Base
      def self.[](symbol)
        @cache ||= {}
        @cache[symbol.to_sym] ||= new(symbol)
      end

      def initialize(symbol)
        @symbol = symbol.to_sym
        @name   = symbol.to_s
      end

      def to_js
        @name
      end
    end

    class Assignment < Base
      def initialize(expression, value)
        @expression = expression
        @value = value
      end

      def to_js
        "#{Utils.to_javascript(@expression)} = #{Utils.to_javascript(@value)}"
      end
    end

    class PropertyAccess < Base
      attr_reader :object, :name

      def initialize(object, name)
        @object = object
        @name   = name
      end

      def to_js
        "#{Utils.to_javascript(object)}.#{Utils.to_javascript(name)}"
      end
    end

    class Return
      attr_reader :expression

      def initialize(expression)
        @expression = expression
      end

      def to_js
        "return #{Utils.to_javascript(expression)}"
      end
    end

    class FunctionCall
      attr_reader :function, :arguments

      def initialize(function, arguments)
        @function  = function
        @arguments = arguments
      end

      def to_js
        "#{Utils.to_javascript(function)}(#{arguments.map(&Utils.method(:to_javascript)).join(', ')})"
      end
    end
  end
end