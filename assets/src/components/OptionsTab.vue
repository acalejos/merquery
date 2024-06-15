<script>
import Editor from './Editor.vue';
export default {
    name: "BodyTab",
    components: {
        Editor
    },
    props: {
        modelValue: Object,
        ctx: Object
    }
}
</script>
<template>
    <div class="p-4">
        <div class="w-full p-3 mb-2 bg-gray-100 border border-gray-300 text-gray-700 rounded">
            <p>Accepts an Elixir Keyword list to add to the top-level Req options. You can use previously defined
                variables.</p>
        </div>
        <Editor v-bind:modelValue="modelValue" :ctx="ctx" target="options" />
    </div>
</template>