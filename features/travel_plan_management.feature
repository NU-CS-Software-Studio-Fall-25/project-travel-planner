# File: `features/travel_plan_management.feature`
Feature: Travel plan create and manage
  As a logged in user
  I want to save and delete travel plans
  So I can keep plans generated from recommendations

  Background:
    Given I am logged in as a user who can generate recommendations

  Scenario: Create a travel plan from new form (happy)
    When I create a new travel plan with minimal valid data
    Then the travel plan should be saved and visible in the list

  Scenario: Fail to create travel plan with missing name (sad)
    When I attempt to create a travel plan with missing required fields
    Then I should see validation errors and remain on the new form

  Scenario: Delete a travel plan (happy)
    Given a travel plan exists for my account
    When I delete the travel plan
    Then it should no longer appear in my plans list

  Scenario: Attempt to delete another user's plan (sad)
    Given another user has a travel plan
    When I attempt to delete that travel plan
    Then I should be prevented and see an access error