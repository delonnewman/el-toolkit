module El
  module JavaScript
    def select(pattern)
      Query.new(pattern)
    end

    def alert(msg)
      Alert.new(msg)
    end

    def confirm(msg)
      Alert.new(msg)
    end

    module Utils
      # TODO: add more data types to serialize
      def to_javascript(value)
        if value.respond_to?(:to_js)
          value.to_js
        else
          case value
          when Date, Time, DateTime
            "new Date(#{value.to_time.to_i})"
          else
            value.to_json
          end
        end
      end
    end

    class Program
      def initialize(statements = [])
        @statements = statements
      end

      def <<(statement)
        @statements << statement
      end

      def to_js
        @statements.map(&:to_js).join(";\n") + ";\n"
      end
    end

    class Base
      include JavaScript
    end

    class Alert
      include Utils

      attr_reader :message

      def initialize(msg)
        @message = msg
      end

      def to_js
        "alert(#{to_javascript(message)})"
      end
    end

    class Confirm < Alert
      def to_js
        "confirm(#{to_javascript(message)})"
      end
    end

    class Query < Base
      attr_reader :pattern

      def initialize(pattern)
        @pattern = pattern
      end

      def text!(text)
        SetQueryInnerText.new(self, text)
      end

      def text
        GetQueryInnerText.new(self)
      end

      def select(pattern)
        Finder.new(self, pattern)
      end

      def to_js
        "document.querySelectorAll(#{pattern.to_json})"
      end
    end

    class Finder < Query
      attr_reader :query, :pattern

      def initialize(query, pattern)
        @query = query
        @pattern = pattern
      end

      def to_js
        "#{query.to_js}.find(#{pattern.to_json}"
      end
    end

    class SetQueryInnerText
      attr_reader :query, :text

      def initialize(query, text)
        @query = query
        @text  = text
      end

      def to_js
        "#{query.to_js}.forEach(function(e) { e.innerText = #{text.to_json} })"
      end
    end

    class GetQueryInnerText
      attr_reader :query

      def initialize(query)
        @query = query
      end

      def to_js
        "#{query.to_js}.text()"
      end
    end
  end
end