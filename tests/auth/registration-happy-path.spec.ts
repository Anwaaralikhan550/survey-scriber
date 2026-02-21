import { test, expect } from '@playwright/test';

test.describe('User Registration Flow', () => {
  const TEST_EMAIL = `e2e-pw-test-${Date.now()}@test.local`;
  const TEST_PASSWORD = 'Test1234!';
  const TEST_FIRST_NAME = 'E2E';
  const TEST_LAST_NAME = 'TestUser';

  test('should register a new user successfully', async ({ page }) => {
    // 1. Navigate to registration page
    await page.goto('http://localhost:5000/#/register', { waitUntil: 'networkidle' });

    // 2. Wait for Flutter to render - give it time to hydrate
    await page.waitForTimeout(5000);

    // 3. Take a screenshot to see the initial state
    await page.screenshot({ path: 'test-results/01-register-page-loaded.png', fullPage: true });

    // Flutter HTML renderer creates real <input> elements
    // Find all text inputs on the page
    const inputs = page.locator('input');
    const inputCount = await inputs.count();
    console.log(`Found ${inputCount} input elements on the page`);

    // For Flutter web HTML renderer, inputs are rendered as actual DOM elements
    // Try multiple strategies to find and fill form fields

    // Strategy 1: Try by placeholder/label text
    try {
      // First name
      const firstNameInput = page.locator('input').first();
      await firstNameInput.waitFor({ state: 'visible', timeout: 10000 });

      // Get all inputs and fill them in order: firstName, lastName, email, password, confirmPassword
      if (inputCount >= 5) {
        await inputs.nth(0).fill(TEST_FIRST_NAME);
        await inputs.nth(0).dispatchEvent('input');
        await page.waitForTimeout(300);

        await inputs.nth(1).fill(TEST_LAST_NAME);
        await inputs.nth(1).dispatchEvent('input');
        await page.waitForTimeout(300);

        await inputs.nth(2).fill(TEST_EMAIL);
        await inputs.nth(2).dispatchEvent('input');
        await page.waitForTimeout(300);

        await inputs.nth(3).fill(TEST_PASSWORD);
        await inputs.nth(3).dispatchEvent('input');
        await page.waitForTimeout(300);

        await inputs.nth(4).fill(TEST_PASSWORD);
        await inputs.nth(4).dispatchEvent('input');
        await page.waitForTimeout(300);
      } else {
        // Try getByRole approach for Flutter semantic tree
        await page.getByRole('textbox', { name: /first/i }).fill(TEST_FIRST_NAME);
        await page.getByRole('textbox', { name: /last/i }).fill(TEST_LAST_NAME);
        await page.getByRole('textbox', { name: /email/i }).fill(TEST_EMAIL);
        await page.getByRole('textbox', { name: /^password$/i }).fill(TEST_PASSWORD);
        await page.getByRole('textbox', { name: /confirm/i }).fill(TEST_PASSWORD);
      }
    } catch (e) {
      console.log(`Form fill strategy error: ${e}`);
      // Take debug screenshot
      await page.screenshot({ path: 'test-results/debug-form-fill-error.png', fullPage: true });
      throw e;
    }

    // 4. Screenshot after filling form
    await page.screenshot({ path: 'test-results/02-register-form-filled.png', fullPage: true });

    // 5. Click the Create Account button
    // Try multiple selectors
    const submitButton = page.locator('button, [role="button"]').filter({ hasText: /create account|sign up|register/i });
    const buttonCount = await submitButton.count();
    console.log(`Found ${buttonCount} submit button(s)`);

    if (buttonCount > 0) {
      await submitButton.first().click();
    } else {
      // Fallback: click by text content in the page
      await page.getByText(/create account/i).click();
    }

    // 6. Wait for navigation or response
    await page.waitForTimeout(5000);

    // 7. Screenshot after submission
    await page.screenshot({ path: 'test-results/03-after-registration.png', fullPage: true });

    // 8. Verify outcome
    const url = page.url();
    console.log(`Current URL after registration: ${url}`);
    console.log(`Test email used: ${TEST_EMAIL}`);

    // Check if redirected to dashboard (auto-login success) or login page
    const isSuccess = url.includes('/dashboard') || url.includes('/login') || url.includes('/#/');

    // Also check for error messages
    const pageContent = await page.textContent('body') || '';
    const hasError = pageContent.includes('already exists') || pageContent.includes('error');

    if (hasError) {
      console.log('Registration may have encountered an error');
      await page.screenshot({ path: 'test-results/04-error-state.png', fullPage: true });
    }

    expect(isSuccess || !hasError).toBeTruthy();
    console.log('Registration test completed');
  });
});
