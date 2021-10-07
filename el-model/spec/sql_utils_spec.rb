require 'spec_helper'

RSpec.describe Drn::Framework::StringUtils do
  describe '.parse_nesting_key' do
    it 'returns the key in a hash with the value if there is no nesting' do
      data = described_class.parse_nesting_key('testing', 1)
      expect(data).to eq({ testing: 1 })
    end

    it 'return the same hash object if a hash object is given' do
      hash = {}
      data = described_class.parse_nesting_key('testing', 1, hash)
      expect(data).to be hash
    end

    [
      { key: 'test[testing]', value: 1, result: { test: { testing: 1 } } },
      { key: 'test[testing][one_2_3]', value: 1, result: { test: { testing: { one_2_3: 1 } } } }
    ].each do |example|
      it "returns a nested hash corresponding to #{example[:key].inspect}" do
        data = described_class.parse_nesting_key(example[:key], example[:value])
        expect(data).to eq example[:result]
      end
    end
  end

  describe '.parse_nested_hash_keys' do
    [[{ :'test[testing][a]' => 1, :'test[testing][b]' => 2, 'testing' => 3, 'test[a]' => 4 },
     { test: { testing: { a: 1, b: 2 }, a: 4 }, testing: 3 }]].each do |example|
      it "returns a nested hash from corresponding to the flat hash #{example[0].inspect}" do
        data = described_class.parse_nested_hash_keys(example[0])
        expect(data).to eq example[1]
      end
    end
  end
end
