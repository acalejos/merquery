<script setup>
import JSON5 from 'json5'
import CodeMirror from 'vue-codemirror6';
import { ref, defineComponent, toRefs, computed } from 'vue';
import { EditorView } from '@codemirror/view';
import { javascript } from '@codemirror/lang-javascript';
import { json } from '@codemirror/lang-json';
import { html } from '@codemirror/lang-html';
import { xml } from '@codemirror/lang-xml';
import { elixir } from 'codemirror-lang-elixir';
import { oneDark } from '@codemirror/theme-one-dark';

const getLanguageExtension = (language) => {
    switch (language) {
        case 'application/javascript':
            return javascript();
        case 'application/json':
            return json();
        case 'text/html':
            return html();
        case 'application/xml':
            return xml();
        case 'text/plain':
            return [];
        case 'elixir':
            return elixir();
        default:
            return [];
    }
};

const formatCode = (code, language) => {
    switch (language) {
        case 'application/javascript':
            return prettier.format(code, { parser: 'babel', plugins: [parserBabel] });
        case 'application/json':
            return prettier.format(code, { parser: 'json', plugins: [parserBabel] });
        case 'text/html':
            return prettier.format(code, { parser: 'html', plugins: [parserHtml] });
        case 'application/xml':
            return prettier.format(code, { parser: 'xml', plugins: [parserXml] });
        default:
            return code;
    }
};
const props = defineProps({ dark: Boolean, modelValue: Object, ctx: Object });
const cm = ref();
const lang = computed(() => getLanguageExtension(props.modelValue.contentType));
const dark = ref(
    window.matchMedia('(prefers-color-scheme: dark)').matches
);

const onChange = (_state) => {
    switch (props.modelValue.contentType) {
        case "application/json":
            try {
                const parsedObject = JSON5.parse(props.modelValue.raw);
                const jsonStringified = JSON.stringify(parsedObject, null, 2);
                props.ctx.pushEvent("updateRaw", jsonStringified);
            } catch {
                props.ctx.pushEvent("updateRaw", props.modelValue.raw);
            }
            break;
        default:
            props.ctx.pushEvent("updateRaw", props.modelValue.raw);
    }
};

const baseTheme = EditorView.baseTheme({
    '&': {
        height: '200px',
    },
    '.cm-scroller': {
        overflow: 'auto',
    },
    '.cm-content': {
        height: '100%',
    },
    '.cm-wrap': {
        height: '100%',
    },
});
</script>

<template>
    <code-mirror ref="cm" v-model="modelValue.raw" basic :dark="false" :lang="lang" @change="onChange"
        :extensions="[baseTheme]" />
</template>

<style scoped>
#editor {
    height: 100%;
}
</style>