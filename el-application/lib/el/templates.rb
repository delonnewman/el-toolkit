# frozen_string_literal: true

require 'pathname'
require_relative 'template'

module El
  class Templates < Advice
    advises :templated, delegating: %i[app layout module_name]

    include Memoize

    def initialize(templated)
      super(templated)
      Memoize.init_memoize_state!(self)

      freeze
    end

    memoize def template(name)
      Template.new(templated, template_path(name))
    end

    memoize def layout_template(name)
      Template.new(templated, layout_path(name))
    end

    def render_template(name, view)
      template(name)&.call(view)
    end

    def template_path(name)
      return Pathname.new(name) if !name.is_a?(Symbol) && File.exist?(name)

      app.app_path.join(module_name, 'templates', "#{name}.html.erb")
    end

    def layout_path(name)
      return Pathname.new(name) if !name.is_a?(Symbol) && File.exist?(name)

      app.app_path.join('layouts', "#{name}.html.erb")
    end
  end
end
