require_relative '../helpers'

module El
  class ActionTest < Minitest::Test
    def test_serialize
      a0 = Action.new { 1 }
      assert_equal 1, a0.call

      a1 = Action.deserialize(a0.serialize!)
      assert_equal 1, a1.call
    end
  end
end