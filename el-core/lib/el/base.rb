# frozen_string_literal: true

module El
  # An enhanced base class
  class Base
    class << self
      def assign_once(name)
        define_method "#{name}=" do |value|
          current_value = instance_variable_get("@#{name}")
          raise "#{name} has already been set, it cannot be set again." if current_value

          instance_variable_set("@#{name}", value)
        end

        define_method name do
          instance_variable_get("@{name}")
        end
      end

      def class_doc(doc)
        class_meta(doc: doc)
      end

      def class_meta(data)
        @class_metadata = data
      end

      def class_metadata
        @class_metadata
      end

      def doc(doc)
        meta(doc: doc)
      end
    
      def meta(data)
        @_metadata = data
      end
    
      def add_method_metadata(method, data)
        @method_metadata ||= {}
        @method_metadata[method] = data
      end
    
      def method_metadata(method)
        @method_metadata[method]
      end
      
      def method_added(method)
        add_method_metadata(method, @_metadata)
        @_metadata = nil
      end
    end
  end
end
