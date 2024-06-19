<script>
import AuthTab from './components/AuthTab.vue'
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
        BodyTab,
        AuthTab
    },
    data() {
        return {
            showImportCurlModal: false,
            importedCurlCommand: "",
            grow: true,
            inline: true,
            currentTab: "params",
            selectedTab: 0,
            shouldStick: false,
            tabComponents: {
                params: BaseInputTable,
                auth: AuthTab,
                headers: BaseInputTable,
                body: BodyTab,
                steps: StepsTab,
                options: OptionsTab,
                plugins: PluginTab
            },
            methodDetails: {
                get: { color: "text-green-500", label: "GET" },
                post: { color: "text-yellow-500", label: "POST" },
                delete: { color: "text-red-500", label: "DEL" },
                options: { color: "text-purple-500", label: "OPT" },
                head: { color: "text-gray-500", label: "HEAD" },
                put: { color: "text-blue-500", label: "PUT" },
                patch: { color: "text-pink-500", label: "PATCH" }
            }
        };
    },
    computed: {
        bindingOptions() { return this.modelValue.bindingOptions },
        fields() { return this.modelValue.fields.queries[this.modelValue.fields.queryIndex]; },
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
    mounted() {
        this.checkWidth();
        window.addEventListener('resize', this.checkWidth);
    },
    beforeDestroy() {
        window.removeEventListener('resize', this.checkWidth);
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
        },
        queryAt(index) {
            return this.modelValue.fields.queries[index];
        },
        selectTab(index) {
            this.modelValue.fields.queryIndex = index;
            this.ctx.pushEvent("selectQueryTab", index);
        },
        addTab() {
            this.ctx.pushEvent("addQueryTab");
            this.$nextTick(() => {
                const container = this.$refs.scrollContainer;
                if (container) {
                    // Scroll to the rightmost edge of the container
                    setTimeout(() => {
                        const container = this.$refs.scrollContainer;
                        container.style.overflowX = 'hidden';
                        if (container) {
                            container.scrollLeft = container.scrollWidth;
                        }
                        container.style.overflowX = 'auto';
                    }, 50);
                }
            });
        },
        deleteTab(index) {
            this.ctx.pushEvent("deleteQueryTab", index);
        },
        checkWidth() {
            const totalWidth = this.$refs.tabsContainer.querySelector('.flex').offsetWidth;
            const containerWidth = this.$refs.tabsContainer.offsetWidth;
            if (totalWidth > containerWidth) {
                this.shouldStick = true;
            } else {
                this.shouldStick = false;
            }
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
        <div v-if="modelValue.fields.queries.length > 0" ref="tabsContainer"
            class="flex items-center border-gray-200 overflow-hidden">
            <div ref="scrollContainer" class="flex overflow-x-auto scrollbar-hide">
                <div class="flex">
                    <div v-for="(tab, index) in  modelValue.fields.queries " :key="index" :class="[
            'flex items-center relative min-w-24 max-w-36 cursor-pointer px-2 py-3 border-l truncate border-gray-300 group',
            modelValue.fields.queryIndex === index ? 'bg-blue-100 text-black font-bold border-t-2 border-t-blue-500' : 'bg-white border-t text-gray-500 mt-0.5'
        ]" @click.stop="selectTab(index)">
                        <span :class="['text-xs mr-2', this.methodDetails[queryAt(index).request_type].color]">
                            {{ this.methodDetails[queryAt(index).request_type].label }}
                        </span>
                        <span class="text-xs truncate">
                            {{ queryAt(index).url === '' ? 'Untitled Request' : queryAt(index).url }}
                        </span>
                        <!-- Delete Button -->
                        <button @click.stop="deleteTab(index)"
                            :class="['absolute right-2 top-1/2 transform -translate-y-1/2 hidden group-hover:block p-1 rounded-md',
            modelValue.fields.queryIndex === index ? 'bg-blue-100 hover:bg-blue-50 text-black font-bold' : 'bg-white hover:bg-gray-50 text-gray-500']"
                            style="width: 24px; height: 24px;">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                                stroke="currentColor" stroke-width="2" class="w-4 h-4">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                            </svg>
                        </button>
                    </div>
                </div>
            </div>
            <!-- Add Button -->
            <button @click="addTab" :class="[
            'mt-0.5 flex-none py-2 border-l px-4 rounded-tr hover:bg-gray-300 flex items-center justify-center',
            'bg-white text-gray-600 border-gray-200 w-12'  // Set a fixed width of 4rem and initial background to white
        ]" :style="{ 'position': shouldStick ? 'absolute' : 'static', 'right': '0' }">
                <!-- Plus Icon -->
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-6 h-6">
                    <path fill-rule="evenodd"
                        d="M12 3.75a.75.75 0 01.75.75v6.75h6.75a.75.75 0 010 1.5h-6.75v6.75a.75.75 0 01-1.5 0v-6.75H4.5a.75.75 0 010-1.5h6.75V4.5a.75.75 0 01.75-.75z"
                        clip-rule="evenodd" />
                </svg>
            </button>
        </div>
        <form v-if="modelValue.fields.queries.length > 0" class="h-[500px]" @change="handleFieldChange">
            <div class="h-full border-b border-x border-gray-300 rounded-b-md bg-[rgba(248,250,252,0.3)] pb-2">
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
                                <option v-for="      tab       in       tabs      " :key="tab"
                                    :selected="currentTab === tab">
                                    {{ tab.charAt(0).toUpperCase() + tab.slice(1) }}
                                </option>
                            </select>
                        </div>

                        <div class="hidden sm:block">
                            <div class="border-b border-gray-200">
                                <nav class="-mb-px flex" aria-label="Tabs">
                                    <button type="button" @click="currentTab = tab"
                                        v-for="      tab       in       tabs      " :key="tab"
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
        <div v-else class="flex flex-col items-center justify-center mt-12">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-6">
                <path
                    d="M5.625 3.75a2.625 2.625 0 1 0 0 5.25h12.75a2.625 2.625 0 0 0 0-5.25H5.625ZM3.75 11.25a.75.75 0 0 0 0 1.5h16.5a.75.75 0 0 0 0-1.5H3.75ZM3 15.75a.75.75 0 0 1 .75-.75h16.5a.75.75 0 0 1 0 1.5H3.75a.75.75 0 0 1-.75-.75ZM3.75 18.75a.75.75 0 0 0 0 1.5h16.5a.75.75 0 0 0 0-1.5H3.75Z" />
            </svg>

            <h3 class="mt-2 text-sm font-semibold text-gray-900">No Queries</h3>
            <p class="mt-1 text-sm text-gray-500">Get started by adding a new query.</p>
            <div class="mt-6 flex space-x-4">
                <button type="button" @click="addTab" title="Add new query"
                    class="inline-flex items-center justify-center gap-1.25 w-38 px-4 py-2 text-sm font-medium text-gray-800 bg-blue-100 rounded-md cursor-pointer transition-colors duration-300 ease-in-out hover:bg-gray-300 disabled:opacity-50 disabled:cursor-not-allowed">
                    <span>Add</span>
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5"
                        stroke="currentColor" class="w-6 h-6">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
                    </svg>
                </button>
            </div>
        </div>
    </div>
</template>

<style scoped>
.group-hover\:flex {
    display: none;
}

.group:hover .group-hover\:flex {
    display: flex;
}
</style>