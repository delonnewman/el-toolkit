# frozen_string_literal: true

require 'forwardable'
require 'el/pluggable'

module El
  class View
    extend Pluggable
    extend Forwardable

    attr_reader :controller, :options

    def_delegators :controller, :app, :request, :module_name
    def_delegators :request, :url_for, :params, :options, :session
    def_delegators :app, :routes

    def initialize(controller, options)
      @controller = controller
      @options    = options
    end

    def render
      raise NotImplementedError, "#{self.class}##{__method__} has not been implemented"
    end
  end
end
