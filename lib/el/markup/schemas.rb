module El
  class Markup
    module Schemas
      HTML5 = {
        xml: false,
        content_elements: Set[
          :div, :p, :a, :script, :table, :tr, :td, :th, :strong, :li, :ul, :ol,
          :h1, :h2, :h3, :h4, :h5, :h6, :span, :nav, :main, :header, :button,
          :form, :code, :pre, :textarea, :submit, :select, :option, :thead, :tbody
        ].freeze,
        singleton_elements: Set[
          :br, :img, :link, :meta, :base, :area, :col, :hr, :input,
          :param, :source, :track, :wbr, :keygen
        ].freeze,
      }.freeze  
    end
  end
end