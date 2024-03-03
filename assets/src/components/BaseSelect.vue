<script>
export default {
    name: "BaseSelect",
    props: {
        label: {
            type: String,
            default: "",
        },
        selectClass: {
            type: String,
            default: "input",
        },
        modelValue: {
            type: String,
            default: "",
        },
        options: {
            type: Array,
            default: [],
            required: true,
        },
        required: {
            type: Boolean,
            default: false,
        },
        inline: {
            type: Boolean,
            default: false,
        },
        grow: {
            type: Boolean,
            default: false,
        },
    },

    methods: {
        available(value, options) {
            return value
                ? options.map((option) => option.value).includes(value)
                : true;
        },
    },
};
</script>

<template>
    <div v-bind:class="[inline ? 'inline-field' : 'field', grow ? 'grow' : '']">
        <label v-bind:class="inline ? 'inline-input-label' : 'input-label'">
            {{ label }}
        </label>
        <select :value="modelValue" v-bind="$attrs" @change="$emit('update:modelValue', $event.target.value)"
            v-bind:class="[selectClass, { unavailable: !available(modelValue, options) }]">
            <option v-if="!required && !available(modelValue, options)"></option>
            <option v-for="option in options" :value="option.value" :key="option"
                :selected="option.value === modelValue">{{ option.label }}</option>
            <option v-if="!available(modelValue, options)" class="unavailable" :value="modelValue">{{ modelValue }}
            </option>
        </select>
    </div>
</template>