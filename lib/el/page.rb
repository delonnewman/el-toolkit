# frozen_string_literal: true
module El
  class Page < View
    class << self
      def title(string = nil)
        if string
          @title = string
        else
          @title
        end
      end

      def path(string = nil)
        if string
          @path = string
        else
          @path
        end
      end
    end

    def render_content
      ERB.new(DEFAULT_LAYOUT).result(binding)
    end

    def content
      render El::HTML.new
    end

    def title
      @title ||= (self.class.title || self.class.to_s.split('::').last)
    end

    def path
      @path ||= (self.class.path || "/#{self.class.to_s.split('::').last.downcase}")
    end

    def runtime_javascript
      RUNTIME_JAVASCRIPT
    end

    private

    DEFAULT_LAYOUT = <<~HTML
      <!doctype html>
      <html lang="en">
      <head>
        <meta charset="utf-8">
        <title><%= title %></title>
      </head>
      <body>
        <%= content %>
        <script>
          <%= runtime_javascript %>
        </script>
      </body>
      </html>
    HTML

    RUNTIME_JAVASCRIPT = <<~JS
      (function() {

          this.el = this.el || {};
          
          function callAction(actionId, element) {
              console.log('calling action', actionId, element);
              var xhr = new XMLHttpRequest();
              xhr.onreadystatechange = function() {
                  if (xhr.readyState === XMLHttpRequest.DONE) {
                      console.log('response:', xhr.responseText);
                  }
                  else {
                      console.error("Something's wrong");
                  }
              };
              xhr.open('POST', '/action/' + actionId);
              xhr.send();
          }
      
          this.el.actions = {
              call: callAction
          };
      
      }.call(window));
    JS
  end
end