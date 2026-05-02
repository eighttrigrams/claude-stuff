import { expect } from "@playwright/test";
import { createBdd } from "playwright-bdd";

const { Given, Then } = createBdd();

Given("I am on the app", async ({ page }) => {
  await page.goto("/");
  await page.waitForLoadState("load");
});

Then("I should see the heading {string}", async ({ page }, text: string) => {
  await expect(page.locator("h1")).toContainText(text);
});

Then("the page title should be {string}", async ({ page }, title: string) => {
  await expect(page).toHaveTitle(title);
});

Then("I should see the paragraph {string}", async ({ page }, text: string) => {
  await expect(page.locator("p")).toContainText(text);
});
