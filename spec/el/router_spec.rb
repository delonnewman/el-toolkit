require 'el/router'

RSpec.describe El::Router do
  let(:router) { described_class.new }

  describe '#add' do
    it 'should add routes to the routing table' do
      $test = 1

      match =
        router
          .add(:get, '/user', ->{ $test = 2 })
          .match(:get, '/user')

      expect(match).not_to be false
      match[:action].call

      expect($test).to eq 2
    end
  end

  describe '#match' do
    it 'should match simple paths' do
      $test = 1

      match =
        router
          .add(:get, '/testing', ->{ $test = 3 })
          .match(:get, '/testing')
      
      expect(match).not_to be false

      match[:action].call

      expect($test).to eq 3
    end

    it 'should match paths with variables' do
      $test = 1

      router
        .add(:get, '/user/:id', ->{ $test = 4 })
        .add(:get, '/user/:id/settings', ->{ $test = 5 })
        .add(:get, '/user/:id/packages/:package_id', ->{ $test = 6 })

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
