Feature: Authentication smoke tests
  Quickly verify the auth pages and a basic login failure.

  Scenario: Signup page loads
    Given I am on the signup page
    Then I should remain on the signup page

  Scenario: Login page basic failure
    Given an existing user exists
    When I log in with invalid credentials
    Then I should remain on the login page