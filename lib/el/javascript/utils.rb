module El
  class JavaScript
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

      module_function :to_javascript
    end
  end
end