require 'el/null'

RSpec.describe El::Null do
  it "returns itself with any method call except to_s and inspect" do
    expect(El::Null.anything).to be El::Null
  end

  describe 'to_s' do
    it "returns 'El::Null'" do
      expect(El::Null.to_s).to eq 'El::Null'
    end
  end

  describe 'inspect' do
    it "returns 'El::Null'" do
      expect(El::Null.inspect).to eq 'El::Null'
    end
  end
end
