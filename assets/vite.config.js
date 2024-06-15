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
        manualChunks: {
          codemirror: [
            "vue-codemirror6",
            "codemirror",
            "@codemirror/autocomplete",
            "@codemirror/commands",
            "@codemirror/language",
            "@codemirror/lint",
            "@codemirror/search",
            "@codemirror/state",
            "@codemirror/view",
          ],
          "codemirror-lang": [
            "@codemirror/lang-html",
            "@codemirror/lang-javascript",
          ],
          // ...
        },
        dir: "./build",
        entryFileNames: "main.js",
        assetFileNames: "main.css",
      },
    },
  },
});
