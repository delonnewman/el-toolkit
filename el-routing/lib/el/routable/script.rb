require_relative '../routable'

module El
  module Routable
    module Script
      def self.routers
        @routers ||= []
      end

      def self.collected_routes
        return @collected_routes if @collected_routes
        return @collected_routes = routers.first.routes if routers.count == 1

        @collected_routes = routers.reduce do |a, b|
          a.routes.merge(b.routes)
        end
      end

      def self.freeze
        collected_routes.freeze
        routers.freeze
        freeze
        self
      end

      def self.request_evaluator
        @request_evaluator ||= RequestEvaluator.new
      end

      # Return the value of the RACK_ENV environment variable as a symbol.
      # If the environment variable is not set return :development.
      #
      # @return [Symbol]
      def self.rack_env
        ENV.fetch('RACK_ENV', :development).to_sym
      end

      def self.call(env)
        request = collected_routes.match(env)

        return not_found unless request

        request_evaluator.evaluate(request)
      rescue StandardError => e
        request.errors.write(e.message) if request
        error(e)

        raise e unless rack_env == :production
      end

      # Return a not found response
      def self.not_found
        [404, RequestEvaluator::DEFAULT_HEADERS.dup, StringIO.new('Not Found')]
      end

      # Return an error response
      def self.error(_)
        [500, RequestEvaluator::DEFAULT_HEADERS.dup, StringIO.new('Server Error')]
      end

      HANDLERS = %i[Puma WEBrick]

      def self.add_handler(name)
        HANDLERS << name
      end

      def self.handler
        HANDLERS.each do |name|
          return Rack::Handler.const_get(name) if Rack::Handler.const_defined?(name)
        end
      end


      def routes(&block)
        Class.new.tap do |klass|
          klass.extend(Routable::DSL::ClassMethods)
          klass.extend(Routable::API::ClassMethods)
          klass.class_eval(&block)
          Script.routers << klass
        end
      end

      def start(args = ARGV, **options, &block)
        handler = Script.handler
        raise "unable to find a suitable handler" unless handler

        handler.run(Script, **options, &block)
      end
    end
  end
end

include El::Routable::Script
