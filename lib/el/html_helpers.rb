module El
  module HTMLHelpers
    def link_to(*args)
      content = attributes = link = nil

      if args.size == 3
        content, link, attributes = args
      elsif args.size == 2
        link, attributes = args
        content = yield
      else
        raise ArgumentError, "wrong number of arguments: expected 2 or 3 got #{args.size}"
      end

      if attributes
        @callbacks = attributes.delete(:on) || {}
        @callbacks.each do |name, cb|
          if Proc === cb
            action = Action.new(cb)
            attributes[:"on#{name}"] = "return el.actions.call(#{action.id}, this)"
            app.action_registry.register(action)
          elsif cb.respond_to?(:to_js)
            attributes[:"on#{name}"] = cb.to_js
          end
        end
      end

      html.a(attributes.merge(href: link, content: content))
    end
  end
end