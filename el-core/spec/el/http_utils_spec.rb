# frozen_string_literal: true

require_relative '../../lib/el/data_utils'

describe El::DataUtils do
  describe '.parse_form_encoded_data' do
    it 'will parse form encoded data into a hash of nested values' do
      examples = [
        { string: '', value: {} },
        { string: 'a=1', value: { a: '1' } },
        { string: 'a=1&b=2&[c][]=3&[c][]=4&[d][e]=10&[d][f]=11',
          value:  { a: '1', b: '2', c: %w[3 4], d: { e: '10', f: '11' } } }
      ]

      examples.each do |example|
        expect(described_class.parse_form_encoded_data(example[:string])).to eq example[:value]
      end
    end
  end
end
