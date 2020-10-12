# frozen_string_literal: true
require 'set'
require 'stringio'
require 'parser/current'
require 'unparser'
require 'erb'
require 'json'
require 'date'

require_relative 'el/action'
require_relative 'el/javascript'
require_relative 'el/html'
require_relative 'el/view'
require_relative 'el/page'
require_relative 'el/application'

module El
  ACTIONS = {}

  def self.call_action(id, params = {})
    action = ACTIONS[id]
    raise "Action #{id} not found: #{ACTIONS}" unless action

    result = action.call

    if result.respond_to?(:to_js)
      [200, { 'Content-Type' => 'application/javascript' }, [result.to_js]]
    elsif result.respond_to?(:to_html)
      [200, { 'Content-Type' => 'text/html' }, [result.to_html]]
    else
      [200, { 'Content-Type' => 'text/html' }, [result.to_s]]
    end
  end

  def self.register_action(action)
    ACTIONS[action.id] = action
  end
end