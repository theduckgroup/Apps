import { defineConfig } from 'vite'
import path from "node:path";
import react from '@vitejs/plugin-react-swc'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig(() => {
  return {
    build: {
      outDir: '../Server/public',
      emptyOutDir: true
    },
    server: {
      port: 8022,
      proxy: {
        '/api': {
          target: 'http://localhost:8021',
          changeOrigin: true,
        },
        '/socketio': {
          target: 'http://localhost:8021',
          changeOrigin: true,
        },
      }
    },
    plugins: [
      react(),
      tailwindcss(),
    ],
    resolve: {
      alias: {
        'src': path.resolve(__dirname, 'src'), // Needed for `import from 'src/...'`
        // /esm/icons/index.mjs only exports the icons statically, so no separate chunks are created
        '@tabler/icons-react': '@tabler/icons-react/dist/esm/icons/index.mjs',
      },
    },
  }
})