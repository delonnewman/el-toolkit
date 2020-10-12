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

      def stylesheets(*paths)
        if paths.empty?
          @stylesheets ||= []
        else
          @stylesheets = paths
        end
      end
    end

    attr_reader :id

    def initialize
      @id = object_id
    end

    def render_content
      ERB.new(DEFAULT_LAYOUT).result(binding)
    end
    alias to_html render_content

    def name
      @name ||= self.class.to_s.split('::').last.downcase
    end

    def title
      @title ||= (self.class.title || name.capitalize)
    end

    def path
      @path ||= (self.class.path || "/#{name}")
    end

    def stylesheets
      self.class.stylesheets
    end

    def runtime_javascript
      RUNTIME_JAVASCRIPT
    end

    def app
      @app
    end

    # can only set the app once
    def app=(value)
      @app ||= value
    end

    private

    DEFAULT_LAYOUT = <<~HTML
      <!doctype html>
      <html lang="en">
      <head>
        <!-- TODO: generalize this -->
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">

        <title><%= title %></title>
        <% stylesheets.each do |stylesheet| %>
          <link rel="stylesheet" src="<%= stylesheet %>">
        <% end %>
      </head>
      <body id="page-<%= id %>">
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
                  var contentType, status;
                  if (xhr.readyState === XMLHttpRequest.DONE) {
                      contentType = xhr.getResponseHeader('Content-Type');
                      status = xhr.status;
                      if (status === 0 || (status >= 200 && status < 400)) {
                          if (contentType === 'application/javascript') {
                            eval(xhr.responseText.toString());
                          }
                          else {
                            console.log(xhr.responseText);
                          }
                      } else {
                          console.error('Something went wrong');
                      }
                  }
              };
              xhr.open('POST', '/action/' + actionId);
              xhr.send();

              return false;
          }
      
          this.el.actions = {
              call: callAction
          };
      
      }.call(window));
    JS
  end
end