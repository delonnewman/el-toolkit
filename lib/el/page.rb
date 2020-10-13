# frozen_string_literal: true
module El
  class Page < View
    abstract!

    class << self
      def content_type(string = nil)
        @@content_type ||= (string || 'text/plain')
      end

      def path(string = nil)
        if string
          @path = string
        else
          @path || "/#{symbol}"
        end
      end
    end

    attr_reader :id, :app, :params

    def initialize(app, params)
      @app    = app
      @params = params
      @id     = object_id
    end

    def cache?
      app.cache?
    end

    def view_cache
      @view_cache ||= {}
    end

    def view(name)
      return app.view_for(self, name) unless cache?

      view_cache[name] ||= app.view_for(self, name)
    end

    def is?(path)
      app.page(path) == self
    end
 
    def headers
      { 'Content-Type' => content_type }
    end

    [:path, :content_type].each do |method|
      define_method method do
        self.class.send(method)
      end
    end
  end
end