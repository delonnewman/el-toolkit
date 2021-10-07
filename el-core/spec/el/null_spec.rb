require 'el/null'

RSpec.describe El::Null do
  it "returns itself with any method call" do
    expect(El::Null.anything).to be El::Null
  end
end
