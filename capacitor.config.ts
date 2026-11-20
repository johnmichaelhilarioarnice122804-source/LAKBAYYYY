import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'ph.lakbaylokal.app',
  appName: 'LAKBAY LOKAL',
  webDir: 'dist',
  /**
   * The LAKBAY LOKAL API runs as plain HTTP on a trusted local network.
   *
   * The WebView keeps Capacitor's DEFAULT https://localhost origin. HTTP API
   * calls are instead unblocked with `allowMixedContent`. That is a
   * development-only allowance and pairs with the debug-only network security
   * config: release builds still forbid cleartext at the platform level, so a
   * released app cannot talk to a plain-HTTP server either way.
   */
  android: {
    allowMixedContent: true,
  },
};

export default config;
