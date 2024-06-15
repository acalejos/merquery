<script>
import BaseSwitch from './BaseSwitch.vue'
export default {
    name: "StepsTab",
    components: {
        BaseSwitch,
    },
    props: {
        modelValue: Array,
    },
    data() {
        return {
            step_types: ["request_steps", "response_steps", "error_steps"],
            current_step: "request_steps",
        };
    },
    methods: {
        capitalize(str) {
            return str.charAt(0).toUpperCase() + str.slice(1);
        },
    },
    computed: {
        currentSteps() {
            return this.modelValue[this.current_step];
        },
    }
};
</script>

<template>
    <div class="w-full">
        <fieldset class="mt-4 ml-4">
            <legend class="sr-only">Step Type</legend>
            <div class="sm:flex sm:items-center sm:space-x-3">
                <div v-for="(step_type, index) in step_types" :key="index" class="flex items-center">
                    <input class="h-4 w-4 border-gray-300 text-indigo-600" type="radio" name="currentStep"
                        :id="step_type" :value="step_type" v-model="current_step" />
                    <label class="ml-1 block text-sm font-medium leading-6 text-gray-900" :for="step_type">{{
                    capitalize(step_type.split("_")[0]) }}</label>
                </div>
            </div>
        </fieldset>
        <table class="w-full text-left border-collapse mt-4 h-[184px]">
            <thead class="flex w-full">
                <tr class="w-full flex mb-4">
                    <th class="pl-16 py-2 px-3 border-b border-gray-200 text-gray-800 bg-gray-50"></th>
                    <th class="w-1/5 py-2 px-3 border-b border-gray-200 text-gray-800 bg-gray-50">Step</th>
                    <th class="w-4/5 py-2 px-3 border-b border-gray-200 text-gray-800 bg-gray-50">Description</th>
                </tr>
            </thead>
            <tbody class="flex w-full flex-col items-center justify-between overflow-y-auto h-full">
                <tr class="w-full flex" v-for="(row, index) in currentSteps" :key="index">
                    <td class="py-2 px-3 border-b border-gray-200 text-gray-600">
                        <BaseSwitch v-model="row.active" />
                    </td>
                    <td class="w-1/5 py-2 px-3 border-b border-gray-200 text-gray-600">
                        {{ row.name }}
                    </td>
                    <td class="w-4/5 py-2 px-3 border-b border-gray-200 text-gray-600">
                        {{ row.doc }}
                    </td>
                </tr>
            </tbody>
        </table>
    </div>
</template>