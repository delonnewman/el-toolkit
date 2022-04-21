module El
  module Validators
    class Base
      extend Forwardable

      def_delegators :options, :key?
      def_delegators 'self.class', :rules, :default_message

      class << self
        def rules
          @rules ||= {}
        end

        def rule(name, &block)
          rules[name] = block
        end

        def default_message(message = nil)
          return @default_message if @default_message

          @default_message = message
        end
      end

      attr_reader :options

      def initialize(options)
        @options = options
      end

      def message
        options[:message] || default_message
      end

      def call(value)
        rules.each_key do |key|
          return message unless key?(method) && rules[key].call(option[key], value)
        end
      end
    end
  end
end
