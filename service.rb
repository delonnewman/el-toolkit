require 'sinatra'
require_relative 'html2'

helpers do
  def html
    @html ||= El::HTML2.new
  end
end

post '/action/:id' do
  El.call_action(params[:id], params)
end

get '/?' do
  (html.script(src: 'runtime.js') +
    html.a(href: "#", on: { click: ->{ system "say TESTING!!!" } }) { html.strong { "TESTING!!!" } }).to_html
end