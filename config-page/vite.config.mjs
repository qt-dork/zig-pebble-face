import { defineConfig } from 'vite';

export default defineConfig({
  root: '.',
  base: '/royale/',
  build: {
    outDir: 'dist'
  },
  server: {
    port: 3000,
    open: '/index.html'
  },
  esbuild: {
    jsx: 'automatic',
    loader: 'tsx'
  },
  optimizeDeps: {
    include: ['react', 'react-dom']
  }
});
