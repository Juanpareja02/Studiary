// capacitor.config.ts
import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.studiary.app',
  appName: 'Studiary',
  webDir: 'out',
  server: {
    hostname: 'localhost',
    androidScheme: 'https'
  },
  plugins: {
    AdMob: {
      androidAppId: 'ca-app-pub-3048984943282265~8038523373',
      initializeOnStartup: true
    }
  }
};

export default config;
