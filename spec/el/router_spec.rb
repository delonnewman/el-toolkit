require 'el/router'

RSpec.describe El::Router do
  let(:router) { described_class.new }

  describe '#add' do
    it 'should add routes to the routing table' do
      $test = 1

      router
        .add(:get, '/user', ->{ $test = 2 })
        .match(:get, '/user').call

      expect($test).to eq 2
    end
  end

  describe '#match' do
    it 'should match simple paths' do
      $test = 1

      router
        .add(:get, '/testing', ->{ $test = 3 })
        .match(:get, '/testing').call

      expect($test).to eq 3
    end

    it 'should match paths with variables' do
      $test = 1

      router
        .add(:get, '/user/:id', ->{ $test = 4 })
        .add(:get, '/user/:id/settings', ->{ $test = 5 })
        .add(:get, '/user/:id/packages/:package_id', ->{ $test = 6 })

      router.match(:get, '/user/1').call
      expect($test).to eq 4

      router.match(:get, '/user/1/settings').call
      expect($test).to eq 5

      router.match(:get, '/user/1/packages/abad564').call
      expect($test).to eq 6
    end
  end
end
