import legacy from '@vitejs/plugin-legacy';
import react from '@vitejs/plugin-react';
import { defineConfig } from 'vitest/config';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react(), legacy()],
  test: {
    environment: 'jsdom',
    setupFiles: './src/setupTests.ts',
    // Playwright e2e specs live in e2e/.
    include: ['src/**/*.test.{ts,tsx}'],
    /*
     * Default is 5000ms. These tests mount real Ionic components (ion-datetime,
     * ion-input, ion-refresher) in jsdom, and with 28 files running in parallel a
     * heavy itinerary test intermittently blew the 5s per-test budget on a loaded
     * machine — it passed in isolation and failed ~1 run in 4. Raising the budget
     * is the honest fix; the alternative was re-running CI until it went green.
     */
    testTimeout: 20000,
    hookTimeout: 20000,
  },
});
