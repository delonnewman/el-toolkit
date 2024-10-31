require_relative '../lib/el/routable/script'
require 'rack/handler/puma'

routes do
  get '/' do
    "Hey its #{Time.now}"
  end
end

start Host: 'localhost', Port: 3000
