// next.config.ts
import type {NextConfig} from 'next';

const nextConfig: NextConfig = {
  output: 'export', // <- Añade esta línea
  typescript: {
    ignoreBuildErrors: true,
  },
  eslint: {
    ignoreDuringBuilds: true,
  },
  images: {
    remotePatterns: [
      // ... (el resto de tu configuración)
    ],
    unoptimized: true // <- Y añade esta línea
  },
};

export default nextConfig;
