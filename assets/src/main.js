import "./main.css";
import { createApp, reactive } from "vue";

import App from "./App.vue";

export async function init(ctx, info) {
  ctx.importCSS("main.css");
  ctx.importCSS(
    "https://fonts.googleapis.com/css2?family=Inter:wght@400;500&display=swap"
  );
  ctx.importCSS(
    "https://fonts.googleapis.com/css2?family=JetBrains+Mono&display=swap"
  );
  const available_plugins = info.available_plugins;
  const state = reactive({
    ...info,
    showCopiedMessage: false,
    curlError: false,
    bindingOptions: [],
  });
  function setValues(fields) {
    for (const field in fields) {
      if (state.fields.hasOwnProperty(field)) {
        state.fields[field] = fields[field];
      } else {
        console.warn(`Field ${field} does not exist in the state.`);
      }
    }
  }
  ctx.handleEvent("update", ({ fields }) => {
    setValues(fields);
  });

  ctx.handleEvent("missing_dep", ({ dep }) => {
    app.missingDep = dep;
  });

  ctx.handleEvent("curlError", ({}) => {
    state.curlError = true;
    setTimeout(() => {
      state.curlError = false;
    }, 3000);
  });

  ctx.handleEvent("set_available_bindings", ({ available_bindings }) => {
    state.bindingOptions = available_bindings;
  });

  ctx.handleEvent("copyAsCurlCommand", async (curlCommand) => {
    if (!navigator.clipboard) {
      console.error("Clipboard API is not available.");
      return;
    }
    try {
      await navigator.clipboard.writeText(curlCommand);
      state.showCopiedMessage = true;
      setTimeout(() => {
        state.showCopiedMessage = false;
      }, 1500);
    } catch (err) {
      console.error("Failed to copy:", err);
    }
  });

  ctx.handleSync(() => {
    // Synchronously invokes change listeners
    document.activeElement &&
      document.activeElement.dispatchEvent(
        new Event("change", { bubbles: true })
      );
  });

  const app = createApp(App, {
    modelValue: state,
    ctx,
    availablePlugins: available_plugins,
  });
  app.mount(ctx.root);
}
