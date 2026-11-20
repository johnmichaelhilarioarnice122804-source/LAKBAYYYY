import { defineConfig, devices } from '@playwright/test';
import fs from 'node:fs';

import {
  API_ORIGIN,
  E2E_DB_PATH,
  E2E_DB_URL,
  E2E_WEB_DIR,
  REPO_ROOT,
  resolvePythonExecutable,
  SERVER_DIR,
  WEB_ORIGIN,
} from './e2e/support/paths';

/*
 * Remove the throwaway database before the API webServer opens it. The file
 * lives in the temp directory across runs, and `create_all()` cannot add columns
 * to an existing table, so a schema change (like province-first itineraries)
 * would otherwise fail against the stale file. This runs in the Playwright
 * runner, before webServer tasks start, so no process is holding the file yet.
 */
if (process.env.TEST_WORKER_INDEX === undefined) {
  for (const suffix of ['', '-wal', '-shm']) {
    fs.rmSync(`${E2E_DB_PATH}${suffix}`, { force: true });
  }
}

const isCI = Boolean(process.env.CI);

/*
 * Two webServers, one lifecycle:
 *   1. FastAPI on 127.0.0.1:8000 with a throwaway SQLite database (temp dir).
 *   2. The Vite preview build on localhost:4173, rebuilt in development mode so
 *      the app uses the VITE_API_BASE_URL fallback and never sits in "Blocked".
 *
 * Playwright starts plugin/webServer tasks before globalSetup, so the API and
 * preview are already healthy when globalSetup resets and seeds the database.
 */
export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: isCI,
  retries: isCI ? 1 : 0,
  // One worker: registrations and itinerary writes share a single SQLite file.
  workers: 1,
  reporter: isCI ? [['github'], ['html', { open: 'never' }]] : 'list',
  timeout: 45_000,
  expect: { timeout: 10_000 },
  globalSetup: './e2e/global-setup.ts',
  use: {
    baseURL: WEB_ORIGIN,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    actionTimeout: 10_000,
    navigationTimeout: 20_000,
  },
  projects: [
    {
      name: 'Microsoft Edge',
      use: {
        ...devices['Pixel 7'],
        // Chromium is not installed in this environment; Edge is.
        channel: 'msedge',
      },
    },
  ],
  webServer: [
    {
      name: 'API',
      command: `"${resolvePythonExecutable()}" -m uvicorn app.main:app --host 127.0.0.1 --port 8000`,
      cwd: SERVER_DIR,
      url: `${API_ORIGIN}/api/health`,
      reuseExistingServer: false,
      timeout: 120_000,
      env: {
        APP_ENV: 'development',
        DATABASE_URL: E2E_DB_URL,
        DISCOVERY_ENABLED: 'false',
        CORS_ORIGINS: `${WEB_ORIGIN},http://127.0.0.1:4173`,
      },
      stdout: 'ignore',
      stderr: 'pipe',
    },
    {
      name: 'Frontend',
      /*
       * Build into a private temp directory. The shared dist/ is rebuilt by
       * other tooling; a concurrent production build there (NODE_ENV is not
       * inherited) would remove the VITE_API_BASE_URL fallback mid-run.
       */
      command: `npx vite build --mode development --outDir "${E2E_WEB_DIR}" --emptyOutDir && npx vite preview --outDir "${E2E_WEB_DIR}" --port 4173 --strictPort`,
      cwd: REPO_ROOT,
      url: WEB_ORIGIN,
      reuseExistingServer: false,
      timeout: 300_000,
      env: {
        NODE_ENV: 'development',
        VITE_API_BASE_URL: API_ORIGIN,
      },
      stdout: 'ignore',
      stderr: 'pipe',
    },
  ],
});
