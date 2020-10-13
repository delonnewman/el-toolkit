module El
  class JSONPage < Page
    abstract!
    content_type 'application/json'

    def render_content
      [ render.to_json ]
    end
  end
end