module El
  class Agent
    include JavaScript

    attr_reader :id, :value

    def initialize(view, init, proc)
      @view  = view
      @value = init
      @proc  = proc
      @id    = object_id
    end

    def render
      value = view.instance_exec(&@proc)
      case value
      when HTML::Element
        value.with_attributes(id: "agent-#{id}").to_html
      else
        html.div(id: "agent-#{id}", content: value)
      end
    end
    alias to_html render

    def send(&block)
      document.querySelector("#agent-#{id}").value.then(block)
    end

    private

    def html
      HTML.instance
    end
  end
end