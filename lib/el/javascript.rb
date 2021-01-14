require 'singleton'
require 'date'
require 'json'

require_relative 'javascript/utils'
require_relative 'javascript/base'
require_relative 'javascript/action'
require_relative 'javascript/assignment'
require_relative 'javascript/chainable'
require_relative 'javascript/proxy'
require_relative 'javascript/ident'
require_relative 'javascript/property_access'
require_relative 'javascript/function_call'
require_relative 'javascript/return'
require_relative 'javascript/window'
require_relative 'javascript/document'

module El
  class JavaScript
    extend Forwardable

    def_delegators :window, :alert, :confirm, :prompt, :document

    def window
      @window ||= JavaScript::Window.new
    end
  end
end
