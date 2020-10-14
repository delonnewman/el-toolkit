module Examples
  module Pages
    class Feed < El::JSONPage
      def render
        { application: app.name }
      end
    end
  end
end