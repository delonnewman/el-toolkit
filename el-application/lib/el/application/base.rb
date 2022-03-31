# frozen_string_literal: true

module El
  module Application
    # Represents the application state
    class Base
      extend ClassMethods

      def self.init!(env = ENV.fetch('RACK_ENV', 'development').to_sym)
        new(env).init!
      end

      def self.with_only_settings(env = ENV.fetch('RACK_ENV', 'development').to_sym)
        new(env).tap do |app|
          app.settings.load!
        end
      end

      def self.freeze
        dependencies[:routers].each(&:freeze)
        self
      end

      def self.rack
        init!.rack_app
      end

      ClassMethods::DEPENDENCY_KINDS.each do |kind|
        define_singleton_method kind do
          dependencies.fetch(kind)
        end

        define_method kind do
          dependencies.fetch(kind)
        end
      end

      attr_reader :env, :logger, :root_path, :request, :settings, :loader, :dependencies, :server, :rack_app, :routes

      def initialize(env)
        @env          = env # development, test, production, ci, etc.
        @logger       = Logger.new($stdout, level: log_level)
        @root_path    = Pathname.new(self.class.root_path || Dir.pwd)
        @settings     = Settings.new(self)
        @loader       = Loader.new(self)
        @dependencies = ClassMethods::DEPENDENCY_KINDS.reduce({}) { |h, kind| h.merge(kind => {}) }
        @routes       = El::Routes.new
      end

      def reload!
        settings.unload!
        loader.reload!
        @initialized = false

        init!

        true
      end

      def log_level
        case env
        when :test
          :warn
        when :production
          :error
        else
          :info
        end
      end

      %i[production development test ci].each do |env|
        define_method :"#{env}?" do
          self.env == env
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

      # Rack interface
      def call(env)
        env['rack.logger'] = logger

        reload! if development? && initialized?

        # dispatch routes
        request = routes.match(env)

        if development?
          request_history << request
          request.respond!(self)
        else
          request.repond(self)
        end
      end

      def request_history
        @request_history ||= []
      end

      def init!
        raise 'An application can only be initialized once' if initialized? && !development?

        notify
        settings.load!
        loader.load! unless loader.loaded?

        initialize_dependencies!
        initialize_middleware!

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

      def initialize_dependencies!
        ClassMethods::DEPENDENCY_KINDS.each do |kind|
          self.class.dependencies[kind].each_with_object(dependencies[kind]) do |(name, opts), deps|
            if opts[:init]
              deps.merge!(name => opts[:object].init_app!(self, opts[:object]))
            else
              deps.merge!(name => opts[:object])
            end
          end
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

        @rack_app = Rack::Builder.new do
          middleware.each do |(middle, options)|
            use middle, options
            run app
          end
        end
      end
    end
  end
end
