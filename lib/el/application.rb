module El
  class Application
    class << self
      def load_components(path)
        expanded = File.expand_path(path)
        symbols = Dir["#{expanded}/*.rb"].entries.map do |path|
          const = File.basename(path, '.rb').split('_').map(&:capitalize).join('').to_sym
          path  = File.expand_path(path)
          
          Object.autoload const, path
          const
        end

        symbols.map do |const|
          Object.const_get(const)
        end
      end


      def load
        pages = load_components('./pages')
        views = load_components('./views')        

        app = new(pages, views)
        yield app if block_given?
        app
      end
    end

    def initialize(pages, views)
      @views = views.reduce({}) do |h, view|
        view = view.new(self)
        h.merge!(view.name.to_sym => view)
      end

      @page_paths = {}
      @page_names = {}
      @middleware = {}

      pages.each do |page|
        next if page.abstract?
        page.new(self).tap do |page|
          @page_paths[page.path] = page
          @page_names[page.name.to_sym] = page
        end
      end
    end

    def use(klass, *args)
      @middleware[klass] = args unless @middleware.key?(klass)

      self
    end

    # compose middleware and return resulting rack app
    def app
      app = @middleware.reduce(self) do |app, (klass, args)|
        klass.new(app, *args)
      end
    end

    def view(name)
      @views[name.to_sym]
    end

    def views
      @views.values
    end

    def page(name)
      @page_names[name.to_sym]
    end

    def pages
      @page_names.values
    end

    def call(env)
      path = env['REQUEST_PATH']
      
      if path.start_with?('/action')
        El.call_action(path.split('/').last)
      else
        render_page(path)
      end
    end

    def render_page(path)
      page = @page_paths[path]

      if page
        [200, { 'Content-Type' => 'text/html' }, [page.render_content]]
      else
        [404, { 'Content-Type' => 'text/html' }, ["<h1>Not Found</h1>"]]
      end
    end
  end
end