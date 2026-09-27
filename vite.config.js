import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/gapi': {
        target: 'https://3100.api.green-api.com',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/gapi/, ''),
      },
    },
  },
})
