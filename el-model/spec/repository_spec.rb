require 'spec_helper'
include Drn::Framework

class Ordered < Repository
  order_by :sort_order
end

RSpec.describe Repository do
  let(:db) { Drn::Mentoring.app.db }

  describe '.order_by' do
    let(:repo) { Ordered.new(db[:products], Product) }

    it "set's the order for the repository" do
      expect { repo.all }.not_to raise_error
    end
  end

  describe '#find_by' do
    let(:repo) { described_class.new(db[:users], User) }

    it 'should retrieve a single value or return nil' do
      user = repo.find_by(username: 'delon')
      expect(user).not_to be_nil
    end

    it 'should resolve predicate attributes' do
      expect { repo.find_by!(id: 1) }.not_to raise_error
    end
  end
end
