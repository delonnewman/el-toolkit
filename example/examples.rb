require 'el'

El::Examples = El::Application.load do |app|
  app.use Rack::Static, root: "public",
                        header_rules: [[:all, {'Cache-Control' => 'public, max-age=3600'}]],
                        urls: Dir.glob("public/*").map { |f| f.sub('public', '') }
end