<script>
export default {
    name: "PluginSearch",
    props: {
        showModal: Boolean,
        default: false
    },
    methods: {
        close() {
            this.$emit("close");
        },
    }
};
</script>

<template>
    <div class="flex justify-center items-center fixed z-40 left-0 top-0 w-full h-full bg-black bg-opacity-50"
        v-show="showModal">
        <div class="bg-white mx-auto p-5 border border-gray-400 w-4/5 rounded-md h-[90%]">
            <span class="text-gray-400 float-right text-3xl font-bold focus:text-black hover:text-black
                cursor-pointer focus:outline-none" @click="close">&times;</span>
            <slot></slot>
        </div>
    </div>
</template>