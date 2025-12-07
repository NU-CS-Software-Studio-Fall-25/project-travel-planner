require "test_helper"

class DestinationsHelperTest < ActionView::TestCase
  test "tripadvisor_url generates valid search URL" do
    destination = destinations(:one)
    url = tripadvisor_url(destination)

    assert_not_nil url
    assert_match(/tripadvisor\.com/, url)
    assert_match(/Search\?q=/, url)
  end

  test "tripadvisor_url returns nil for destination without name" do
    destination = Destination.new(country: "Test Country")
    url = tripadvisor_url(destination)

    assert_nil url
  end

  test "tripadvisor_url encodes special characters" do
    destination = Destination.new(
      name: "São Paulo",
      country: "Brazil"
    )
    url = tripadvisor_url(destination)

    assert_match(/S%C3%A3o/, url)
  end

  test "safety_badge_class returns success for high scores" do
    assert_equal "bg-success", safety_badge_class(9)
    assert_equal "bg-success", safety_badge_class(10)
    assert_equal "bg-success", safety_badge_class(8)
  end

  test "safety_badge_class returns warning for medium scores" do
    assert_equal "bg-warning text-dark", safety_badge_class(7)
    assert_equal "bg-warning text-dark", safety_badge_class(6)
    assert_equal "bg-warning text-dark", safety_badge_class(5)
  end

  test "safety_badge_class returns danger for low scores" do
    assert_equal "bg-danger", safety_badge_class(4)
    assert_equal "bg-danger", safety_badge_class(2)
    assert_equal "bg-danger", safety_badge_class(0)
  end

  test "safety_badge_class returns secondary for nil score" do
    assert_equal "bg-secondary", safety_badge_class(nil)
  end
end
