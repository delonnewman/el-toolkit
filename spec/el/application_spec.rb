require 'el/application'

RSpec.describe El::Application do
  class TestApplicaton < described_class
    root_path '.'

    get ?/ do
      'root dir'
    end

    get '/user/:id' do
      'get user'
    end

    post '/user' do
      'create user'
    end
  end

  let(:app) { TestApplication.new }

  describe '#app'
  describe '#'
end
