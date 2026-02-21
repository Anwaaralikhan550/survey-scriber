import { test, expect } from '@playwright/test';

test.describe('User Registration Flow', () => {
  test.setTimeout(90000);

  test('should register a new user via the web UI successfully', async ({ page }) => {
    const uniqueId = Math.floor(Math.random() * 100000);
    const testData = {
      firstName: 'E2E',
      lastName: 'TestUser',
      email: `e2etest${uniqueId}@testmail.com`,
      password: 'Test1234!',
    };

    console.log(`Starting registration test with email: ${testData.email}`);

    // 1. Navigate to the registration page
    await page.goto('http://localhost:5000/#/register', {
      waitUntil: 'domcontentloaded',
      timeout: 30000,
    });

    // 2. Wait for Flutter to fully hydrate
    await page.waitForTimeout(8000);
    await page.screenshot({ path: 'test-results/registration-e2e/01-loaded.png', fullPage: true });
    expect(page.url()).toContain('/#/register');

    // Flutter Web (HTML renderer) renders visuals on a paint layer, not DOM elements.
    // Text input works by: click the visual field area → Flutter creates an <input>
    // in flt-text-editing-host → type into it via keyboard.
    //
    // IMPORTANT: We must NOT use .fill() on the editing host input because there
    // are 6 persistent editing inputs. Instead, after clicking the field area,
    // Flutter puts keyboard focus on the correct internal input. We just type
    // via page.keyboard which goes to the focused element.

    async function fillFlutterField(x: number, y: number, value: string, fieldName: string) {
      console.log(`Filling ${fieldName} at (${x}, ${y})...`);
      await page.mouse.click(x, y);
      await page.waitForTimeout(600);
      // Type directly via keyboard — Flutter routes it to the focused field
      await page.keyboard.type(value, { delay: 20 });
      await page.waitForTimeout(300);
      console.log(`  Done: ${fieldName}`);
    }

    // Field positions from screenshot (1280x720 viewport):
    // First Name: ~(497, 317)
    // Last Name: ~(778, 317)
    // Email: ~(637, 413)
    // Password: ~(637, 508)
    // Confirm Password: ~(637, 604)
    // Create Account button: ~(637, 693)

    await fillFlutterField(497, 317, testData.firstName, 'firstName');
    await fillFlutterField(778, 317, testData.lastName, 'lastName');
    await fillFlutterField(637, 413, testData.email, 'email');
    await fillFlutterField(637, 508, testData.password, 'password');
    await fillFlutterField(637, 604, testData.password, 'confirmPassword');

    // Click a neutral area to blur last field and trigger validation
    await page.mouse.click(300, 150);
    await page.waitForTimeout(1500);

    await page.screenshot({ path: 'test-results/registration-e2e/02-form-filled.png', fullPage: true });

    // Set up network monitoring before clicking submit
    const registrationPromise = page.waitForResponse(
      response =>
        response.url().includes('/auth/register') &&
        response.request().method() === 'POST',
      { timeout: 20000 },
    ).catch(() => null);

    // Click "Create Account" button
    console.log('Clicking Create Account button...');
    // From the screenshot, the button center is at ~(637, 693)
    // Try clicking it directly, then if that doesn't work, try scrolled position
    await page.mouse.click(637, 693);
    await page.waitForTimeout(1000);

    // If no response yet, try scrolling and clicking again
    // (button may be partially clipped at bottom of viewport)
    await page.mouse.wheel(0, 150);
    await page.waitForTimeout(300);
    await page.mouse.click(637, 600);
    await page.waitForTimeout(500);
    await page.screenshot({ path: 'test-results/registration-e2e/03-submitted.png', fullPage: true });

    // Wait for registration network response
    const registrationResponse = await registrationPromise;
    if (registrationResponse) {
      const status = registrationResponse.status();
      console.log(`Registration API response status: ${status}`);
      expect([200, 201]).toContain(status);
      const responseBody = await registrationResponse.json();
      console.log('Registration response:', JSON.stringify(responseBody));
    } else {
      console.log('No registration API response captured — checking form state...');
      await page.screenshot({ path: 'test-results/registration-e2e/04-debug.png', fullPage: true });
    }

    // Wait for navigation (auto-login + redirect)
    await page.waitForTimeout(6000);
    await page.screenshot({ path: 'test-results/registration-e2e/05-final.png', fullPage: true });

    // Verify success
    const finalUrl = page.url();
    console.log(`Final URL: ${finalUrl}`);
    // After registration + auto-login, Flutter may redirect to:
    // - /#/dashboard (explicit dashboard route)
    // - /#/login (if auto-login fails)
    // - / or /#/ (root route, which is the dashboard/home)
    // The key check: we should NOT still be on /#/register
    const leftRegisterPage = !finalUrl.includes('/register');
    expect(leftRegisterPage).toBeTruthy();

    console.log(`Registration E2E test completed. Email: ${testData.email}`);
  });
});
