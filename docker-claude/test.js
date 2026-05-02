const { chromium } = require('playwright-core');

const URL = process.env.URL || 'http://localhost:8080/';
const CHROMIUM = process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH || '/usr/bin/chromium';

let passed = 0;
let failed = 0;

function assert(condition, message) {
  if (condition) {
    console.log(`  ✓ ${message}`);
    passed++;
  } else {
    console.error(`  ✗ ${message}`);
    failed++;
  }
}

(async () => {
  const browser = await chromium.launch({
    executablePath: CHROMIUM,
    args: ['--no-sandbox', '--disable-dev-shm-usage'],
  });
  const page = await browser.newPage();

  try {
    await page.goto(URL, { waitUntil: 'load' });

    console.log('\nPage load');
    assert(page.url().startsWith(URL), `navigated to ${URL}`);

    const title = await page.title();
    assert(title === 'POC', `title is "POC" (got "${title}")`);

    console.log('\nContent');
    const heading = await page.textContent('#hello');
    assert(heading === 'Hello from Headless Claude', `heading reads "Hello from Headless Claude"`);

    const para = await page.textContent('p');
    assert(para === 'Served by a Java HttpServer inside Docker.', `paragraph text is correct`);

    console.log('\nLayout');
    const h1 = await page.$('h1');
    assert(h1 !== null, 'h1 element exists in the DOM');

    const bodyBg = await page.$eval('body', el =>
      getComputedStyle(el).backgroundColor
    );
    assert(bodyBg === 'rgb(11, 19, 43)', `body has dark background (${bodyBg})`);

    await page.screenshot({ path: 'screenshot.png', fullPage: true });
    console.log('\nScreenshot saved to screenshot.png');

  } finally {
    await browser.close();
  }

  console.log(`\n${passed + failed} checks: ${passed} passed, ${failed} failed`);
  if (failed > 0) process.exit(1);
})().catch(err => {
  console.error(err);
  process.exit(1);
});
