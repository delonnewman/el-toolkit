module Examples
  module Pages
    class Feed < El::JSONPage
      def render
        { application: app.name,
          pages: app.page_instances.map { |page|
            { name: page.name,
              path: page.path,
              views: page.views.map { |view|
                { name: view.name }
              }
            }
          }
        }
      end
    end
  end
end