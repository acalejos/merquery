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
    <div>
        <div class="radio-buttons">
            <div v-for="(step_type, index) in step_types" :key="index">
                <input type="radio" name="currentStep" :id="step_type" :value="step_type" v-model="current_step" />
                <label :for="step_type">{{ capitalize(step_type.split("_")[0]) }}</label>
            </div>
        </div>

        <table class="base-input-table">
            <thead>
                <tr>
                    <th></th>
                    <th>Step</th>
                    <th>Description</th>
                </tr>
            </thead>
            <tbody>
                <tr v-for="(row, index) in currentSteps" :key="index">
                    <td>
                        <BaseSwitch v-model="row.active" />
                    </td>
                    <td>
                        {{ row.name }}
                    </td>
                    <td>
                        {{ row.doc }}
                    </td>
                </tr>
            </tbody>
        </table>
    </div>
</template>