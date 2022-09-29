# frozen_string_literal: true

module El
  module Application
    # Represents the application state
    class Base
      extend ClassMethods
      extend Pluggable['Application']

      set :not_found_path, '404.html'
      set :error_path, '505.html'

      configure :development do
        enable :logging_request_history
        enable :autoreload
        enable :livereload
        enable :raise_server_errors

        disable :template_caching
      end

      configure :production do
        disable :logging_request_history
        disable :autoreload
        disable :livereload
        disable :raise_server_errors

        enable :template_caching
      end

      def self.init!(env = environment)
        new(env).init!
      end

      def self.with_only_settings(env = environment)
        new(env).tap do |app|
          app.settings.load!
        end
      end

      def self.freeze
        self
      end

      def self.rack
        init!.rack
      end

      attr_reader :env, :logger, :root_path, :environment, :loader, :dependencies, :rack

      alias settings environment

      def initialize(env)
        @env         = env # development, test, production, ci, etc.
        @logger      = Logger.new($stdout, level: log_level)
        @root_path   = Pathname.new(self.class.root_path || Dir.pwd)
        @environment = Settings.new(self)
        @loader      = Loader.new(self)
      end

      # Base URL
      attr_reader :base_url

      def base_url=(url)
        @base_url = url
        routes.helpers.generate_methods!(url)
      end

      private :base_url=

      def reload!
        logger.info 'Reloading...'
        settings.unload!
        loader.reload!

        @routes = El::Routes.new # TODO: We'll want to formalize the semantics around reloading do dependencies can opt-in

        @initialized = false

        init!

        true
      end

      def log_level
        case env
        when :test
          :warn
        when :development
          :info
        else
          :error
        end
      end

      def lib_path
        root_path.join('lib', app_name)
      end

      def app_name
        parts = self.class.name.split('::')
        StringUtils.underscore(parts[parts.length - 2])
      end

      def app_path
        root_path.join(app_name)
      end

      def public_path
        root_path.join('public')
      end

      def public_urls
        public_path.opendir.children
      end

      def not_found(_request)
        unless (path = public_path.join(settings[:not_found_path])).exist?
          raise "specified file for error page does not exist, perhaps set :not_found_path setting or create #{path.to_s.inspect} file?"
        end

        [404, { 'Content-Type' => 'text/html' }, path]
      end

      def error(_request, err)
        logger.error(err)

        unless (path = public_path.join(settings[:error_path])).exist?
          raise "specified file for error page does not exist, perhaps set :error_path setting or create #{path.to_s.inspect} file?"
        end

        [505, { 'Content-Type' => 'text/html' }, path]
      end

      # Rack interface
      def call(env)
        env['rack.logger'] = logger

        reload! if settings[:autoreload] && initialized?

        request = routes.match(env)
        request_history << request if settings[:logging_request_history]

        return not_found(request) if request.not_found?

        dispatch_request(request)
      end

      def dispatch_request(request)
        self.base_url = request.base_url if base_url.nil?

        if settings[:raise_server_errors]
          request.respond!(self)
        else
          begin
            request.respond!(self)
          rescue StandardError => e
            error(request, e)
          end
        end
      end

      def route_helpers(&block)
        routes.helpers.module_eval(&block) if block_given?

        routes.helpers
      end

      def request_history
        @request_history ||= []
      end

      def init!
        raise 'An application can only be initialized once' if initialized? && !settings[:autoreload]

        environment.load!
        loader.load! unless loader.loaded?

        initialize_dependencies!
        initialize_middleware!
        after_init_dependencies!

        initialized!

        self
      end

      def initialized?
        !!@initialized
      end

      def middleware
        @middleware ||= self.class.middleware.dup
      end

      def use(middle, options = {})
        middleware << [middle, options]
      end

      def to_s
        "#<#{self.class} #{env}>"
      end
      alias inspect to_s

      private

      def notify
        logger.info "#{self.class} is being initialized in a #{env} environment"
      end

      def initialized!
        @initialized = true
      end

      def after_init_dependencies!
        self.class.dependencies.each_value do |dep|
          dep[:object].after_init_app(self)
        end
      end

      def initialize_dependencies!(graph = nil)
        subgraph = self.class.dependency_graph[graph]
        return unless subgraph

        subgraph.each_with_object(@dependencies ||= {}) do |name, deps|
          deps.merge!(name => init_dependency(self.class.dependency!(name)))
          initialize_dependencies!(name)
        end
      end

      def init_dependency(dep)
        if dep[:init]
          dep[:object].init_app!(self)
        else
          dep[:object]
        end
      end

      def session_options
        { secret: settings[:session_secret], key: "#{app_name}.session" }
      end

      def initialize_middleware!
        use Rack::Static, cascade: true, root: public_path, urls: public_urls << '/assets'
        use Rack::Session::Cookie, session_options if settings[:session_secret]

        app = self
        middleware = self.middleware

        @rack = Rack::Builder.new do
          middleware.each do |(middle, options)|
            use middle, options
            run app
          end
        end
      end
    end
  end
end
