# frozen_string_literal: true

module Dragnet
  module DOM
    class RubyCode < Text
      def name
        '#ruby'
      end

      def to_s
        "<%= #{content} %>"
      end
    end
  end
end
