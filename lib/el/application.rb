module El
  class Application
    class << self
      def load_components(path, mod = Object)
        expanded = File.expand_path(path)
        symbols = Dir["#{expanded}/*.rb"].entries.map do |path|
          const = File.basename(path, '.rb').split('_').map(&:capitalize).join('').to_sym
          path  = File.expand_path(path)
          mod.autoload const, path
          [const, path]
        end

        symbols.map do |(const, path)|
          mod.const_get(const).tap do |klass|
            klass.file = path
          end
        end
      end


      def load(name, opts = {})
        mod = Module.new
        Object.const_set(name.to_sym, mod)

        pages_mod = Module.new
        mod.const_set(:Pages, pages_mod)

        views_mod = Module.new
        mod.const_set(:Views, views_mod)

        pages = load_components('./pages', pages_mod)
        views = load_components('./views', views_mod)        

        app = new(name, pages, views, opts)
        yield app if block_given?

        app.use Rack::Static, root: "public",
                              header_rules: [[:all, {'Cache-Control' => 'public, max-age=3600'}]],
                              urls: Dir.glob("public/*").map { |f| f.sub('public', '') }

        app
      end
    end

    attr_reader :name

    def initialize(name, pages, views, opts)
      @name  = name
      @cache = opts.fetch(:cache) { env.production? }

      @views = views.reduce({}) do |h, view|
        h.merge!(view.symbol => view)
      end

      @page_paths = {}
      @page_names = {}
      @middleware = {}

      pages.each do |page|
        next if page.abstract?
        page.tap do |page|
          @page_paths[page.path] = page
          @page_names[page.symbol] = page
        end
      end
    end

    def cache?
      @cache == true
    end

    def env
      PredicateString.new(ENV.fetch('RACK_ENV') { 'development' })
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

    def view_for(page, name)
      case name
      when Class
        name.new(page)
      else
        @views.fetch(name.to_sym).new(page)
      end
    end

    def views
      @views.values
    end

    def page_class(name)
      @page_names.fetch(name.to_sym)
    end

    def pages
      @page_names.values
    end

    def page_instances
      pages.map { |p| p.new(self) }
    end

    def page_by_path(path, params)
      @page_paths[path]&.new(self, params)
    end
    alias page page_by_path

    def call(env)
      path = env['REQUEST_PATH']
      params = Rack::Utils.parse_nested_query(env['rack.input'].read)
      
      if path.start_with?('/action')
        El.call_action(path.split('/').last, params)
      else
        render_page(path, params)
      end
    end

    def render_page(path, params)
      page = page_by_path(path, params)

      if page
        [200, page.headers, page.render_content]
      else
        [404, { 'Content-Type' => 'text/html' }, ["<h1>Not Found</h1>"]]
      end
    end
  end
end