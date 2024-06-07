<script>
import BaseInput from './BaseInput.vue'
import BaseSelect from './BaseSelect.vue'

export default {
    name: "BaseSecret",

    components: {
        BaseInput,
        BaseSelect
    },

    props: {
        ctx: Object,
        bindingOptions: Array,
        textInputName: {
            type: String,
            default: "",
        },
        secretInputName: {
            type: String,
            default: "",
        },
        toggleInputName: {
            type: String,
            default: "",
        },
        label: {
            type: String,
            default: "",
        },
        toggleInputValue: {
            type: Number,
            default: 0,
        },
        secretInputValue: {
            type: [String, Number],
            default: "",
        },
        textInputValue: {
            type: [String, Number],
            default: "",
        },
        bindingInputValue: {
            type: String,
            default: "",
        },
        modalTitle: {
            type: String,
            default: "Select secret",
        },
        required: {
            type: Boolean,
            default: false,
        },
    },
    computed: {
        options() {
            return this.bindingOptions;
        }
    },
    methods: {
        cycleInputType() {
            let newState = (this.toggleInputValue + 1) % 3;  // Assuming 3 states: 0, 1, 2
            this.$emit('update:toggleInputValue', newState);
        },
        selectSecret() {
            const preselectName = this.secretInputValue;
            this.ctx.selectSecret(
                (secretName) => {
                    this.$emit("update:secretInputValue", secretName);
                    this.$emit("update:textInputValue", secretName);
                    this.$emit("update:bindingInputValue", secretName);
                },
                preselectName,
                { title: this.modalTitle }
            );
        },
    }
};
</script>

<template>
    <div class="relative grow">
        <BaseInput v-if="toggleInputValue === 1" :name="secretInputName" :label="label" :value="secretInputValue"
            inputClass="input input-icon" grow=true readonly @click="selectSecret"
            @input="$emit('update:secretInputValue', $event.target.value)" :required="!secretInputValue && required" />
        <BaseInput v-else-if="toggleInputValue === 0" :name="textInputName" :label="label" type="text"
            :value="textInputValue" inputClass="input input-icon-text" grow=true
            @input="$emit('update:textInputValue', $event.target.value)" :required="!textInputValue && required" />
        <BaseSelect v-else :options="bindingOptions" grow=true :name="bindingInputName"
            selectClass="input input-icon-text " :value="bindingInputValue" :label="label"
            @input="$emit('update:bindingInputValue', $event.target.value)"
            :required="!bindingInputValue && required" />
        <div class="icon-container">
            <label class="hidden-checkbox">
                <button type="button" @click="cycleInputType" :name="toggleInputName"
                    @input="$emit('update:toggleInputValue', $event.target.checked)" class="hidden-checkbox-input" />
                <svg v-if="toggleInputValue === 1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="22"
                    height="22">
                    <path fill="none" d="M0 0h24v24H0z" />
                    <path d="M18 8h2a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1h2V7a6 6 0 1 1 12 0v1zM5
                10v10h14V10H5zm6 4h2v2h-2v-2zm-4 0h2v2H7v-2zm8 0h2v2h-2v-2zm1-6V7a4 4 0 1 0-8 0v1h8z" fill="#000" />
                </svg>
                <svg v-else-if="toggleInputValue === 0" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"
                    width="24" height="24">
                    <path fill="none" d="M0 0h24v24H0z" />
                    <path d="M21 3v18H3V3h18zm-8.001 3h-2L6.6 17h2.154l1.199-3h4.09l1.201 3h2.155l-4.4-11zm-1 2.885L13.244
                12h-2.492l1.247-3.115z" fill="#445668" />
                </svg>
                <svg v-else xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" width="24"
                    class="size-6">
                    <path fill-rule="evenodd"
                        d="M19.253 2.292a.75.75 0 0 1 .955.461A28.123 28.123 0 0 1 21.75 12c0 3.266-.547 6.388-1.542 9.247a.75.75 0 1 1-1.416-.494c.94-2.7 1.458-5.654 1.458-8.753s-.519-6.054-1.458-8.754a.75.75 0 0 1 .461-.954Zm-14.227.013a.75.75 0 0 1 .414.976A23.183 23.183 0 0 0 3.75 12c0 3.085.6 6.027 1.69 8.718a.75.75 0 0 1-1.39.563c-1.161-2.867-1.8-6-1.8-9.281 0-3.28.639-6.414 1.8-9.281a.75.75 0 0 1 .976-.414Zm4.275 5.052a1.5 1.5 0 0 1 2.21.803l.716 2.148L13.6 8.246a2.438 2.438 0 0 1 2.978-.892l.213.09a.75.75 0 1 1-.584 1.381l-.214-.09a.937.937 0 0 0-1.145.343l-2.021 3.033 1.084 3.255 1.445-.89a.75.75 0 1 1 .786 1.278l-1.444.889a1.5 1.5 0 0 1-2.21-.803l-.716-2.148-1.374 2.062a2.437 2.437 0 0 1-2.978.892l-.213-.09a.75.75 0 0 1 .584-1.381l.214.09a.938.938 0 0 0 1.145-.344l2.021-3.032-1.084-3.255-1.445.89a.75.75 0 1 1-.786-1.278l1.444-.89Z"
                        clip-rule="evenodd" />
                </svg>
            </label>
        </div>
    </div>
</template>