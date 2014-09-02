require 'test_helper'

class ClientsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should get show" do
    get :show
    assert_response :success
  end

  test "should get destroy" do
    get :destroy
    assert_response :success
  end

  test "should get individual_detail" do
    get :individual_detail
    assert_response :success
  end

  test "should get cellular_number" do
    get :cellular_number
    assert_response :success
  end

end
