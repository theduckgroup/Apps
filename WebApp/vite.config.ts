import { defineConfig } from 'vite'
import path from 'node:path'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import { visualizer } from 'rollup-plugin-visualizer'

// @vitejs/plugin-react-swc does not yet support react compiler
// https://www.reddit.com/r/react/comments/1m4mxgg/react_compiler_swc_vite/

export default defineConfig(() => {
  return {
    build: {
      outDir: '../Server/public',
      emptyOutDir: true,
      chunkSizeWarningLimit: 2000
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
      react({
        babel: {
          plugins: ['babel-plugin-react-compiler'],
        },
      }),
      tailwindcss(),
      visualizer({
        filename: 'tmp/rollup-visualiser-stats.html'
      }),
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