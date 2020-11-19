# frozen_string_literal: true
module El
  class Fragment
    class Base < Fragment
      include Markup::Elemental

      attr_reader :options

      def html
        @html ||= Markup[:HTML]
      end

      def initialize(options, value = nil)
        @options = options
        @value   = value if value
      end

      def with_value(value)
        self.class.new(@options, value)
      end
    end

    class Button < Base; end
    class ButtonGroup < Base; end
    class Link < Base; end
    class Text < Base; end
    class Grid < Base; end
    class TextField < Base; end
    class LongTextField < Base; end
    class SelectField < Base; end
    class Toggle < Base; end
    class CheckBoxes < Base; end
    class RadioButtons < Base; end

    class Form < Base
      class << self
        def fields
          @fields ||= {}
        end

        def text(name, opts = {})
          fields[name] = TextField.new(opts)
        end

        def textarea(name, opts = {})
          fields[name] = LongTextField.new(opts)
        end

        def select(name, opts = {})
          fields[name] = SelectField.new(opts)
        end

        def attributes
          @attributes ||= []
        end

        def url(value = nil)
          @url ||= value
        end

        def method(value = nil)
          @method ||= value
        end
      end

      attr_reader :fields

      def initialize(attributes = EMPTY_HASH)
        @url    = attributes.fetch(:url) { self.class.url }
        @method = attributes.fetch(:url) { self.class.method }

        @fields = self.class.fields.reduce({}) do |h, (name, field)|
          if attributes.key?(name)
            h.merge!(name => field.with_value(attributes[name]))
          else
            h.merge!(name => field)
          end
        end
      end

      private

      EMPTY_HASH = {}.freeze
    end
  end
end

class ContactForm < El::Fragment::Form
  url '/contact'
  method :post

  text :name
  text :email

  select :intrests, blank: 'Please Select One', reading: 'Reading', hiking: 'Hiking', biking: 'Biking'  
  textarea :comments
end