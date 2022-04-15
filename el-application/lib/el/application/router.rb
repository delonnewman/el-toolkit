# frozen_string_literal: true

module El
  module Application
    class Router
      include Dependency
      include Routable
      extend  Pluggable

      # Common Media Types
      # (see https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types, and
      #  https://www.iana.org/assignments/media-types/media-types.xhtml)
      media_type :plain,      'text/plain'
      media_type :csv,        'test/csv'
      media_type :ics,        'text/calendar'
      media_type :pdf,        'application/pdf'
      media_type :epub,       'application/epub+zip'
      media_type :rtf,        'application/rtf'

      media_type :html,       'text/html'
      media_type :css,        'text/css'
      media_type :javascript, 'text/javascript'
      media_type :json,       'application/json'
      media_type :jsonld,     'application/ld+json'
      media_type :xml,        'application/xml', 'text/xml'
      media_type :xhtml,      'application/xhtml'
      media_type :php,        'application/x-httpd-php'
      media_type :atom,       'application/atom+xml'
      media_type :rdf,        'application/rdf+xml'
      media_type :rss,        'application/rss+xml'

      media_type :gz,         'application/gzip'
      media_type :bz,         'application/x-bzip'
      media_type :bz2,        'application/x-bzip2'

      media_type :jpeg,       'image/jpeg'
      media_type :gif,        'image/gif'
      media_type :png,        'image/png'
      media_type :image,      'image/tiff'
      media_type :svg,        'image/svg+xml'

      def self.add_to!(app_class)
        super(app_class)

        app_class.register_dependency(canonical_name, self)

        app_class.define_method(:routes) do
          @routes or raise 'application routes are not initialized, perhaps call `app.init`.'
        end
      end

      # TODO: guess based on configuration, then set once a request has been made
      DEFAULT_BASE_URL = 'http://localhost:3000'

      def self.init_app!(app)
        router = new(app)
        freeze

        app.instance_variable_set(:@routes, El::Routes.new) unless app.instance_variable_get(:@routes)
        app.routes.merge!(routes)

        router
      end

      def self.after_init_app(app)
        app.routes.include_helpers!(DEFAULT_BASE_URL)
        super(app)
      end

      def self.canonical_name
        parts = name.split('::')
        ident = parts.last == 'Router' ? parts[parts.length - 2] : parts.last
        StringUtils.underscore(ident).to_sym
      end

      attr_reader :app

      def initialize(app)
        super()

        @app = app
      end

      def logger
        app.logger
      end

      def json(*args)
        res = JSONResponse.new(response)
        return res if args.empty?

        res.render(*args)
      end

      def response
        Rack::Response.new
      end
    end
  end
end
