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
  const state = reactive(info);
  console.log(state);
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

  ctx.handleSync(() => {
    // Synchronously invokes change listeners
    document.activeElement &&
      document.activeElement.dispatchEvent(
        new Event("change", { bubbles: true })
      );
  });

  const app = createApp(App, { modelValue: state, ctx });
  app.mount(ctx.root);
}
