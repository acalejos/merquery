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
        ctx: Object
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
                : "singleOption";
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
            <div class="app-container">
                <div class="row header">
                    <BaseSelect name="request_type" label="" v-model="fields.request_type"
                        v-bind:selectClass="selectClass" :inline
                        :options="fields.verbs.map((name) => ({ label: name.toUpperCase(), value: name }))" />

                    <BaseInput name="variable" label=" Assign to " type="text" v-model="fields.variable"
                        inputClass="input input--xs input-text" :inline />
                </div>

                <div class="common-request-form">
                    <div class="row mixed-row">
                        <BaseInput name="url" label="URL" type="text" v-model="fields.url" inputClass="input" :grow />
                    </div>
                    <!-- Tabs -->
                    <div class="tabs">
                        <div class="tabs-wrapper">
                            <button type="button" v-for="tab in tabs" :key="tab" @click="currentTab = tab"
                                :class="{ active: currentTab === tab }">
                                {{ tab.charAt(0).toUpperCase() + tab.slice(1) }}
                            </button>
                        </div>
                    </div>

                    <component :ctx="this.ctx" :is="currentTabComponent" v-bind:modelValue="fields[currentTab]"
                        v-bind:currentTab="currentTab" @update:modelValue="handleFieldChange"
                        v-if="currentTabComponent">
                    </component>
                </div>
            </div>
        </form>
    </div>
</template>

<style lang="postcss">
@tailwind base;
@tailwind components;
@tailwind utilities;
</style>