import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Development: the editor and the API share one origin through this proxy, so the HttpOnly cookie works
// exactly as it will behind nginx in production. Override the target with EDITOR_API_TARGET.
const target = process.env.EDITOR_API_TARGET || 'http://localhost:3099';

export default defineConfig({
  plugins: [react()],
  server: { port: 5174, strictPort: true, proxy: { '/api': { target, changeOrigin: false } } },
  preview: { port: 5174, strictPort: true, proxy: { '/api': { target, changeOrigin: false } } },
  build: { sourcemap: false },
});
