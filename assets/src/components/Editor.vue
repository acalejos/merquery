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
        case 'elixir':
            return elixir();
        default:
            return [];
    }
};
const props = defineProps({ modelValue: Object, ctx: Object });
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
    <code-mirror ref="cm" v-model="modelValue.raw" basic :lang="lang" @change="onChange" :extensions="[baseTheme]" />
</template>