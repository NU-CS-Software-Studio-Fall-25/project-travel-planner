require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "password must meet complexity requirements" do
    user = User.new(
      name: "Test User",
      email: "test@example.com",
      current_country: "United States"
    )

    # Test: password too short (< 7 chars)
    user.password = user.password_confirmation = "Abc1@"
    assert_not user.valid?
    assert_includes user.errors[:password], "must be at least 7 characters and include one uppercase letter, one lowercase letter, one digit and one special character (@#$%&!*)"

    # Test: missing uppercase
    user.password = user.password_confirmation = "abcd123@"
    assert_not user.valid?
    assert_includes user.errors[:password], "must be at least 7 characters and include one uppercase letter, one lowercase letter, one digit and one special character (@#$%&!*)"

    # Test: missing lowercase
    user.password = user.password_confirmation = "ABCD123@"
    assert_not user.valid?
    assert_includes user.errors[:password], "must be at least 7 characters and include one uppercase letter, one lowercase letter, one digit and one special character (@#$%&!*)"

    # Test: missing digit
    user.password = user.password_confirmation = "Abcdefg@"
    assert_not user.valid?
    assert_includes user.errors[:password], "must be at least 7 characters and include one uppercase letter, one lowercase letter, one digit and one special character (@#$%&!*)"

    # Test: missing special character
    user.password = user.password_confirmation = "Abcdefg1"
    assert_not user.valid?
    assert_includes user.errors[:password], "must be at least 7 characters and include one uppercase letter, one lowercase letter, one digit and one special character (@#$%&!*)"

    # Test: valid password with each allowed special character
    [ "@", "#", "$", "%", "&", "!", "*" ].each do |special_char|
      user.password = user.password_confirmation = "Abc123#{special_char}x"
      assert user.valid?, "Password with special char #{special_char} should be valid"
    end

    # Test: fully valid password
    user.password = user.password_confirmation = "Str0ng@Pass"
    assert user.valid?
  end
end
