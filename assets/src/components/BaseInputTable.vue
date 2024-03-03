<script>
import BaseSwitch from './BaseSwitch.vue'
import BaseSecret from './BaseSecret.vue'

export default {
    name: "BaseInputTable",
    components: {
        BaseSwitch,
        BaseSecret
    },
    props: {
        ctx: Object,
        modelValue: Array,
        currentTab: String,
    },
    data() {
        return {
            addRow: { active: true, key: "", value: "", isSecretValue: false },
            focusedRowIndex: null,
            inputs: {},
        };
    },
    computed: {
        newRowIndex() {
            return this.modelValue.length;
        },
    },
    methods: {
        handleInput(index, field, value) {
            // If editing the last row, append a new empty row - only if not already appended
            if (index === this.newRowIndex) {
                this.focusedRowIndex = index;
                this.modelValue.push({
                    ...this.addRow,
                });
                this.addRow = {
                    active: true,
                    key: "",
                    value: "",
                    isSecretValue: false,
                };
                this.$nextTick(() => {
                    this.inputs[`${field}-${index}`].focus();
                });
            } else {
                this.modelValue[index][field] = value;
            }
            this.emitModelValueUpdate();
        },
        deleteRow(index) {
            this.modelValue.splice(index, 1);
            this.emitModelValueUpdate();
        },
        handleFocus(index) {
            this.focusedRowIndex = index;
        },
        handleBlur() {
            this.focusedRowIndex = null;
        },
        emitModelValueUpdate() {
            // Emit an event with the updated rows array
            this.$emit("update:modelValue", this.modelValue);
        },
    }
};
</script>

<template>
    <div>
        <table class="base-input-table">
            <thead>
                <tr>
                    <th>Active</th>
                    <th>Key</th>
                    <th>Value</th>
                </tr>
            </thead>
            <tbody>
                <tr v-for="(row, index) in modelValue" :key="index" class="table-row">
                    <td>
                        <BaseSwitch v-model="row.active" />
                    </td>
                    <td>
                        <input type="text" v-model="row.key" placeholder="Key"
                            :ref="(el) => { inputs['key-' + index] = el; }"
                            @input="handleInput(index, 'key', $event.target.value)" @focus="handleFocus(index)"
                            @blur="handleFocus(index)">
                    </td>
                    <td>
                        <BaseSecret :ctx="ctx" :ref="(el) => { inputs['value-' + index] = el; }" textInputName="value"
                            secretInputName="value" toggleInputName="isSecretValue" label=""
                            v-model:textInputValue="row.value" v-model:secretInputValue="row.value"
                            v-model:toggleInputValue="row.isSecretValue" modalTitle="Set value"
                            @focus="handleFocus(index)" @blur="handleBlur(index)" />
                        <!-- Apply conditional rendering for the delete icon -->
                        <span v-show="focusedRowIndex !== index" class="delete-icon" @click="deleteRow(index)">
                            &#10006; <!-- Simple 'X' icon, can be replaced with an SVG or Font Awesome icon -->
                        </span>
                    </td>
                </tr>
                <tr id="newRow" :key="newRowIndex" class="table-row">
                    <td>
                        <BaseSwitch v-model="addRow.active" />
                    </td>
                    <td>
                        <input type="text" v-model="addRow.key" placeholder="Key"
                            @input="handleInput(newRowIndex, 'key', $event.target.value)"
                            @focus="handleFocus(newRowIndex)" @blur="handleFocus(newRowIndex)">
                    </td>
                    <td>
                        <BaseSecret :ctx="ctx" textInputName="value" secretInputName="value"
                            toggleInputName="isSecretValue" label="" v-model:textInputValue="addRow.value"
                            v-model:secretInputValue="addRow.value" v-model:toggleInputValue="addRow.isSecretValue"
                            modalTitle="Set value" @focus="handleFocus(newRowIndex)" @blur="handleBlur(newRowIndex)" />
                    </td>
                </tr>
            </tbody>
        </table>
    </div>
</template>