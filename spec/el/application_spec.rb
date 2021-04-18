require 'el/application'

RSpec.describe El::Application do
  class TestApp < described_class
    root_path '.'

    get ?/ do
      'root dir'
    end

    get '/user/:id' do |params|
      "get user #{params[:id]}"
    end

    post '/user' do
      'create user'
    end
  end

  let(:app) { TestApp.new }

  describe '#app' do
    subject(:rack_app) { app.app }

    it 'should respond to rack requests' do
      env = Rack::MockRequest.env_for('/user/1')
      expect(rack_app.call(env)).to eq [200, {}, ['get user 1']]
    end
  end
end
