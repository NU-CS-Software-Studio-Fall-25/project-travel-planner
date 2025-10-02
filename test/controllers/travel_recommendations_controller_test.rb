require "test_helper"

class TravelRecommendationsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get travel_recommendations_index_url
    assert_response :success
  end

  test "should get show" do
    get travel_recommendations_show_url
    assert_response :success
  end

  test "should get new" do
    get travel_recommendations_new_url
    assert_response :success
  end

  test "should get create" do
    get travel_recommendations_create_url
    assert_response :success
  end
end
