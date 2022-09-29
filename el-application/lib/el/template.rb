# frozen_string_literal: true

require 'forwardable'

module El
  class Template
    extend Forwardable
    def_delegators :@templated, :app

    attr_reader :path

    def initialize(templated, path)
      @templated = templated
      @path      = path
    end

    def code
      return @code if app.settings[:template_caching] && @code

      @code = Erubi::Engine.new(path.read).src
    end

    def eval(binding)
      binding.eval(code, path.to_s)
    end
  end
end
