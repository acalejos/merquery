<script>
import BaseSecret from './BaseSecret.vue'
import BaseSelect from './BaseSelect.vue'
export default {
    name: "AuthTab",
    props: {
        modelValue: Object,
        ctx: Object,
        bindingOptions: Array
    },
    components: {
        BaseSecret,
        BaseSelect
    },
    data() {
        return {
            schemes: {
                "none": { placeholder: "    ", label: "None", details: "This request does not use any authorization." },
                "basic": { placeholder: "User Info", label: "Basic", details: "Uses Basic HTTP authentication" },
                "bearer": { placeholder: "Token", label: "Bearer", details: "Uses Bearer HTTP authentication" },
                "netrc": { placeholder: "Path", label: ".netrc", details: "If a path is provided, load credentials from path.  Otherwise, load credentials from .netrc at path specified in NETRC environment variable. If NETRC is not set, load .netrc in user's home directory." },
                "string": { placeholder: "Value", label: "String", details: "Sets the authorization header to this value" }
            }
        }
    }
}
</script>
<template>
    <div class="flex h-[298px]">
        <!-- Left pane -->
        <div class="w-1/4 bg-gray-100 border-r text-gray-700 rounded p-4">
            <BaseSelect name="scheme" label="Scheme" v-model="modelValue.scheme" :inline :options="Object.entries(schemes).map(([key, value]) => {
                return {
                    value: key,
                    label: value.label
                };
            })" />
        </div>
        <!-- Right pane -->
        <div class="flex-1 text-gray-700 rounded p-4 flex flex-col">
            <label for="token" class="block mb-2 input-label">{{ schemes[modelValue.scheme].placeholder
                }}</label>
            <BaseSecret v-if="modelValue.scheme !== 'none'" :ctx="ctx" textInputName="value" secretInputName="value"
                toggleInputName="type" v-model:textInputValue="modelValue.value"
                v-model:secretInputValue="modelValue.value" v-model:toggleInputValue="modelValue.type"
                :bindingOptions="bindingOptions" v-model:bindingInputValue="modelValue.value" modalTitle="Set value"
                :placeholder="schemes[modelValue.scheme].placeholder"
                @update:secretInputValue="$emit('update:modelValue', modelValue)"
                @update:textInputValue="$emit('update:modelValue', modelValue)"
                @update:bindingInputValue="$emit('update:modelValue', modelValue)"
                @update:toggleInputValue="$emit('update:modelValue', modelValue)" />
            <div class="flex-grow flex flex-col justify-center items-center">
                <p>{{ schemes[modelValue.scheme].details }}</p>
            </div>
        </div>
    </div>
</template>