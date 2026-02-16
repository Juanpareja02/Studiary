// capacitor.config.ts
import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.studiary.app',
  appName: 'Studiary',
  webDir: 'out', // <- ¡Esta es la línea clave!
  bundledWebRuntime: false,
  server: {
    hostname: 'localhost',
    androidScheme: 'https'
  }
};

export default config;
