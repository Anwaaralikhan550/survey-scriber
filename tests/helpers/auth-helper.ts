import { APIRequestContext } from '@playwright/test';

const API = 'http://localhost:3000/api/v1';

/** Sleep for given ms */
export function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/** Register a user, retrying on 429 with backoff */
export async function registerUser(
  request: APIRequestContext,
  data: { email: string; password: string; firstName: string; lastName: string; role?: string },
  maxRetries = 5,
): Promise<{ id: string; email: string; role: string }> {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    const res = await request.post(`${API}/auth/register`, { data });
    if (res.status() === 201) return res.json();
    if (res.status() === 409) {
      // Already exists - that's fine
      return { id: '', email: data.email, role: data.role || 'SURVEYOR' };
    }
    if (res.status() === 429) {
      // Rate limited - wait and retry
      const wait = (attempt + 1) * 15000; // 15s, 30s, 45s...
      console.log(`Rate limited on register (attempt ${attempt + 1}), waiting ${wait / 1000}s...`);
      await sleep(wait);
      continue;
    }
    throw new Error(`Register failed with status ${res.status()}: ${await res.text()}`);
  }
  throw new Error(`Register failed after ${maxRetries} retries due to rate limiting`);
}

/** Login a user, retrying on 429 with backoff */
export async function loginUser(
  request: APIRequestContext,
  email: string,
  password: string,
  maxRetries = 5,
): Promise<{ accessToken: string; refreshToken: string; user: { id: string; email: string; role: string } }> {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    const res = await request.post(`${API}/auth/login`, {
      data: { email, password },
    });
    if (res.status() === 200) return res.json();
    if (res.status() === 429) {
      const wait = (attempt + 1) * 15000;
      console.log(`Rate limited on login (attempt ${attempt + 1}), waiting ${wait / 1000}s...`);
      await sleep(wait);
      continue;
    }
    throw new Error(`Login failed with status ${res.status()}: ${await res.text()}`);
  }
  throw new Error(`Login failed after ${maxRetries} retries due to rate limiting`);
}

/** Register + login in one call */
export async function setupUser(
  request: APIRequestContext,
  opts: { email: string; password: string; firstName: string; lastName: string; role?: string },
): Promise<{ token: string; userId: string; refreshToken: string }> {
  await registerUser(request, opts);
  const login = await loginUser(request, opts.email, opts.password);
  return {
    token: login.accessToken,
    userId: login.user.id,
    refreshToken: login.refreshToken,
  };
}
