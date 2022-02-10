require "el/routable/routes"

# rubocop:disable Metric/BlockLength

RSpec.describe El::Routable::Routes do
  subject(:routes) { described_class.new }

  describe "#match" do
    context "when a route does not contain variables" do
      before do
        routes.add!(:get, "/testing", -> { $test = 3 })
      end

      it "will match the corresponding path" do
        route, = routes.match(Rack::MockRequest.env_for("/testing"))

        expect(route).not_to be_nil
      end

      it "will return an empty array if it doesn't match" do
        res = routes.match(Rack::MockRequest.env_for("/wrong-path"))

        expect(res).to be_empty
      end

      it "should match simple paths" do
        $test = 1
        route, = routes.match(Rack::MockRequest.env_for("/testing"))

        expect { route.action.call }.to change { $test }.from(1).to(3)
      end
    end

    context "when a route contains variables" do
      before do
        routes.add!(:get, "/user/:id", -> { $test = 4 })
              .add!(:get, "/user/:id/settings", -> { $test = 5 })
              .add!(:get, "/user/:id/packages/:package_id", -> { $test = 6 })
      end

      before :each do
        $test = 1
      end

      it "will match a path with a single variable" do
        route, = routes.match(Rack::MockRequest.env_for("/user/1"))

        expect { route.action.call }.to change { $test }.from(1).to(4)
      end

      it "will match a path that has additional content after the variable" do
        route, = routes.match(Rack::MockRequest.env_for("/user/1/settings"))

        expect { route.action.call }.to change { $test }.from(1).to(5)
      end

      it "will return the variables in the params hash" do
        _, params = routes.match(Rack::MockRequest.env_for("/user/1/packages/abad564"))

        expect(params).to match a_hash_including(id: "1", package_id: "abad564")
      end

      it "will match a path that has more than on variable" do
        route, = routes.match(Rack::MockRequest.env_for("/user/1/packages/abad564"))

        expect { route.action.call }.to change { $test }.from(1).to(6)
      end
    end
  end
end
