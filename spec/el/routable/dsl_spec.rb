require 'el/routable'

RSpec.describe El::Routable do
  let(:routable) { Class.new.include(described_class) }

  it 'can specify namespaces for routes' do
    routable.namespace('/test').get('/:id', ->{})

    expect(routable.routes.fetch(:get, '/test/1')).not_to be_nil
  end
end
