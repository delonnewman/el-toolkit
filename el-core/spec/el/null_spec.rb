require 'el/null'

RSpec.describe El::Null do
  it "returns itself with any method call except to_s and inspect" do
    expect(El::Null.anything).to be El::Null
  end

  it "will return false to meta queries with respond_to? for any method except to_s and inspect" do
    examples = { :to_s => true, :inspect => true, :anything => false, :something => false }

    examples.each do |method, result|
      expect(El::Null.respond_to?(method)).to be result
    end
  end

  describe "to_s" do
    it "returns ''" do
      expect(El::Null.to_s).to eq ""
    end
  end

  describe "inspect" do
    it "returns 'El::Null'" do
      expect(El::Null.inspect).to eq "El::Null"
    end
  end
end
