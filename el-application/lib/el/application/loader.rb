# frozen_string_literal: true

module El
  module Application
    # A resource for handling code loading
    class Loader
      include Servicable

      attr_reader :instance, :app

      def initialize(app)
        @app = app
        @instance = Zeitwerk::Loader.new
      end

      def reload!
        instance.eager_load
        instance.reload

        self
      end

      def on_setup(&block)
        instance.on_setup(&block)

        self
      end

      def on_load(*args, &block)
        instance.on_load(*args, &block)

        self
      end

      # TODO: make these configurable
      INFLECTIONS = {
        'json_response' => 'JSONResponse'
      }.freeze

      IGNORE_PATHS = [
        '**/templates',
        '**/core_ext.rb',
        '**/layouts',
        'vendor/**'
      ].freeze

      COLLAPSE_PATHS = [
        '**/controllers',
        '**/views',
        '**/shared'
      ].freeze

      def load!
        @instance.inflector.inflect(INFLECTIONS)

        init_app_paths
        init_ignore_paths
        init_collapse_paths

        @instance.enable_reloading if app.settings[:autoreload]
        init_livereload! if app.settings[:livereload]

        @instance.setup
        @instance.eager_load

        loaded!
      end

      private

      def init_livereload!
        require 'rack-livereload'
        app.use Rack::LiveReload
      end

      def init_app_paths
        @instance.push_dir(app.lib_path, namespace: app.class.app_module)
        @instance.push_dir(app.app_path, namespace: app.class.app_module)
      end

      def init_ignore_paths
        IGNORE_PATHS.each do |path|
          @instance.ignore(path)
        end
      end

      def init_collapse_paths
        COLLAPSE_PATHS.each do |path|
          @instance.collapse(path)
        end
      end
    end
  end
end
