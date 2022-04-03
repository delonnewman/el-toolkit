# frozen_string_literal: true

module El
  module Application
    # A resource for loading settings from user and environment variables
    class Settings
      include Servicable

      attr_reader :app

      def initialize(app)
        @app = app
        @settings = {} # TODO: wrap in an atom
      end

      def [](key)
        @settings[normalize_key(key)]
      end

      def []=(key, value)
        @settings[key] = value # TODO: use @settings.swap { |s| s.merge(key => value) }
      end

      def load!
        return if loaded?

        load_user_settings!
        load_env!

        loaded!
        self
      end

      def unload!
        @loaded = false
        @settings = {}
        self
      end

      def dotenv_paths
        %W[.env .env.#{app.env}].map do |path|
          app.root_path.join(path)
        end
      end

      def to_s
        "#<#{self.class} #{@settings.inspect}>"
      end
      alias inspect to_s

      private

      def normalize_key(key)
        return key if key.is_a?(Symbol)

        key.downcase.to_sym
      end

      def load_settings_from_environment!(settings)
        settings.each do |setting|
          env_name = app.class.settings_from_environment[setting]
          @settings.merge!(setting => ENV.fetch(env_name))
        end

        self
      end

      def load_dotenv_files
        dotenv_paths.reduce({}) do |h, path|
          if path.exist?
            h.merge!(Dotenv.load(path))
          else
            h
          end
        end
      end

      def load_env!
        settings = load_dotenv_files
        @settings.merge!(settings.transform_keys(&method(:normalize_key)))

        missing = app.class.settings_from_environment.keys - @settings.keys
        load_settings_from_environment!(missing)

        self
      end

      def load_user_settings!
        @settings.merge!(app.class.settings)
      end
    end
  end
end
