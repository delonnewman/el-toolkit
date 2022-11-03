module El
  module Routable
    module API
      module ClassMethods
        # Return an array of Rack middleware (used by this application) and their arguments.
        #
        # @return [Array<[Class, Array]>]
        def middleware
          @middleware ||= []
        end

        # Return a hash of media type aliases.
        #
        # @return [Hash{Symbol, String}]
        def media_type_aliases
          @media_type_aliases ||= Hash.new { |_, k| k }
        end
        alias content_type_aliases media_type_aliases

        # Return the routing table for the class.
        #
        # @return [Routes]
        def routes
          @routes ||= Routes.new
        end

        # Make internal data structures immutable
        #
        # @return [ClassMethods]
        def freeze
          routes.freeze
          middleware.freeze
          media_type_aliases.freeze
          self
        end
      end
    end
  end
end
