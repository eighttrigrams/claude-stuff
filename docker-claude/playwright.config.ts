import { defineConfig } from "@playwright/test";
import { defineBddConfig } from "playwright-bdd";

const port = process.env.PORT || "8080";

const testDir = defineBddConfig({
  features: "./e2e/features",
  steps: "./e2e/steps/*.ts",
});

export default defineConfig({
  testDir,
  timeout: 30_000,
  workers: 1,
  expect: { timeout: 5_000 },
  use: {
    baseURL: `http://localhost:${port}`,
    headless: true,
    launchOptions: {
      executablePath: process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH || "/usr/bin/chromium",
      args: ["--no-sandbox", "--disable-dev-shm-usage"],
    },
  },
  projects: [{ name: "chromium", use: { browserName: "chromium" } }],
  webServer: {
    command: "clj -M -m poc.server",
    url: `http://localhost:${port}`,
    timeout: 60_000,
    reuseExistingServer: true,
  },
});
