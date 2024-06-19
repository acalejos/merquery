<script>
import BaseSwitch from './BaseSwitch.vue'
import PluginSearch from './PluginSearch.vue'
export default {
    name: "PluginTab",
    data() {
        return { showModal: false, searchQuery: "", showTooltipIndex: null, };
    },
    props: {
        ctx: Object,
        modelValue: Array,
        availablePlugins: Array
    },
    components: {
        BaseSwitch,
        PluginSearch,
    },
    computed: {
        filteredItems() {
            return this.unloadedPlugins.filter((item) =>
                item.name.toLowerCase().includes(this.searchQuery.toLowerCase()) ||
                item.description.toLowerCase().includes(this.searchQuery.toLowerCase())
            );
        },
        unloadedPlugins() {
            return this.availablePlugins.filter((item) =>
                !this.modelValue.some((plugin) => plugin.name === item.name)
            );
        }
    },
    methods: {
        async copyTextToClipboard(text, index) {
            if (!navigator.clipboard) {
                console.error('Clipboard API is not available.');
                return;
            }
            try {
                await navigator.clipboard.writeText(text);
                this.showTooltipIndex = index; // Show tooltip for the clicked item
                setTimeout(() => {
                    this.showTooltipIndex = null; // Hide tooltip after 2 seconds
                }, 2000);
            } catch (err) {
                console.error('Failed to copy:', err);
            }
        },
        refreshPlugins() {
            this.ctx.pushEvent("refreshPlugins", {
                plugins: JSON.parse(JSON.stringify(this.modelValue)),
            });
        },
        addDep(depString, index) {
            this.showTooltipIndex = index; // Show tooltip for the clicked item
            setTimeout(() => {
                this.showTooltipIndex = null; // Hide tooltip after 2 seconds
            }, 2000);
            this.ctx.pushEvent("addDep", { depString: depString, plugins: JSON.parse(JSON.stringify(this.modelValue)) })
        },
        deleteRow(index) {
            this.modelValue.splice(index, 1);
            this.emitModelValueUpdate();
        },
        toggleModal() {
            this.showModal = !this.showModal;
        },
        emitModelValueUpdate() {
            // Emit an event with the updated rows array
            this.$emit("update:modelValue", this.modelValue);
        }
    }
};
</script>

