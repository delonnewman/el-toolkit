# frozen_string_literal: true

require 'forwardable'
require 'el/memoize'
require 'el/pluggable'
require_relative 'templating'

module El
  class Controller
    include Memoize
    include Templating
    extend  Pluggable
    extend  Forwardable

    class << self
      alias call_without_processors new
      alias call new

      def call_with_processors(app, request)
        new(app, apply_before_processors(app, request))
      end

      def apply_before_processors(app, request)
        return request unless (procs = processors[:before])

        procs.reduce(request) do |req, p|
          p.call(app, req) || req
        end
      end

      def processors
        procs = @processors ||= {}

        procs.merge!(superclass.processors) if superclass.respond_to?(:processors)

        procs
      end

      def freeze
        processors.freeze
        self
      end

      # Class DSL methods

      def before(callable = nil, &block)
        processors[:before] ||= []
        processors[:before] << callable || block
        class << self
          undef_method :call
          alias_method :call, :call_with_processors
        end
      end
      alias define_before_processor before

      def around(action, callable = nil, &block)
        processors[:around] ||= {}
        processors[:around][action] ||= []
        processors[:around][action] << callable || block
        undef_method :call
        alias_method :call, :call_with_processors
      end
      alias define_around_processor around

      def after(action, callable = nil, &block)
        processors[:after] ||= {}
        processors[:after][action] ||= []
        processors[:after][action] << callable || block
        undef_method :call
        alias_method :call, :call_with_processors
      end
      alias define_after_processor after
    end

    attr_reader :app, :request

    def_delegators 'self.class', :processors, :layout, :module_name

    def initialize(app, request)
      @app = app
      @request = request
      Memoize.init_memoize_state!(self)

      freeze
    end

    def apply_around_processors(action)
      procs = processors.fetch(:around, EMPTY_HASH).fetch(action, nil)
      return request unless procs

      procs.reduce(request) do |req, p|
        p.call(self, req) || req
      end
    end

    def apply_after_processors(action, response)
      procs = processors.fetch(:around, EMPTY_HASH).fetch(action, nil)
      return request unless procs

      procs.reduce(response) do |res, p|
        p.call(self, res) || res
      end
    end

    def call_without_processors(action)
      public_send(action)
    end
    alias call call_without_processors

    def call_with_processors(action)
      @request = apply_around_processors(action)
      res = public_send(action)
      apply_after_processors(action, res)
    end

    protected

    # Instance DSL Methods

    def_delegators :request, :params, :url_for, :options, :session
    def_delegators :app, :logger, :routes

    def escape_html(*args)
      CGI.escapeHTML(*args)
    end
    alias h escape_html

    def redirect(url, status: 302)
      r = Rack::Response.new
      r.redirect(url, status)
      r.finish
    end

    def redirect_to(path)
      redirect(request.url_for(path))
    end

    def json(*args)
      res = JSONResponse.new(response)
      return res if args.empty?

      res.render(*args)
    end

    def response
      Rack::Response.new
    end

    def render(name = nil, **options)
      return name if name.is_a?(Rack::Response)
      return render_view(name, options) unless name.nil?

      render_special_types(options)
    end

    private

    # TODO: Make this extensible

    def render_special_types(options)
      if (content = options.delete(:json))
        render_json(content)
      elsif (content = options.delete(:plain))
        render_plain(content)
      elsif (content = options.delete(:js))
        render_js(content)
      else
        raise 'No content to render has been specified'
      end
    end

    def render_json(content)
      response.tap do |res|
        res.write(content.to_json)
        res.set_header('Content-Type', 'application/json')
      end
    end

    def render_plain(content)
      response.tap do |res|
        res.write(content)
        res.set_header('Content-Type', 'text/plain')
      end
    end

    def render_js(content)
      response.tap do |res|
        content = content.to_js if content.respond_to?(:to_js)
        res.write(content)
        res.set_header('Content-Type', 'application/javascript')
      end
    end

    def render_view(view, options)
      response.tap do |res|
        res.write(init_view(view, options).render)
        res.set_header('Content-Type', 'text/html')
      end
    end

    def init_view(view, options)
      if view.is_a?(Symbol)
        data = options.delete(:with) || EMPTY_HASH
        HashView.new(self, view, data, options)
      else
        view.new(self, options)
      end
    end
  end
end
