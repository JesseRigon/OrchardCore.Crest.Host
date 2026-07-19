const { chromium } = require('playwright');

const baseUrl = process.env.BASE_URL || 'http://127.0.0.1:5014';
const headed = process.env.HEADED === '1';

const tenants = [
  { name: 'Default', prefix: '', username: 'admin', password: 'BlazingRules1!' }
];

async function login(context, tenant) {
  const response = await context.request.post(`${baseUrl}${tenant.prefix}/api/blazing/auth/login`, {
    data: { userName: tenant.username, password: tenant.password, rememberMe: false }
  });

  if (!response.ok()) {
    throw new Error(`Login failed for ${tenant.name}: ${response.status()} ${await response.text()}`);
  }
}

async function validateTenant(browser, tenant) {
  const context = await browser.newContext({ viewport: { width: 1440, height: 1000 } });
  const page = await context.newPage();

  page.on('console', message => console.log(`[browser:${tenant.name}:${message.type()}] ${message.text()}`));
  page.on('pageerror', error => console.log(`[browser:${tenant.name}:error] ${error.message}`));

  await login(context, tenant);
  await page.goto(`${baseUrl}${tenant.prefix}/Admin`, { waitUntil: 'domcontentloaded' });

  const adminShell = page.locator('.admin-shell');
  try {
    await adminShell.waitFor({ timeout: 30000 });
  } catch (error) {
    const debug = await page.evaluate(() => ({
      title: document.title,
      url: location.href,
      bodyText: document.body?.textContent?.replace(/\s+/g, ' ').trim().slice(0, 1000) || '',
      forms: Array.from(document.forms).map(form => ({ action: form.action, inputs: Array.from(form.elements).map(element => ({ id: element.id, name: element.getAttribute('name'), type: element.getAttribute('type') })) }))
    }));
    console.log(JSON.stringify({ tenant: tenant.name, debug }, null, 2));
    throw error;
  }

  await page.locator('.admin-menu-sidebar').waitFor({ timeout: 30000 });

  const result = await page.evaluate(() => ({
    title: document.title,
    url: location.href,
    hasShell: !!document.querySelector('.admin-shell'),
    hasSidebar: !!document.querySelector('.admin-menu-sidebar'),
    menuText: document.querySelector('.admin-menu-sidebar')?.textContent?.replace(/\s+/g, ' ').trim().slice(0, 300) || ''
  }));

  console.log(JSON.stringify({ tenant: tenant.name, ...result }, null, 2));

  if (!result.hasShell || !result.hasSidebar) {
    throw new Error(`Expected Blazing admin shell and sidebar for ${tenant.name}.`);
  }

  await context.close();
}

async function main() {
  const browser = await chromium.launch({ headless: !headed });

  for (const tenant of tenants) {
    await validateTenant(browser, tenant);
  }

  await browser.close();
}

main().catch(error => {
  console.error(error);
  process.exit(1);
});
