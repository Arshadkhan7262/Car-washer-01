import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    host: '0.0.0.0', // Bind to all interfaces for network access
    port: 3001,
    open: true,
    strictPort: true, // Exit if port is already in use
  },
  preview: {
    host: '127.0.0.1', // Only bind to localhost for preview
    port: 3001,
    strictPort: true,
  },
})

