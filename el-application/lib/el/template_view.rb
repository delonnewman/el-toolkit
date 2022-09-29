# frozen_string_literal: true

require 'el/memoize'
require 'el/string_utils'
require_relative 'templates'
require_relative 'template_helpers'

module El
  # A view that has an associated template
  class TemplateView < View
    include Memoize
    include TemplateHelpers

    def initialize(controller, options)
      super(controller, options)

      Memoize.init_memoize_state!(self)
    end

    def template_name
      StringUtils.underscore(self.class.name.split('::').last.sub(/View$/, '')).to_sym
    end

    memoize def templates
      Templates.new(self)
    end

    def render
      templates.template(template_name).eval(binding)
    end
  end
end
