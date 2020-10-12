# frozen_string_literal: true
require 'set'
require 'stringio'
require 'parser/current'
require 'unparser'
require 'erb'

require_relative 'el/action'
require_relative 'el/html'
require_relative 'el/view'
require_relative 'el/page'
require_relative 'el/application'

module El
  ACTIONS = {}

  def self.call_action(id, params = {})
    action = ACTIONS[id]
    if action
      action.call
    else
      raise "Action #{id} not found: #{ACTIONS}"
    end
  end

  def self.register_action(action)
    ACTIONS[action.id] = action
  end
end