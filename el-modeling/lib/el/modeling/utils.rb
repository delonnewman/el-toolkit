module El
  module Modeling
    module Utils
      extend self

      def entity_name(string, namespace: false)
        string = string.split('::').last unless namespace
        Inflection.singular(StringUtils.camelcase(string))
      end

      def table_name(string, namespace: false)
        string = string.split('::').last unless namespace
        Inflection.plural(StringUtils.underscore(string))
      end
      alias repository_name table_name

      def join_table_name(entity_class, other_class)
        "#{table_name(entity_class.name)}_#{table_name(other_class.name)}"
      end

      def component_table_name(attribute)
        table_name(attribute.value_class.name)
      end

      def reference_key(string)
        string = string.name if string.is_a?(Symbol)
        "#{Inflection.singular(string)}_id"
      end
    end
  end
end
