# frozen_string_literal: true
module El
  class View < Base
    include JavaScript
    include HTMLHelpers
    include Elemental

    extend Forwardable
    def_delegators :page, :view, :app

    class << self
      def symbol
        name.to_sym
      end

      def name
        @name ||= to_s.split('::').last.downcase
      end

      def is?(name)
        symbol == name.to_sym
      end
    end

    attr_reader :id, :page

    def initialize(page)
      @page = page
      @id   = object_id
    end

    def fragments
      @fragments ||= {}
    end

    def define(name, value = nil, &block)
      fragments[name] = Fragment.new(self, value, block)
    end

    def get(name, &block)
      f = fragments.fetch(name)
      if block
        f.get(block)
      else
        f
      end
    end

    def update(name, &block)
      fragments.fetch(name).update(block)
    end

    def reset!(name, value)
      fragments.fetch(name).reset!(value)
    end

    def action(&block)
      Action.new(block).tap do |action|
        app.action_registry.register(action)
      end
    end

    def symbol
      self.class.symbol
    end
    alias to_sym symbol

    def name
      symbol.to_s
    end

    def content
      value = render

      if value.respond_to?(:to_html)
        value.to_html
      elsif value.respond_to?(:each)
        buffer = StringIO.new
        value.each do |element|
          if element.respond_to?(:to_html)
            buffer.puts element.to_html
          else
            buffer.puts element.to_s
          end
        end
        buffer.string
      else
        value.to_s
      end
    end
    alias to_html content
  end
end