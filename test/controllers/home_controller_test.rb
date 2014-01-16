require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  test "should get current" do
    get :current
    assert_response :success
  end

end
