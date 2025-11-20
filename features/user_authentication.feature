# File: `features/user_authentication.feature`
Feature: User authentication
  As a visitor
  I want to sign up and sign in
  So I can access protected pages

  Scenario: Sign up with valid information (happy)
    Given I am on the signup page
    When I sign up with valid details
    Then I should be redirected to my travel plans page
    And I should see a welcome notice

  Scenario: Sign up with invalid password (sad)
    Given I am on the signup page
    When I sign up with an invalid password
    Then I should remain on the signup page
    And I should see a password validation error

  Scenario: Log in with an existing account (happy)
    Given an existing user exists
    When I log in with valid credentials
    Then I should be redirected to my travel plans page

  Scenario: Log in with wrong credentials (sad)
    Given an existing user exists
    When I log in with invalid credentials
    Then I should remain on the login page
    And I should see an invalid credentials message