const { chromium } = require('playwright-core');

(async () => {
  const url = process.env.URL || 'http://localhost:8080/';
  const out = process.env.OUT || 'screenshot.png';
  const browser = await chromium.launch({
    executablePath: process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH || '/usr/bin/chromium',
    args: ['--no-sandbox', '--disable-dev-shm-usage'],
  });
  const page = await browser.newPage();
  await page.goto(url, { waitUntil: 'load' });
  const heading = await page.textContent('#hello');
  console.log('Heading text:', heading);
  if (heading !== 'Hello from Headless Claude') {
    await browser.close();
    console.error('Assertion failed: unexpected heading');
    process.exit(1);
  }
  await page.screenshot({ path: out, fullPage: true });
  console.log('Screenshot written to', out);
  await browser.close();
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
