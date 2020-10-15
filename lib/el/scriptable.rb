# frozen_string_literal: true
module El
  module Scriptable
    extend Forwardable

    def_delegators :window, :alert, :confirm, :prompt, :document

    def window
      JavaScript::Window.instance
    end
  end
end

require_relative 'javascript'