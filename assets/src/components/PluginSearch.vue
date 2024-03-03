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
    <div class="modal" v-show="showModal">
        <div class="modal-content">
            <span class="close" @click="close">&times;</span>
            <slot></slot>
        </div>
    </div>
</template>