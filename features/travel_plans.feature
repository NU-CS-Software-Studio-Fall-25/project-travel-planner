# file: `features/04_travel_plans.feature`
Feature: Travel plans management
  Ensure users can create and view travel plans.

  Scenario: View existing travel plan
    Given a logged-in user exists with a travel plan named "City Break"
    When I visit the travel plans page
    Then I should see "City Break"