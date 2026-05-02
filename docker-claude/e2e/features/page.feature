Feature: Page

  Scenario: User sees the welcome page
    Given I am on the app
    Then I should see the heading "Hello from Headless Claude"
    And the page title should be "POC"
    And I should see the paragraph "Served by a Java HttpServer inside Docker."
