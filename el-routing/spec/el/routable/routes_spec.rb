require "el/routable/routes"

RSpec.describe El::Routable::Routes do
  subject(:routes) { described_class.new }

  describe "#match" do
    context "when a route does not contain variables" do
      before do
        routes.add!(:get, "/testing", -> { $test = 3 })
      end

      it "will match the corresponding path" do
        match, = routes.match(Rack::MockRequest.env_for("/testing"))

        expect(match).not_to be false
      end

      it "should match simple paths" do
        $test = 1

        match, = routes.match(Rack::MockRequest.env_for("/testing"))
        match.action.call

        expect($test).to eq 3
      end
    end

    context "when a route contains variables" do
      before do
        routes.add!(:get, "/user/:id", -> { $test = 4 })
              .add!(:get, "/user/:id/settings", -> { $test = 5 })
              .add!(:get, "/user/:id/packages/:package_id", -> { $test = 6 })
      end

      before :all do
        $test = 1
      end

      it "will match a path with a single variable" do
        match, = routes.match(Rack::MockRequest.env_for("/user/1"))
        match.action.call

        expect($test).to eq 4
      end

      it "will match a path that has additional content after the variable" do
        match, = routes.match(Rack::MockRequest.env_for("/user/1/settings"))
        match.action.call

        expect($test).to eq 5
      end

      it "will return the variables in the params hash" do
        _, params = routes.match(Rack::MockRequest.env_for("/user/1/packages/abad564"))

        expect(params).to match a_hash_including(id: "1", package_id: "abad564")
      end

      it "will match a path that has more than on variable" do
        match, = routes.match(Rack::MockRequest.env_for("/user/1/packages/abad564"))
        match.action.call

        expect($test).to eq 6
      end
    end
  end
end
