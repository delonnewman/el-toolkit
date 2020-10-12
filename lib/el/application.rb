module El
  class Application
    attr_reader :pages

    def initialize(pages)
      @pages = pages

      @page_paths = {}
      @page_names = {}

      pages.each do |page|
        page.app = self
        @page_paths[page.path] = page
        @page_names[page.name.to_sym] = page 
      end
    end

    def page(name)
      @page_names[name]
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