# File: `features/travel_recommendations.feature`
Feature: Travel recommendations generation
  As a logged-in user
  I want to generate travel recommendations from preferences

  Scenario: Generate recommendations from preferences (happy)
    Given I am logged in as a user who can generate recommendations
    When I submit travel preferences for recommendations
    Then I should see a recommendations list

  Scenario: Respect free-tier generation limit (sad)
    Given the user has used up their free generation allowance
    When I attempt to generate recommendations
    Then I should see a limit reached message