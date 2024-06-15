<script>
import BaseInput from './components/BaseInput.vue'
import BaseInputTable from './components/BaseInputTable.vue'
import BaseSelect from './components/BaseSelect.vue'
import BodyTab from './components/BodyTab.vue'
import PluginTab from './components/PluginTab.vue'
import PluginSearch from './components/PluginSearch.vue'
import StepsTab from './components/StepsTab.vue'
import OptionsTab from './components/OptionsTab.vue'

export default {
    props: {
        modelValue: Object,
        ctx: Object,
        availablePlugins: Array
    },
    components: {
        BaseInput,
        BaseSelect,
        BaseInputTable,
        PluginTab,
        StepsTab,
        OptionsTab,
        PluginSearch,
        BodyTab
    },
    data() {
        return {
            showImportCurlModal: false,
            importedCurlCommand: "",
            grow: true,
            inline: true,
            currentTab: "params",
            tabComponents: {
                params: BaseInputTable,
                headers: BaseInputTable,
                body: BodyTab,
                steps: StepsTab,
                plugins: PluginTab,
                // options: OptionsTab,
            },
        };
    },

    computed: {
        bindingOptions() { return this.modelValue.bindingOptions },
        fields() { return this.modelValue.fields },
        missingDep() { return this.modelValue.missing_dep },
        curlError() { return this.modelValue.curlError },
        showCopiedMessage() { return this.modelValue.showCopiedMessage },
        tabs() {
            return Object.keys(this.tabComponents);
        },
        selectClass() {
            return this.fields.verbs.length > 1
                ? "input input--xs"
                : "pointer-events-none appearance-none bg-no-repeat bg-center bg-[length:10px_10px] pr-7 w-auto min-w-[150px] py-2 px-3 bg-gray-50 text-sm border border-gray-200 rounded-md text-gray-600"
        },
        currentTabComponent() {
            const componentConfig = this.tabComponents[this.currentTab];
            if (!componentConfig) return null;

            // Assuming `fields` includes dynamic data that should be passed as props
            const dynamicProps = this.fields[this.currentTab];
            return {
                ...componentConfig,
                modelValue: dynamicProps,
            };
        },
    },

    methods: {
        handleFieldChange(event) {
            this.ctx.pushEvent("update_fields", JSON.parse(JSON.stringify(this.fields)));
        },
        toggleImportCurlModal() {
            this.importedCurlCommand = "";
            this.showImportCurlModal = !this.showImportCurlModal;
        },
        importCurlCommand() {
            this.ctx.pushEvent("importCurlCommand", JSON.parse(JSON.stringify(this.importedCurlCommand)));
            this.showImportCurlModal = false;
        },
        copyAsCurl() {
            this.ctx.pushEvent("copyAsCurlCommand");
        },
        autoResize(event) {
            const textarea = event.target;
            textarea.style.height = 'auto';
            textarea.style.height = textarea.scrollHeight + 'px';  // Set the height to scroll height
        }
    }
}
</script>

