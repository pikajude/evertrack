require 'test_helper'

class NotesControllerTest < ActionController::TestCase
  test "should get view" do
    get :view
    assert_response :success
  end

  test "should get update" do
    get :update
    assert_response :success
  end

end
