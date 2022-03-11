require 'el/routable'

class TestApp
  include El::Routable
  require 'json'

  get '/' do
    'root dir'
  end

  get '/user/:id' do
    "get user #{params[:id]}"
  end

  post '/user' do
    'create user'
  end

  get '/simple', -> { 'Testing' }

  get '/array' do
    [200, { 'Content-Type' => 'text/plain' }, ['Hello!']]
  end

  get '/hash' do
    { status:  200,
      headers: { 'Content-Type' => 'text/plain' },
      body:    ['Hello!'] }
  end

  get '/only-json', accept: :json do
    'This as JSON'
  end

  get '/only-json' do
    'This is not JSON'
  end

  get '/destruct' do |req|
    case req
    in { content_type: 'application/json' }
      'This is JSON'
    else
      'This is not JSON'
    end
  end
end

RSpec.describe El::Routable do
  describe TestApp do
    context 'when url params are given' do
      it 'will pass them to the router action as params' do
        env = Rack::MockRequest.env_for('/user/1')

        expect(described_class.call(env)[2].string).to eq 'get user 1'
      end
    end

    it 'should support procs for route actions' do
      env = Rack::MockRequest.env_for('/simple')

      expect(described_class.call(env)[2].string).to eq 'Testing'
    end
  end
end
