# frozen_string_literal: true
require 'logger'
require 'pathname'
require 'zeitwerk'

module El
  # Represents a web application, handles dependency injection.
  # (see https://github.com/stuartsierra/component)
  #
  # @example
  #   class ChatApplication < El::Application
  #     root_path File.join(__dir__, '..')
  #
  #     public '/'
  #
  #     get '/rooms' do
  #       Room.all.to_json
  #     end
  #
  #     get '/rooms/:id' do |id|
  #       Room.find(id).to_json
  #     end
  #
  #     get '/rooms/:id/members' do |id|
  #       Room.find(id).members.to_json
  #     end
  #
  #     post '/rooms/:id/message' do |id|
  #       Room.find(id).message.create(params.slice(:user_id, :content))
  #     end
  #   end
  #
  # @!attribute [r] loader
  #   @return [Zeitwerk::Loader] the autoloader used by the application
  #
  # @!attribute [r] env
  #   @return [:test, :development, :production] the environment the application is in
  #
  # @!attribute [r] root
  #   @return [Pathname] the root path of the application
  #
  # @!attribute [r] logger
  #   @return [#info, #warn, #error] the logger for the application
  #
  # @!attribute [r] system
  #   @return [Hash{Symbol => Object}] the system of dependencies for the application
  class Application
    attr_reader :loader, :env, :root, :logger, :system, :app

    class << self
      # A "macro" method to specify paths that should be used to serve static files.
      # They will be served from the "public" directory within the applications root_path.
      # 
      # @param paths [Array<String>]
      def public(*paths)
        use Rack::TryStatic, root: 'public', urls: paths, try: %w[.html index.html /index.html]
      end

      # A "macro" method to specify Rack middleware that should be used by this application.
      #
      # @param klass [Class] Rack middleware
      # @param args [Array] arguments for initializing the middleware
      def use(klass, *args)
        @middleware ||= []
        @middleware << [klass, args]
      end

      # Return an array of Rack middleware (used by this application) and their arguments.
      #
      # @return [Array<[Class, Array]>]
      def middleware
        @middleware || EMPTY_ARRAY
      end

      # A "macro" method for specifying the root_path of the application.
      # If called as a class method it will return the value that will be used
      # when instatiating.
      # 
      # @param dir [String]
      # @return [String, nil]
      def root_path(dir = nil)
        @root_path = dir unless dir.nil?
        @root_path
      end

      # A "macro" method for specifying the system of dependencies for the application.
      # If called as a class method it will return the value that will be used
      # when instatiating.
      # 
      # @param sys [Hash{Symbol => Object}]
      # @return [Hash{Symbol => Object}, nil]
      def system(sys = nil)
        @system = sys unless sys.nil?
        @system || EMPTY_HASH
      end

      # Return the raw route data for the application.
      # 
      # @return [Array<Array<[Symbol, String, Hash, Proc]>>]
      def routes
        @routes || EMPTY_ARRAY
      end

      # Valid methods for routes
      METHODS = %i[get post delete put head].to_set.freeze

      # A "macro" method for defining a route for the application.
      #
      # @param method [:get, :post, :delete :put, :head]
      def route(method, path, **options, &block)
        raise "Invalid method: #{method.inspect}" unless METHODS.include?(method)

        @routes ||= []
        @routes << [method, path, options, block]
      end

      METHODS.each do |method|
        define_method method do |path, **options, &block|
          route(method, path, **options, &block)
        end
      end
    end

    def initialize(root_path: self.class.root_path, logger: nil, system: self.class.system)
      raise "A root directory must be specified with :root_path" if root_path.nil?

      @system = system
      @logger = logger || Logger.new($stdout)
      @root   = Pathname.new(root_path).expand_path
      @env    = ENV.fetch('APP_ENV') { ENV.fetch('RACK_ENV') { :development } }.to_sym

      @loader = Zeitwerk::Loader.new.tap do |loader|
        loader.push_dir(root.join('lib'))
        loader.enable_reloading if env == :development
      end
    end

    # Rack integration for this application
    #
    # @return [#call]
    def app
      return @app if @app

      @app = Pendragon.new(type: :radix) do
        self.class.routes.each do |(method, path, options, block)|
          route method, path, **options, &block
        end
      end

      unless (middleware = self.class.middleware).empty?
        @app = Rack::Builder.new do
          middleware.each do |(klass, args)|
            use klass, *args
            run @app
          end
        end
      end

      @app
    end

    # Return the named component of the application.
    #
    # @param component [Symbol]
    def [](component)
      @system[component]
    end

    # Initialize the autoloader and system components in insertion order.
    def init!
      loader.setup
      @system.each_value(&:start)
      self
    end

    # Stop the system components in insertion order.
    def stop!
      @system.each_value(&:stop)
      self
    end

    EMPTY_ARRAY = [].freeze
    EMPTY_HASH  = {}.freeze
    private_constant :EMPTY_HASH, :EMPTY_ARRAY
  end
end