<template>
    <div class="h-full flex flex-col justify-center">
        <div class="flex items-center gap-2.5 ml-2.5">
            <PluginSearch :showModal @close="toggleModal">
                <template v-slot:default>
                    <div class="mx-auto max-w-lg h-full">
                        <div>
                            <div class="text-center">
                                <svg class="mx-auto h-8 w-8 text-gray-400" xmlns="http://www.w3.org/2000/svg"
                                    fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round"
                                        d="M14.25 6.087c0-.355.186-.676.401-.959.221-.29.349-.634.349-1.003 0-1.036-1.007-1.875-2.25-1.875s-2.25.84-2.25 1.875c0 .369.128.713.349 1.003.215.283.401.604.401.959v0a.64.64 0 0 1-.657.643 48.39 48.39 0 0 1-4.163-.3c.186 1.613.293 3.25.315 4.907a.656.656 0 0 1-.658.663v0c-.355 0-.676-.186-.959-.401a1.647 1.647 0 0 0-1.003-.349c-1.036 0-1.875 1.007-1.875 2.25s.84 2.25 1.875 2.25c.369 0 .713-.128 1.003-.349.283-.215.604-.401.959-.401v0c.31 0 .555.26.532.57a48.039 48.039 0 0 1-.642 5.056c1.518.19 3.058.309 4.616.354a.64.64 0 0 0 .657-.643v0c0-.355-.186-.676-.401-.959a1.647 1.647 0 0 1-.349-1.003c0-1.035 1.008-1.875 2.25-1.875 1.243 0 2.25.84 2.25 1.875 0 .369-.128.713-.349 1.003-.215.283-.4.604-.4.959v0c0 .333.277.599.61.58a48.1 48.1 0 0 0 5.427-.63 48.05 48.05 0 0 0 .582-4.717.532.532 0 0 0-.533-.57v0c-.355 0-.676.186-.959.401-.29.221-.634.349-1.003.349-1.035 0-1.875-1.007-1.875-2.25s.84-2.25 1.875-2.25c.37 0 .713.128 1.003.349.283.215.604.401.96.401v0a.656.656 0 0 0 .658-.663 48.422 48.422 0 0 0-.37-5.36c-1.886.342-3.81.574-5.766.689a.578.578 0 0 1-.61-.58v0Z" />
                                </svg>

                                <h2 class="mt-2 text-base font-semibold leading-6 text-gray-900">Add Plugin</h2>
                                <p class="mt-1 text-sm text-gray-500">
                                    Once you find a plugin you want add it to your setup
                                    cell and rerun to see it reflected in your plugins list.
                                </p>
                            </div>
                            <form action="#" class="mt-6 flex">
                                <label for="search" class="sr-only">Search</label>
                                <input id="search" v-model="searchQuery"
                                    class="px-4 block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 sm:text-sm sm:leading-6"
                                    placeholder="Search..." />
                            </form>
                        </div>
                        <div class="mt-4 h-full flex-col">
                            <h3 class="text-sm font-medium text-gray-500">
                                Suggest more on <a href="https://github.com/acalejos/merquery"
                                    class="text-blue-500 hover:text-blue-600 underline" target="_blank"
                                    rel="noopener noreferrer">
                                    GitHub!
                                </a>
                            </h3>
                            <ul role="list"
                                class="h-48 overflow-y-auto mt-4 divide-y divide-gray-200 border-b border-t border-gray-200">
                                <li v-for="(plugin, pluginIdx) in filteredItems" :key="pluginIdx"
                                    class="flex items-center justify-between space-x-3 py-4">
                                    <div class="flex min-w-0 flex-1 items-center space-x-3">
                                        <div class="min-w-0  flex-1">
                                            <p class="truncate text-sm font-medium text-gray-900">{{ plugin.name }}</p>
                                            <p class="truncate text-sm font-medium text-gray-500">
                                                {{ plugin.description }}
                                            </p>
                                        </div>
                                    </div>
                                    <div class="flex-shrink-0 pr-4">
                                        <span v-if="showTooltipIndex === pluginIdx"
                                            class="p-2 text-sm font-medium text-gray-800 rounded-md -translate-x-1/2 left-1/2 bottom-full mb-2">
                                            Added!
                                        </span>
                                        <div v-else="showTooltipIndex === index" class="ml-2">
                                            <button class="button-base button-gray whitespace-nowrap py-1 px-2"
                                                type="button" @click="addDep(plugin.version, pluginIdx)"
                                                aria-label="add">
                                                <i class="ri-add-line align-middle mr-1 text-xs" aria-hidden="true"></i>
                                                <span class="font-normal text-xs">Add</span>
                                            </button>
                                        </div>

                                    </div>
                                </li>
                            </ul>
                        </div>
                    </div>
                </template>
            </PluginSearch>
        </div>
        <div class="flex flex-col items-center justify-center mt-12" v-if="modelValue.length <= 0">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5"
                stroke="currentColor" class="mx-auto h-12 w-12 text-gray-400">
                <path stroke-linecap="round" stroke-linejoin="round"
                    d="M14.25 6.087c0-.355.186-.676.401-.959.221-.29.349-.634.349-1.003 0-1.036-1.007-1.875-2.25-1.875s-2.25.84-2.25 1.875c0 .369.128.713.349 1.003.215.283.401.604.401.959v0a.64.64 0 0 1-.657.643 48.39 48.39 0 0 1-4.163-.3c.186 1.613.293 3.25.315 4.907a.656.656 0 0 1-.658.663v0c-.355 0-.676-.186-.959-.401a1.647 1.647 0 0 0-1.003-.349c-1.036 0-1.875 1.007-1.875 2.25s.84 2.25 1.875 2.25c.369 0 .713-.128 1.003-.349.283-.215.604-.401.959-.401v0c.31 0 .555.26.532.57a48.039 48.039 0 0 1-.642 5.056c1.518.19 3.058.309 4.616.354a.64.64 0 0 0 .657-.643v0c0-.355-.186-.676-.401-.959a1.647 1.647 0 0 1-.349-1.003c0-1.035 1.008-1.875 2.25-1.875 1.243 0 2.25.84 2.25 1.875 0 .369-.128.713-.349 1.003-.215.283-.4.604-.4.959v0c0 .333.277.599.61.58a48.1 48.1 0 0 0 5.427-.63 48.05 48.05 0 0 0 .582-4.717.532.532 0 0 0-.533-.57v0c-.355 0-.676.186-.959.401-.29.221-.634.349-1.003.349-1.035 0-1.875-1.007-1.875-2.25s.84-2.25 1.875-2.25c.37 0 .713.128 1.003.349.283.215.604.401.96.401v0a.656.656 0 0 0 .658-.663 48.422 48.422 0 0 0-.37-5.36c-1.886.342-3.81.574-5.766.689a.578.578 0 0 1-.61-.58v0Z" />
            </svg>
            <h3 class="mt-2 text-sm font-semibold text-gray-900">No plugins loaded</h3>
            <p class="mt-1 text-sm text-gray-500">Get started by adding a new plugin dependency.</p>
            <div class="mt-6 flex space-x-4">
                <button type="button" @click="toggleModal" title="Add new plugin from Hex"
                    class="inline-flex items-center justify-center gap-1.25 w-38 px-4 py-2 text-sm font-medium text-gray-800 bg-blue-100 rounded-md cursor-pointer transition-colors duration-300 ease-in-out hover:bg-gray-300 disabled:opacity-50 disabled:cursor-not-allowed">
                    <span>Add</span>
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5"
                        stroke="currentColor" class="w-6 h-6">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
                    </svg>
                </button>
                <button type="button" @click="refreshPlugins" title="Reload All Loaded Plugins"
                    class="inline-flex items-center justify-center gap-1.25 w-38 px-4 py-2 text-sm font-medium text-gray-800 bg-blue-100 rounded-md cursor-pointer transition-colors duration-300 ease-in-out hover:bg-gray-300 disabled:opacity-50 disabled:cursor-not-allowed">
                    <span>Refresh</span>
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5"
                        stroke="currentColor" class="w-6 h-6">
                        <path stroke-linecap="round" stroke-linejoin="round"
                            d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0 3.181 3.183a8.25 8.25 0 0 0 13.803-3.7M4.031 9.865a8.25 8.25 0 0 1 13.803-3.7l3.181 3.182m0-4.991v4.99" />
                    </svg>

                </button>
            </div>
        </div>
        <table class="w-full border-collapse mt-4 table-fixed" v-if="modelValue.length > 0">
            <thead>
                <tr>
                    <th class="w-24 py-2 px-3 border-b border-gray-200 text-gray-800 bg-gray-50">
                        <div class="flex items-center justify-center space-x-2">
                            <button type="button" @click="toggleModal" title="Add new plugin from Hex"
                                class="hover:bg-gray-100 p-1 rounded-lg transition-colors duration-150">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"
                                    stroke-width="1.5" stroke="currentColor" class="w-6 h-6 text-gray-500">
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
                                </svg>
                            </button>
                            <button type="button" @click="refreshPlugins" title="Refresh plugins list"
                                class="hover:bg-gray-100 p-1 rounded-lg transition-colors duration-150">
                                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor"
                                    class="w-5 h-5 text-gray-500">
                                    <path fill-rule="evenodd"
                                        d="M15.312 11.424a5.5 5.5 0 0 1-9.201 2.466l-.312-.311h2.433a.75.75 0 0 0 0-1.5H3.989a.75.75 0 0 0-.75.75v4.242a.75.75 0 0 0 1.5 0v-2.43l.31.31a7 7 0 0 0 11.712-3.138.75.75 0 0 0-1.449-.39Zm1.23-3.723a.75.75 0 0 0 .219-.53V2.929a.75.75 0 0 0-1.5 0V5.36l-.31-.31A7 7 0 0 0 3.239 8.188a.75.75 0 1 0 1.448.389A5.5 5.5 0 0 1 13.89 6.11l.311.31h-2.432a.75.75 0 0 0 0 1.5h4.243a.75.75 0 0 0 .53-.219Z"
                                        clip-rule="evenodd" />
                                </svg>
                            </button>
                        </div>
                    </th>
                    <th class="text-left w-32 py-2 px-3 border-b border-gray-200 text-gray-800 bg-gray-50">Plugin</th>
                    <th class="text-left w-auto py-2 px-3 border-b border-gray-200 text-gray-800 bg-gray-50">Description
                    </th>
                    <th class="w-10 py-2 px-3 border-b border-gray-200 text-gray-800 bg-gray-50"></th>
                </tr>
            </thead>
            <tbody>
                <tr v-for="(row, index) in modelValue" :key="index">
                    <td class="py-2 px-3 border-b border-gray-200 text-gray-600">
                        <BaseSwitch v-model="row.active" />
                    </td>
                    <td class="py-2 px-3 border-b border-gray-200 text-gray-600">
                        {{ row.name }}
                    </td>
                    <td class="py-2 px-3 border-b border-gray-200 text-gray-600 overflow-hidden">
                        <div class="truncate">
                            {{ row.description }}
                        </div>
                    </td>
                    <td class="py-2 px-3 border-b border-gray-200 text-gray-600 flex justify-center">
                        <button @click="deleteRow(index)" class="hover:bg-gray-100 p-1 rounded-lg">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5"
                                stroke="currentColor" class="w-6 h-6 text-gray-500">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                            </svg>
                        </button>
                    </td>
                </tr>
            </tbody>
        </table>
    </div>
</template>