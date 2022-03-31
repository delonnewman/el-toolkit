# frozen_string_literal: true

require 'el/data_utils'

module El
  module Routable
    # Instance methods for the El::Routable module
    module InstanceMethods
      protected

      def rack_env
        ENV.fetch('RACK_ENV', :development).to_sym
      end

      def not_found
        [404, Request::DEFAULT_HEADERS.dup, StringIO.new('Not Found')]
      end

      def error(_)
        [500, Request::DEFAULT_HEADERS.dup, StringIO.new('Server Error')]
      end

      public

      def halt(*response)
        response = response[0] if response.size == 1
        throw :halt, response
      end

      %i[routes namespace middleware media_type_aliases content_type_aliases].each do |method|
        define_method method do
          self.class.public_send(method)
        end
      end

      def rack
        routable = self
        Rack::Builder.new do
          middleware.each do |middle|
            use middle
          end
          run routable
        end
      end

      # TODO: add error and not_found to the DSL
      def call(env)
        request = routes.match(env)

        return not_found unless request

        request.respond!(self)
      rescue StandardError => e
        request.errors.write(e.message)
        error(e)

        raise e unless rack_env == :production
      end
    end
  end
end
