<script>
export default {
    name: "BaseSwitch",

    props: {
        label: {
            type: String,
            default: "",
        },
        modelValue: {
            type: Boolean,
            default: true,
        },
        inline: {
            type: Boolean,
            default: false,
        },
        grow: {
            type: Boolean,
            default: false,
        },
        inputClass: {
            type: String,
            default: "",
        },
        number: {
            type: Boolean,
            default: false,
        },
    }
};
</script>

<template>
    <div v-bind:class="[inline ? 'inline-field' : 'field', grow ? 'grow' : '']">
        <label v-bind:class="inline ? 'inline-input-label' : 'input-label'">
            {{ label }}
        </label>
        <div class="input-container">
            <label class="switch-button">
                <input :checked="modelValue" type="checkbox" @input="$emit('update:modelValue', $event.target.checked)"
                    v-bind="$attrs" class="switch-button-checkbox"
                    v-bind:class="[inputClass, number ? 'input-number' : '']">
                <div class="switch-button-bg" />
            </label>
        </div>
    </div>
</template>