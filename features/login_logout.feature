# features/authentication/login_logout.feature
Feature: User Login and Logout

  As a user
  I want to log in and out of my account
  So that I can access my private content and secure my account.

  Background:
    Given a user exists with name "tester", email "tester@example.com", and password "Password123!"

  Scenario: Successful login with valid credentials
    Given I am on the login page
    When I fill in "email" with "tester@example.com"
    And I fill in "password" with "Password123!"
    And I press "Login"
    Then I should be on the travel plans page
    And I should see "Welcome back, tester!"

  Scenario: Unsuccessful login with incorrect password
    Given I am on the login page
    When I fill in "email" with "tester@example.com"
    And I fill in "password" with "WrongPassword!"
    And I press "Login"
    Then I should be on the login page
    And I should see "Invalid email or password"

  Scenario: Unsuccessful login with non-existent email
    Given I am on the login page
    When I fill in "email" with "nouser@example.com"
    And I fill in "password" with "Password123!"
    And I press "Login"
    Then I should be on the login page
    And I should see "Invalid email or password"

  Scenario: Successful logout
    Given I am logged in as the user "tester@example.com" with password "Password123!"
    When I press "Logout"
    Then I should be on the root page
    And I should see "You have been logged out."

  Scenario: Redirect if already logged in
    Given I am logged in as the user "tester@example.com" with password "Password123!"
    When I go to the login page
    Then I should be on the travel plans page
    And I should see "You are already logged in."
