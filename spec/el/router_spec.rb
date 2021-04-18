require 'el/router'

RSpec.describe El::Router do
  describe '.from' do
    it 'should return a router instance from the given routing data' do
      paths   = ['/test', '/testing', '/a/b/c/d']
      routing = paths.map { |path| [:get, path, ->{ path }] }
      router  = described_class.from(routing)

      paths.each do |path|
        expect(router.match(:get, path)[:action].call).to be path
      end
    end
  end

  describe '.parse' do
    it 'should return a compiled route hash' do
      route = described_class.parse('/user')

      expect(route[:names]).to be_empty
      expect(route[:path]).to eq ['user']
    end
  end

  describe '#match' do
    it 'should match simple paths' do
      $test = 1
      router = described_class.from([[:get, '/testing', ->{ $test = 3 }]])
      match  = router.match(:get, '/testing')
      
      expect(match).not_to be false
      match[:action].call

      expect($test).to eq 3
    end

    it 'should match paths with variables' do
      $test = 1

      router = described_class.from([
        [:get, '/user/:id', ->{ $test = 4 }],
        [:get, '/user/:id/settings', ->{ $test = 5 }],
        [:get, '/user/:id/packages/:package_id', ->{ $test = 6 }]
      ])

      match = router.match(:get, '/user/1')
      expect(match).not_to be false

      match[:action].call
      expect($test).to eq 4

      match = router.match(:get, '/user/1/settings')
      expect(match).not_to be false

      match[:action].call
      expect($test).to eq 5

      match = router.match(:get, '/user/1/packages/abad564')
      expect(match).not_to be false

      match[:action].call
      expect($test).to eq 6
    end
  end
end
