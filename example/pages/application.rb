module Examples
  module Pages
    class Application < El::HTMLPage
      abstract!
      stylesheets "/css/bootstrap.min.css"
    end
  end
end