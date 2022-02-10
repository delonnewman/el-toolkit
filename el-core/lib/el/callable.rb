# frozen_string_literal: true

require_relative "trait"

module El
  module Callable
    extend Trait

    module_doc %{
      This module attempts to generalize the notion of a first class function or Procs as they are often called
      in Ruby. It enables any class and it's objects to be treated as first-class functions.

      ```ruby
      class TwitterPoster
        include El::Callable

        def call(user)
          # do the dirt
          ...
          TwitterStatus.new(user, data)
        end
      end

      users.map(&TwitterPoster.new) # => [#<TwitterStatus>, ...]
      ```
    }

    requires :call, "When defined will enable this object to behave like a Proc"

    doc "Return a Proc that resresents this object, works with Ruby's '&' interface."
    def to_proc
      lambda do |*args|
        call(*args)
      end
    end
  end
end
