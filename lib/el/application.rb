module El
  class Application
    def initialize(pages)
      @pages = pages.reduce({}) do |h, page|
        h.merge!(page.path => page)
      end
    end

    def call(env)
      path = env['REQUEST_PATH']
      
      if path.start_with?('/action')
        El.call_action(path.split('/').last)
        [200, {'Content-Type' => 'text/html'}, []]
      else
        render_page(path)
      end
    end

    def render_page(path)
      page = @pages[path]

      if page
        [200, { 'Content-Type' => 'text/html' }, [page.render_content]]
      else
        [404, { 'Content-Type' => 'text/html' }, ["<h1>Not Found</h1>"]]
      end
    end
  end
end