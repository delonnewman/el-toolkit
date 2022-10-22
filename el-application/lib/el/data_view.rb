require_relative 'page_view'

module El
  # An anonymous view based on hash data
  class DataView < PageView
    attr_reader :template_name

    def initialize(controller, name, data, options)
      super(controller, options)

      @template_name = name
      @__data__      = data

      data.each_pair do |key, value|
        define_singleton_method(key) { value }
      end
    end

    def respond_to_missing?(method, include_all)
      super(method, include_all) || controller.respond_to_missing?(method, include_all)
    end

    def method_missing(method, *args, **kwargs, &block)
      controller.public_send(method, *args, **kwargs, &block)
    end

    def to_h
      @__data__.dup
    end

    def to_json(*args)
      @__data__.to_json(*args)
    end

    def view
      @__data__
    end
  end
end
