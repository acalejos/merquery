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
            type: Boolean,
            default: false,
        },
        secretInputValue: {
            type: [String, Number],
            default: "",
        },
        textInputValue: {
            type: [String, Number],
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

    methods: {
        selectSecret() {
            console.log("Inside secret select");
            console.log(this.ctx);
            const preselectName = this.secretInputValue;
            this.ctx.selectSecret(
                (secretName) => {
                    console.log(secretName);
                    this.$emit("update:secretInputValue", secretName);
                    this.$emit("update:textInputValue", secretName);
                },
                preselectName,
                { title: this.modalTitle }
            );
        },
    }
};
</script>

<template>
    <div class="input-icon-container grow">
        <BaseInput v-if="toggleInputValue" :name="secretInputName" :label="label" :value="secretInputValue"
            inputClass="input input-icon" grow=true readonly @click="selectSecret"
            @input="$emit('update:secretInputValue', $event.target.value)" :required="!secretInputValue && required" />
        <BaseInput v-else :name="textInputName" :label="label" type="text" :value="textInputValue"
            inputClass="input input-icon-text" grow=true @input="$emit('update:textInputValue', $event.target.value)"
            :required="!textInputValue && required" />
        <div class="icon-container">
            <label class="hidden-checkbox">
                <input type="checkbox" :name="toggleInputName" :checked="toggleInputValue"
                    @input="$emit('update:toggleInputValue', $event.target.checked)" class="hidden-checkbox-input" />
                <svg v-if="toggleInputValue" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="22"
                    height="22">
                    <path fill="none" d="M0 0h24v24H0z" />
                    <path d="M18 8h2a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1h2V7a6 6 0 1 1 12 0v1zM5
                10v10h14V10H5zm6 4h2v2h-2v-2zm-4 0h2v2H7v-2zm8 0h2v2h-2v-2zm1-6V7a4 4 0 1 0-8 0v1h8z" fill="#000" />
                </svg>
                <svg v-else xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
                    <path fill="none" d="M0 0h24v24H0z" />
                    <path d="M21 3v18H3V3h18zm-8.001 3h-2L6.6 17h2.154l1.199-3h4.09l1.201 3h2.155l-4.4-11zm-1 2.885L13.244
                12h-2.492l1.247-3.115z" fill="#445668" />
                </svg>
            </label>
        </div>
    </div>
</template>