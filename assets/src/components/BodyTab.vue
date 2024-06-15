<script>
import Editor from './Editor.vue';
import BaseInputTable from './BaseInputTable.vue';
import prettier from 'prettier';
import parserBabel from 'prettier/parser-babel';
import parserHtml from 'prettier/parser-html';
import parserXml from 'prettier/parser-html';
import * as prettierPluginEstree from "prettier/plugins/estree";

export default {
    name: "BodyTab",
    components: {
        Editor,
        BaseInputTable
    },
    props: {
        modelValue: Object,
        ctx: Object,
        bindingOptions: Array
    },
    data() {
        return {
            radioButtons: ["none", "x-www-form-urlencoded", "raw"],
            currentButton: "none",
        };
    },
    methods: {
        handleFieldChange(_event) {
            this.ctx.pushEvent("update_fields", JSON.parse(JSON.stringify(this.modelValue)));
        },
        async formatContent() {
            const options = {};
            switch (this.modelValue.contentType) {
                case 'application/javascript':
                    options.parser = "babel";
                    options.plugins = [parserBabel, prettierPluginEstree];
                    break;
                case 'application/json':
                    options.parser = "json";
                    options.plugins = [parserBabel, prettierPluginEstree];
                    break;
                case 'text/html':
                    options.parser = 'html';
                    options.plugins = [parserHtml];
                    break;
                case 'application/xml':
                    options.parser = 'xml';
                    options.plugins = [parserXml];
            };
            try {
                const formatted = await prettier.format(this.modelValue.raw, options);
                this.modelValue.raw = formatted; // Update the raw content
                this.$emit('update:modelValue', { ...this.modelValue, raw: formatted }); // Emit update event
            } catch (error) {
                console.error('Error formatting content:', error);
            }
        }
    }
}
</script>

<template>
    <div class="h-[300px]">
        <fieldset class="mt-4 ml-4">
            <legend class="sr-only">Body Type</legend>
            <div class="sm:flex sm:items-center sm:space-x-3">
                <div class="flex items-center">
                    <input class="h-4 w-4 border-gray-300 text-indigo-600" type="radio" id="none" value="none"
                        v-model="modelValue.contentType">
                    <label class="ml-1 block text-sm font-medium leading-6 text-gray-900" for="none">None</label>

                    <input class="ml-2 h-4 w-4 border-gray-300 text-indigo-600" type="radio" id="urlencoded"
                        value="application/x-www-form-urlencoded" v-model="modelValue.contentType">
                    <label class="ml-1 block text-sm font-medium leading-6 text-gray-900"
                        for="urlencoded">x-www-form-urlencoded</label>

                    <input
                        v-if="modelValue.contentType == 'text/plain' || modelValue.contentType == 'none' || modelValue.contentType == 'application/x-www-form-urlencoded'"
                        class="ml-2 h-4 w-4 border-gray-300 text-indigo-600" type="radio" id="raw" value="text/plain"
                        v-model="modelValue.contentType">
                    <label
                        v-if="modelValue.contentType == 'text/plain' || modelValue.contentType == 'none' || modelValue.contentType == 'application/x-www-form-urlencoded'"
                        class="ml-1 block text-sm font-medium leading-6 text-gray-900" for="raw">Raw</label>
                    <input v-if="modelValue.contentType == 'application/javascript'"
                        class="ml-2 h-4 w-4 border-gray-300 text-indigo-600" type="radio" id="raw"
                        value="application/javascript" v-model="modelValue.contentType">
                    <label v-if="modelValue.contentType == 'application/javascript'" class=" ml-1 block text-sm
                        font-medium leading-6 text-gray-900" for="raw">Raw</label>
                    <input v-if="modelValue.contentType == 'application/json'"
                        class="ml-2 h-4 w-4 border-gray-300 text-indigo-600" type="radio" id="raw"
                        value="application/json" v-model="modelValue.contentType">
                    <label v-if="modelValue.contentType == 'application/json'"
                        class="ml-1 block text-sm font-medium leading-6 text-gray-900" for="raw">Raw</label>
                    <input v-if="modelValue.contentType == 'text/html'"
                        class="ml-2 h-4 w-4 border-gray-300 text-indigo-600" type="radio" id="raw" value="text/html"
                        v-model="modelValue.contentType">
                    <label v-if="modelValue.contentType == 'text/html'"
                        class="ml-1 block text-sm font-medium leading-6 text-gray-900" for="raw">Raw</label>
                    <input v-if="modelValue.contentType == 'elixir'"
                        class="ml-2 h-4 w-4 border-gray-300 text-indigo-600" type="radio" id="raw" value="elixir"
                        v-model="modelValue.contentType">
                    <label v-if="modelValue.contentType == 'elixir'"
                        class="ml-1 block text-sm font-medium leading-6 text-gray-900" for="raw">Raw</label>
                    <input v-if="modelValue.contentType == 'application/xml'"
                        class="ml-2 h-4 w-4 border-gray-300 text-indigo-600" type="radio" id="raw"
                        value="application/xml" v-model="modelValue.contentType">
                    <label v-if="modelValue.contentType == 'application/xml'"
                        class="ml-1 block text-sm font-medium leading-6 text-gray-900" for="raw">Raw</label>
                </div>
                <select
                    v-if="modelValue.contentType != 'application/x-www-form-urlencoded' && modelValue.contentType != 'none'"
                    v-model="modelValue.contentType" id="language" @change="handleRadioButtons"
                    class="mt-1 block pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md">
                    <option value="text/plain">Plaintext</option>
                    <option value="application/javascript">JavaScript</option>
                    <option value="application/json">JSON</option>
                    <option value="text/html">HTML</option>
                    <option value="application/xml">XML</option>
                    <option value="elixir">Elixir</option>
                </select>
                <div class="flex-grow"></div>
                <button
                    v-if="modelValue.contentType != 'application/x-www-form-urlencoded' && modelValue.contentType != 'none'"
                    type="button" @click="formatContent"
                    class="pr-12 items-center justify-center text-indigo-600 hover:text-blue-700 font-semibold text-sm">
                    Prettify
                </button>
            </div>
        </fieldset>
        <div class="h-full flex-grow">
            <div v-if="modelValue.contentType == 'none'" class="flex justify-center content-center h-full w-full">
                <p class="content-center">This request does not have a body</p>
            </div>
            <BaseInputTable v-else-if="modelValue.contentType == 'application/x-www-form-urlencoded'"
                v-bind:modelValue="modelValue.form" :bindingOptions="bindingOptions" :ctx="ctx" />
            <div v-else class="p-4">
                <Editor v-bind:modelValue="modelValue" @update:modelValue="handleFieldChange" :ctx="ctx" />
            </div>
        </div>

    </div>
</template>