// Generated from: e2e/features/page.feature
import { test } from "playwright-bdd";

test.describe('Page', () => {

  test('User sees the welcome page', async ({ Given, Then, And, page }) => { 
    await Given('I am on the app', null, { page }); 
    await Then('I should see the heading "Hello from Headless Claude"', null, { page }); 
    await And('the page title should be "POC"', null, { page }); 
    await And('I should see the paragraph "Served by a Java HttpServer inside Docker."', null, { page }); 
  });

});

// == technical section ==

test.use({
  $test: [({}, use) => use(test), { scope: 'test', box: true }],
  $uri: [({}, use) => use('e2e/features/page.feature'), { scope: 'test', box: true }],
  $bddFileData: [({}, use) => use(bddFileData), { scope: "test", box: true }],
});

const bddFileData = [ // bdd-data-start
  {"pwTestLine":6,"pickleLine":3,"tags":[],"steps":[{"pwStepLine":7,"gherkinStepLine":4,"keywordType":"Context","textWithKeyword":"Given I am on the app","stepMatchArguments":[]},{"pwStepLine":8,"gherkinStepLine":5,"keywordType":"Outcome","textWithKeyword":"Then I should see the heading \"Hello from Headless Claude\"","stepMatchArguments":[{"group":{"start":25,"value":"\"Hello from Headless Claude\"","children":[{"start":26,"value":"Hello from Headless Claude","children":[{"children":[]}]},{"children":[{"children":[]}]}]},"parameterTypeName":"string"}]},{"pwStepLine":9,"gherkinStepLine":6,"keywordType":"Outcome","textWithKeyword":"And the page title should be \"POC\"","stepMatchArguments":[{"group":{"start":25,"value":"\"POC\"","children":[{"start":26,"value":"POC","children":[{"children":[]}]},{"children":[{"children":[]}]}]},"parameterTypeName":"string"}]},{"pwStepLine":10,"gherkinStepLine":7,"keywordType":"Outcome","textWithKeyword":"And I should see the paragraph \"Served by a Java HttpServer inside Docker.\"","stepMatchArguments":[{"group":{"start":27,"value":"\"Served by a Java HttpServer inside Docker.\"","children":[{"start":28,"value":"Served by a Java HttpServer inside Docker.","children":[{"children":[]}]},{"children":[{"children":[]}]}]},"parameterTypeName":"string"}]}]},
]; // bdd-data-end