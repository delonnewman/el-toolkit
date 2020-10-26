# frozen_string_literal: true
module El
  module Scriptable

    def javascript
      @javascript ||= JavaScript.new
    end
  end
end