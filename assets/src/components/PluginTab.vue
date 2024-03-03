<script>
import BaseSwitch from './BaseSwitch.vue'
import PluginSearch from './PluginSearch.vue'
export default {
    name: "PluginTab",
    data() {
        return { showModal: false, searchQuery: "" };
    },
    props: {
        ctx: Object,
        modelValue: Array,
    },
    components: {
        BaseSwitch,
        PluginSearch,
    },
    computed: {
        // filteredItems() {
        //   return this.items.filter((item) =>
        //     item.name.toLowerCase().includes(this.searchQuery.toLowerCase())
        //   );
        // },
    },
    methods: {
        refreshPlugins() {
            this.ctx.pushEvent("refreshPlugins", {
                plugins: JSON.parse(JSON.stringify(this.modelValue)),
            });
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
    <div>
        <div class="button-group">
            <button type="button" @click="toggleModal" title="Add new plugin from Hex">
                <span>Add</span>
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5"
                    stroke="currentColor" class="w-6 h-6">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
                </svg>
            </button>
            <PluginSearch :showModal @close="toggleModal">
                <template v-slot:default>
                    <div class="mx-auto max-w-lg">
                        <div>
                            <div class="text-center">
                                <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor"
                                    viewBox="0 0 48 48" aria-hidden="true">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                        d="M34 40h10v-4a6 6 0 00-10.712-3.714M34 40H14m20 0v-4a9.971 9.971 0 00-.712-3.714M14 40H4v-4a6 6 0 0110.713-3.714M14 40v-4c0-1.313.253-2.566.713-3.714m0 0A10.003 10.003 0 0124 26c4.21 0 7.813 2.602 9.288 6.286M30 14a6 6 0 11-12 0 6 6 0 0112 0zm12 6a4 4 0 11-8 0 4 4 0 018 0zm-28 0a4 4 0 11-8 0 4 4 0 018 0z" />
                                </svg>
                                <h2 class="mt-2 text-base font-semibold leading-6 text-gray-900">Add team members</h2>
                                <p class="mt-1 text-sm text-gray-500">You haven’t added any team members to your project
                                    yet. As the owner of this project, you can manage team member permissions.</p>
                            </div>
                            <form action="#" class="mt-6 flex">
                                <label for="email" class="sr-only">Email address</label>
                                <input type="email" name="email" id="email"
                                    class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                                    placeholder="Enter an email" />
                                <button type="submit"
                                    class="ml-4 flex-shrink-0 rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">Send
                                    invite</button>
                            </form>
                        </div>
                        <div class="mt-10">
                            <h3 class="text-sm font-medium text-gray-500">Team members previously added to projects</h3>
                            <ul role="list" class="mt-4 divide-y divide-gray-200 border-b border-t border-gray-200">
                                <li v-for="(person, personIdx) in people" :key="personIdx"
                                    class="flex items-center justify-between space-x-3 py-4">
                                    <div class="flex min-w-0 flex-1 items-center space-x-3">
                                        <div class="flex-shrink-0">
                                            <img class="h-10 w-10 rounded-full" :src="person.imageUrl" alt="" />
                                        </div>
                                        <div class="min-w-0 flex-1">
                                            <p class="truncate text-sm font-medium text-gray-900">{{ person.name }}</p>
                                            <p class="truncate text-sm font-medium text-gray-500">{{ person.role }}</p>
                                        </div>
                                    </div>
                                    <div class="flex-shrink-0">
                                        <button type="button"
                                            class="inline-flex items-center gap-x-1.5 text-sm font-semibold leading-6 text-gray-900">
                                            <!-- Add Icon -->
                                            Invite <span class="sr-only">{{ person.name }}</span>
                                        </button>
                                    </div>
                                </li>
                            </ul>
                        </div>
                    </div>
                </template>
            </PluginSearch>
            <button type="button" @click="refreshPlugins" title="Refresh plugins list">
                <span>Refresh</span>
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-5 h-5">
                    <path fill-rule="evenodd"
                        d="M15.312 11.424a5.5 5.5 0 0 1-9.201 2.466l-.312-.311h2.433a.75.75 0 0 0 0-1.5H3.989a.75.75 0 0 0-.75.75v4.242a.75.75 0 0 0 1.5 0v-2.43l.31.31a7 7 0 0 0 11.712-3.138.75.75 0 0 0-1.449-.39Zm1.23-3.723a.75.75 0 0 0 .219-.53V2.929a.75.75 0 0 0-1.5 0V5.36l-.31-.31A7 7 0 0 0 3.239 8.188a.75.75 0 1 0 1.448.389A5.5 5.5 0 0 1 13.89 6.11l.311.31h-2.432a.75.75 0 0 0 0 1.5h4.243a.75.75 0 0 0 .53-.219Z"
                        clip-rule="evenodd" />
                </svg>
            </button>
        </div>
        <div class="plugin-empty-state" v-if="modelValue.length <= 0">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5"
                stroke="currentColor" class="w-6 h-6">
                <path stroke-linecap="round" stroke-linejoin="round"
                    d="M14.25 6.087c0-.355.186-.676.401-.959.221-.29.349-.634.349-1.003 0-1.036-1.007-1.875-2.25-1.875s-2.25.84-2.25 1.875c0 .369.128.713.349 1.003.215.283.401.604.401.959v0a.64.64 0 0 1-.657.643 48.39 48.39 0 0 1-4.163-.3c.186 1.613.293 3.25.315 4.907a.656.656 0 0 1-.658.663v0c-.355 0-.676-.186-.959-.401a1.647 1.647 0 0 0-1.003-.349c-1.036 0-1.875 1.007-1.875 2.25s.84 2.25 1.875 2.25c.369 0 .713-.128 1.003-.349.283-.215.604-.401.959-.401v0c.31 0 .555.26.532.57a48.039 48.039 0 0 1-.642 5.056c1.518.19 3.058.309 4.616.354a.64.64 0 0 0 .657-.643v0c0-.355-.186-.676-.401-.959a1.647 1.647 0 0 1-.349-1.003c0-1.035 1.008-1.875 2.25-1.875 1.243 0 2.25.84 2.25 1.875 0 .369-.128.713-.349 1.003-.215.283-.4.604-.4.959v0c0 .333.277.599.61.58a48.1 48.1 0 0 0 5.427-.63 48.05 48.05 0 0 0 .582-4.717.532.532 0 0 0-.533-.57v0c-.355 0-.676.186-.959.401-.29.221-.634.349-1.003.349-1.035 0-1.875-1.007-1.875-2.25s.84-2.25 1.875-2.25c.37 0 .713.128 1.003.349.283.215.604.401.96.401v0a.656.656 0 0 0 .658-.663 48.422 48.422 0 0 0-.37-5.36c-1.886.342-3.81.574-5.766.689a.578.578 0 0 1-.61-.58v0Z" />
            </svg>
        </div>
        <table class="base-input-table" v-if="modelValue.length > 0">
            <thead>
                <tr>
                    <th></th>
                    <th>Plugin</th>
                    <th>Description</th>
                    <th></th>
                </tr>
            </thead>
            <tbody>
                <tr v-for="(row, index) in modelValue" :key="index" class="table-row">
                    <td>
                        <BaseSwitch v-model="row.active" />
                    </td>
                    <td>
                        {{ row.name }}
                    </td>
                    <td>
                        {{ row.description }}
                    </td>
                    <td>
                        <span class="delete-icon" @click="deleteRow(index)">
                            &#10006; <!-- Simple 'X' icon, can be replaced with an SVG or Font Awesome icon -->
                        </span>
                    </td>
                </tr>
            </tbody>
        </table>
    </div>
</template>