<template>
    <div class="app">
        <div class="box box-warning" v-if="missingDep">
            <p>You must add the following dependency:</p>
            <pre><code>{{ missingDep }}</code></pre>
        </div>
        <div class="box box-warning" v-if="curlError">
            <p>Trouble importing from cURL! Invalid cURL command.</p>
        </div>
        <form class="h-[500px]" @change="handleFieldChange">
            <div class="h-full border border-gray-300 rounded-md bg-[rgba(248,250,252,0.3)] pb-2">
                <div class="flex flex-col justify-center">
                    <div class="flex items-center gap-2.5 ml-2.5">
                        <PluginSearch v-bind:showModal="showImportCurlModal" @close="toggleImportCurlModal">
                            <template v-slot:default>
                                <div class="p-5">
                                    <h2 class="text-lg font-bold mb-4">Import</h2>
                                    <form class="flex flex-col space-y-4">
                                        <label for="search" class="sr-only">Import</label>
                                        <textarea rows="1" spellcheck="false" wrap="off" id="curlImport"
                                            @input="autoResize" v-model="importedCurlCommand"
                                            class="px-4 block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 sm:text-sm sm:leading-6"
                                            placeholder="Paste cURL to import..." />
                                        <div class="flex justify-end">
                                            <button type="button" @click="importCurlCommand" title="Import from cURL"
                                                class="space-x-1 inline-flex items-center justify-center gap-1.25 w-38 px-4 py-2 text-sm font-medium text-gray-800 bg-blue-100 rounded-md cursor-pointer transition-colors duration-300 ease-in-out hover:bg-gray-300 disabled:opacity-50 disabled:cursor-not-allowed">
                                                <span>Import</span>
                                                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                                                    stroke-width="1.5" stroke="currentColor" class="size-4">
                                                    <path stroke-linecap="round" stroke-linejoin="round"
                                                        d="M3 16.5v2.25A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75V16.5M16.5 12 12 16.5m0 0L7.5 12m4.5 4.5V3" />
                                                </svg>
                                            </button>
                                        </div>
                                    </form>
                                </div>
                            </template>
                        </PluginSearch>
                    </div>
                </div>
                <div class="row header">
                    <BaseSelect name="request_type" label="" v-model="fields.request_type"
                        v-bind:selectClass="selectClass" :inline
                        :options="fields.verbs.map((name) => ({ label: name.toUpperCase(), value: name }))" />

                    <BaseInput name="variable" label=" Assign to " type="text" v-model="fields.variable"
                        inputClass="input input--xs input-text" :inline />

                    <!-- Icon buttons -->
                    <div class="flex justify-end space-x-2 ml-auto">
                        <button type="button" class="icon-button" title="Import from cURL"
                            @click="toggleImportCurlModal">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5"
                                stroke="currentColor" class="size-6 text-gray-400">
                                <path stroke-linecap="round" stroke-linejoin="round"
                                    d="M3 16.5v2.25A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75V16.5M16.5 12 12 16.5m0 0L7.5 12m4.5 4.5V3" />
                            </svg>
                        </button>
                        <div class="flex items-center space-x-2">
                            <div v-if="showCopiedMessage" class="text-sm font-medium text-gray-400">
                                Copied!
                            </div>
                            <button v-else type="button" class="icon-button" title="Copy as cURL" @click="copyAsCurl">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                                    stroke-width="1.5" stroke="currentColor" class="size-6 text-gray-400">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                        d="M15.75 17.25v3.375c0 .621-.504 1.125-1.125 1.125h-9.75a1.125 1.125 0 0 1-1.125-1.125V7.875c0-.621.504-1.125 1.125-1.125H6.75a9.06 9.06 0 0 1 1.5.124m7.5 10.376h3.375c.621 0 1.125-.504 1.125-1.125V11.25c0-4.46-3.243-8.161-7.5-8.876a9.06 9.06 0 0 0-1.5-.124H9.375c-.621 0-1.125.504-1.125 1.125v3.5m7.5 10.375H9.375a1.125 1.125 0 0 1-1.125-1.125v-9.25m12 6.625v-1.875a3.375 3.375 0 0 0-3.375-3.375h-1.5a1.125 1.125 0 0 1-1.125-1.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H9.75" />
                                </svg>
                            </button>
                        </div>
                    </div>

                </div>

                <div>
                    <div class="row mixed-row">
                        <BaseInput name="url" label="URL" type="text" v-model="fields.url" inputClass="input" :grow />
                    </div>
                    <!-- Tabs -->
                    <div>
                        <div class="sm:hidden">
                            <label for="tabs" class="sr-only">Select a tab</label>
                            <select id="tabs" name="tabs"
                                class="block w-full rounded-md border-gray-300 focus:border-indigo-500 focus:ring-indigo-500">
                                <option v-for="tab in tabs" :key="tab" :selected="currentTab === tab">
                                    {{ tab.charAt(0).toUpperCase() + tab.slice(1) }}
                                </option>
                            </select>
                        </div>

                        <div class="hidden sm:block">
                            <div class="border-b border-gray-200">
                                <nav class="-mb-px flex" aria-label="Tabs">
                                    <button type="button" @click="currentTab = tab" v-for="tab in tabs" :key="tab"
                                        :class="[currentTab === tab ? 'border-indigo-500 text-indigo-600' : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700', 'w-1/4 border-b-2 py-4 px-1 text-center text-sm font-medium']"
                                        :aria-current="currentTab === tab ? 'page' : undefined">
                                        {{ tab.charAt(0).toUpperCase() + tab.slice(1) }}
                                    </button>
                                </nav>
                            </div>
                        </div>
                    </div>

                    <component :availablePlugins="this.availablePlugins" :ctx="this.ctx" :is="currentTabComponent"
                        v-bind:modelValue="fields[currentTab]" v-bind:currentTab="currentTab"
                        :bindingOptions="bindingOptions" @update:modelValue="handleFieldChange"
                        v-if="currentTabComponent">
                    </component>
                </div>
            </div>
        </form>
    </div>
</template>