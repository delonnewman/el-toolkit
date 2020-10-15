require 'singleton'
require 'date'
require 'json'

require_relative 'action'
require_relative 'scriptable'

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
  module JavaScript
    extend El::Scriptable
  end
end