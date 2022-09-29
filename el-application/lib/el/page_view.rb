require_relative 'template_view'

module El
  # A view that represents an entire page so may include a layout
  #
  # @example
  #   class HomePageView < El::PageView
  #     def greeting
  #       'Hello'
  #     end
  #   end
  #
  #   class HomeController < El::Controller
  #     layout :home # can specify layout here
  #
  #     # can disable layout in all page views rendered for this controller with nil or false
  #     layout nil
  #
  #     def index
  #       render HomePageView, layout: :index # can override layout here
  #     end
  #   end
  class PageView < TemplateView
    def render
      return super() unless layout

      render_layout { super() }
    end

    def layout
      options.fetch(:layout, controller.layout)
    end

    private

    def render_layout
      eval(templates.layout_template(layout).code)
    end
  end
end
