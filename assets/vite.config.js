import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";

// https://vitejs.dev/config/
export default defineConfig({
  root: "./src/",
  plugins: [vue()],
  build: {
    outDir: "../lib/build",
    rollupOptions: {
      preserveEntrySignatures: "exports-only",
      input: "./src/main.js",
      output: {
        dir: "./build",
        entryFileNames: "main.js",
        assetFileNames: "main.css",
      },
    },
  },
});
