require "test_helper"

class DestinationShowPageTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @destination = destinations(:one)
    login_as(@user)
  end

  test "displays destination header with key information" do
    visit destination_path(@destination)

    # Check that the destination name is displayed prominently
    assert_selector "h1.destination-name", text: @destination.name

    # Check that location is shown
    assert_selector ".destination-location", text: @destination.country

    # Check quick info items are present
    assert_selector ".quick-info-item", minimum: 3

    # Check safety score is displayed
    assert_selector ".quick-info-value .badge", text: /\d+\/10/
  end

  test "displays TripAdvisor link when destination has valid data" do
    visit destination_path(@destination)

    # Check that TripAdvisor link exists and opens in new tab
    assert_selector "a[href*='tripadvisor.com']", text: /TripAdvisor/i
    assert_selector "a[target='_blank'][rel='noopener noreferrer']"
  end

  test "displays Plan Your Trip call-to-action button" do
    visit destination_path(@destination)

    # Check primary CTA exists
    assert_selector "a.destination-cta", text: /Plan Your Trip/i

    # Verify it links to travel plans
    assert_selector "a.destination-cta[href*='travel_plans']"
  end

  test "responsive layout on mobile viewports" do
    # Simulate mobile viewport
    page.driver.browser.manage.window.resize_to(375, 667)

    visit destination_path(@destination)

    # Verify key elements are still visible
    assert_selector ".destination-header"
    assert_selector ".destination-actions"
  end

  test "displays visa badge when visa is required" do
    @destination.update(visa_required: true)
    visit destination_path(@destination)

    assert_selector ".quick-info-value .badge", text: /Required/i
  end

  test "accessibility: header has proper semantic structure" do
    visit destination_path(@destination)

    # Check for proper heading hierarchy
    assert_selector "h1", text: @destination.name

    # Verify SVG icons have aria-hidden
    assert_selector "svg[aria-hidden='true']", minimum: 1
  end

  private

  def login_as(user)
    visit login_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password"
    click_button "Log in"
  end
end
