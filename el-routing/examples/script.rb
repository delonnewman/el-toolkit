require_relative '../lib/el/routable/script'
require 'rack/handler/puma'

routes do
  get '/' do
    "Hey its #{Time.now}"
  end
end

run