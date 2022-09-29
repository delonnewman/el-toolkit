# frozen_string_literal: true

require 'el/string_utils'

module El
  module Templating
    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
    end

    module ClassMethods
      def layout(value = nil)
        @layout = value unless value.nil?
        @layout.nil? ? module_name : @layout
      end

      def module_name
        parts = name.split('::')
        StringUtils.underscore(parts[parts.length - 2])
      end
    end

    module InstanceMethods
      include Memoize

      def layout
        self.class.layout
      end

      def module_name
        self.class.module_name
      end

      memoize def templates
        Templates.new(self)
      end
    end
  end
end
