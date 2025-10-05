require "test_helper"

class TravelPlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @travel_plan = travel_plans(:one)
  end

  test "should get index" do
    get travel_plans_url
    assert_response :success
  end

  test "should get new" do
    get new_travel_plan_url
    assert_response :success
  end

  test "should create travel_plan" do
    assert_difference("TravelPlan.count") do
      post travel_plans_url, params: { travel_plan: { destination_id: @travel_plan.destination_id, end_date: @travel_plan.end_date, notes: @travel_plan.notes, start_date: @travel_plan.start_date, status: @travel_plan.status, user_id: @travel_plan.user_id } }
    end

    assert_redirected_to travel_plan_url(TravelPlan.last)
  end

  test "should show travel_plan" do
    get travel_plan_url(@travel_plan)
    assert_response :success
  end

  test "should get edit" do
    get edit_travel_plan_url(@travel_plan)
    assert_response :success
  end

  test "should update travel_plan" do
    patch travel_plan_url(@travel_plan), params: { travel_plan: { destination_id: @travel_plan.destination_id, end_date: @travel_plan.end_date, notes: @travel_plan.notes, start_date: @travel_plan.start_date, status: @travel_plan.status, user_id: @travel_plan.user_id } }
    assert_redirected_to travel_plan_url(@travel_plan)
  end

  test "should destroy travel_plan" do
    assert_difference("TravelPlan.count", -1) do
      delete travel_plan_url(@travel_plan)
    end

    assert_redirected_to travel_plans_url
  end
end
