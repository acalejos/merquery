<script>
export default {
    name: "BaseInput",

    props: {
        label: {
            type: String,
            default: "",
        },
        inputClass: {
            type: String,
            default: "input",
        },
        modelValue: {
            type: [String, Number],
            default: "",
        },
        inline: {
            type: Boolean,
            default: false,
        },
        grow: {
            type: Boolean,
            default: false,
        },
        number: {
            type: Boolean,
            default: false,
        },
    },

    computed: {
        emptyClass() {
            if (this.modelValue === "") {
                return "empty";
            }
        },
    }
};
</script>

<template>
    <div v-bind:class="[inline ? 'inline-field' : 'field', grow ? 'grow' : '']">
        <label v-bind:class="inline ? 'inline-input-label' : 'input-label'">
            {{ label }}
        </label>
        <input :value="modelValue" @input="$emit('update:modelValue', $event.target.value)" v-bind="$attrs"
            v-bind:class="[inputClass, number ? 'input-number' : '', emptyClass]">
    </div>
</template>