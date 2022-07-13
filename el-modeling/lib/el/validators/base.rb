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

        def message(msg = nil, &block)
          @rule_message = msg || block
        end

        def rule(name, &block)
          if @rule_message
            msg = @rule_message
            @rule_message = nil
          else
            msg = default_message
          end

          rules[name] = {
            msg:  msg,
            rule: block
          }

          name
        end

        # TODO: add some validation
        def option(name)
          define_method name do
            options.fetch(name) do
              raise "`#{name}` was not provided as an option"
            end
          end
        end

        def default_message(message = nil)
          return @default_message if @default_message

          @default_message = message || 'is not valid'
        end
      end

      attr_reader :options

      def initialize(options)
        @options = options
      end

      def field
        options.fetch(:field) do
          raise '`field` was not provided as an option'
        end
      end

      def rule_data(name)
        rules.fetch(name) do
          raise "`#{name}` is not a valid rule for #{inspect}:#{self.class}"
        end
      end

      def rule(name)
        rule_data(name)[:rule]
      end

      def message(name, value)
        msg = option[:message] || rule_data(name)[:msg]
        msg = msg.call(value) if msg.respond_to?(:call)

        interpolate_message(name, msg)
      end

      TEMPLATE_PATTERN = /${\w+}/.freeze

      def interpolate_message(name, msg)
        msg.gsub(TEMPLATE_PATTERN, options[name].to_s)
      end

      def pass_rule?(name, value)
        options.key?(name) && rule(name).call(options[name], value)
      end

      def call(value)
        errors = {}

        rules.each_key do |key|
          unless value.key?(field) && pass_rule?(key, value[field])
            errors[field] = message(key, value[field])
          end
        end

        errors
      end
    end
  end
end
