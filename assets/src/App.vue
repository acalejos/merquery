<script>
import BaseInput from './components/BaseInput.vue'
import BaseInputTable from './components/BaseInputTable.vue'
import BaseSelect from './components/BaseSelect.vue'
import PluginTab from './components/PluginTab.vue'
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
        OptionsTab
    },
    data() {
        return {
            grow: true,
            inline: true,
            currentTab: "params",
            tabComponents: {
                params: BaseInputTable,
                headers: BaseInputTable,
                plugins: PluginTab,
                steps: StepsTab,
                options: OptionsTab,
            },
        };
    },

    computed: {
        fields() { return this.modelValue.fields },
        missingDep() { return this.modelValue.missing_dep },
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
        handleFieldChange(_event) {
            this.ctx.pushEvent("update_fields", JSON.parse(JSON.stringify(this.fields)));
        },
    }
}
</script>

<template>
    <div class="app">
        <div class="box box-warning" v-if="missingDep">
            <p>You must add the following dependency:</p>
            <pre><code>{{ missingDep }}</code></pre>
        </div>
        <form @change="handleFieldChange">
            <div class="border border-gray-300 rounded-md bg-[rgba(248,250,252,0.3)] pb-2 min-h-[500px]">
                <div class="row header">
                    <BaseSelect name="request_type" label="" v-model="fields.request_type"
                        v-bind:selectClass="selectClass" :inline
                        :options="fields.verbs.map((name) => ({ label: name.toUpperCase(), value: name }))" />

                    <BaseInput name="variable" label=" Assign to " type="text" v-model="fields.variable"
                        inputClass="input input--xs input-text" :inline />
                </div>

                <div class="h-full">
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
                                        <!-- <span v-if=""
                                            :class="[currentTab ? 'bg-indigo-100 text-indigo-600' : 'bg-gray-100 text-gray-900', 'ml-3 hidden rounded-full py-0.5 px-2.5 text-xs font-medium md:inline-block']">{{
            tab.count }}</span> -->
                                    </button>
                                </nav>
                            </div>
                        </div>
                    </div>

                    <component :availablePlugins="this.availablePlugins" :ctx="this.ctx" :is="currentTabComponent"
                        v-bind:modelValue="fields[currentTab]" v-bind:currentTab="currentTab"
                        @update:modelValue="handleFieldChange" v-if="currentTabComponent">
                    </component>
                </div>
            </div>
        </form>
    </div>
</template>