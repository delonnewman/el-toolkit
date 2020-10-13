# frozen_string_literal: true
require 'set'
require 'stringio'
require 'parser/current'
require 'unparser'
require 'erb'
require 'json'
require 'date'
require 'rack'

require_relative 'el/utils'
require_relative 'el/base'
require_relative 'el/action'
require_relative 'el/javascript'
require_relative 'el/html'
require_relative 'el/view'
require_relative 'el/page'
require_relative 'el/html_page'
require_relative 'el/json_page'
require_relative 'el/application'

module El
  ACTIONS = {}

  def self.call_action(id, params = {})
    action = ACTIONS[id]
    raise "Action #{id} not found: #{ACTIONS}" unless action

    result = if params['result'] && action.proc.arity == 1
              action.call(params['result'])
            else
              action.call
            end

    if Action === result
      register_action(result)
      if result.respond_to?(:to_js)
        [200, { 'Content-Type' => 'application/json' }, [{ status: 'success', action_id: result.id, js: result.to_js }.to_json]]
      else
        [200, { 'Content-Type' => 'application/json' }, [{ status: 'success', action_id: result.id }.to_json]]
      end
    elsif result.respond_to?(:to_js)
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