<template>
  <div class="subscribers-page">
    <!-- Header -->
    <div class="page-header">
      <h1 class="page-title">{{ $t('globals.terms.subscribers') }}</h1>
      <div class="header-actions">
        <button type="button" class="action-btn" @click="exportSubscribers">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M21,15v4a2,2,0,0,1-2,2H5a2,2,0,0,1-2-2V15" />
            <polyline points="7,10 12,15 17,10" />
            <line x1="12" y1="15" x2="12" y2="3" />
          </svg>
        </button>
        <button type="button" class="filter-btn" @click="showFilters = !showFilters">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polygon points="22,3 2,3 10,12.46 10,19 14,21 14,12.46" />
          </svg>
          Filter
        </button>
        <div class="search-container-header">
          <input
            v-model="queryInput"
            @input="onSimpleQueryInput"
            @keyup.enter="onSubmit"
            type="text"
            :placeholder="$t('subscribers.queryPlaceholder')"
            :aria-label="$t('subscribers.queryPlaceholder')"
            class="search-input-header"
          />
          <svg class="search-icon-header" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor"
            stroke-width="2">
            <circle cx="11" cy="11" r="8" />
            <line x1="21" y1="21" x2="16.65" y2="16.65" />
          </svg>
        </div>
        <button v-if="$can('subscribers:manage')" type="button" class="new-btn" @click="showNewForm">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="12" y1="5" x2="12" y2="19" />
            <line x1="5" y1="12" x2="19" y2="12" />
          </svg>
          {{ $t('globals.buttons.new') }}
        </button>
      </div>
    </div>

    <!-- Table container -->
    <div class="table-container">
      <div v-if="loading.subscribers" class="loading-overlay">
        <div class="spinner" />
      </div>
      <table class="subscribers-table">
        <thead>
          <tr>
            <th>Nombre</th>
            <th>Listas</th>
            <th>Añadido en</th>
            <th>Correo</th>
            <th class="options-header">Opciones</th>
          </tr>
        </thead>
        <tbody class="scrollable-tbody">
          <tr v-for="sub in subscribers.results" :key="sub.id" class="table-row">
            <!-- Nombre -->
            <td class="nombre-cell">
              <span v-if="sub.status !== 'enabled'" class="status-dot"
                :class="`status-${sub.status}`" />
              {{ sub.name }}
            </td>

            <!-- Listas -->
            <td class="listas-cell">
              <router-link v-if="listCount(sub.lists) > 0" :to="`/subscribers/lists/${sub.lists[0].id}`" class="list-count-link">
                {{ listCount(sub.lists) }}
              </router-link>
              <span v-else>0</span>
            </td>

            <!-- Añadido en -->
            <td class="fecha-cell">{{ $utils.niceDate(sub.createdAt) }}</td>

            <!-- Correo -->
            <td class="correo-cell">{{ sub.email }}</td>

            <!-- Opciones -->
            <td class="opciones-cell">
              <div class="opciones-dropdown-container">
                <button
                  type="button"
                  class="opciones-dropdown-arrow"
                  @click.stop="toggleActionsMenu(sub.id)"
                  :class="{ 'active': activeDropdown === sub.id }"
                >
                  <svg class="dropdown-arrow-only" width="16" height="16" viewBox="0 0 24 24" fill="none"
                    stroke="currentColor" stroke-width="2">
                    <polyline points="6,9 12,15 18,9" />
                  </svg>
                </button>
                <div v-if="activeDropdown === sub.id" class="actions-menu" @click.stop>
                  <button
                    v-if="$can('subscribers:manage')"
                    type="button"
                    @click="showEditForm(sub)"
                    class="menu-item"
                  >
                    Editar
                  </button>
                  <button
                    v-if="$can('subscribers:manage')"
                    type="button"
                    @click="deleteSubscriber(sub)"
                    class="menu-item menu-item-danger"
                  >
                    Eliminar
                  </button>
                </div>
              </div>
            </td>
          </tr>
        </tbody>
      </table>

      <!-- Empty state -->
      <div v-if="!loading.subscribers && subscribers.results.length === 0" class="empty-state">
        <empty-placeholder />
      </div>

      <!-- Pagination -->
      <div class="pagination" v-if="subscribers.total > subscribers.perPage">
        <button
          type="button"
          class="pagination-btn"
          @click="onPageChange(queryParams.page - 1)"
          :disabled="queryParams.page <= 1"
        >
          ‹
        </button>
        <span class="pagination-current">{{ queryParams.page }}</span>
        <button
          type="button"
          class="pagination-btn"
          @click="onPageChange(queryParams.page + 1)"
          :disabled="queryParams.page >= Math.ceil(subscribers.total / subscribers.perPage)"
        >
          ›
        </button>
      </div>
    </div>

    <!-- Modals -->
    <b-modal scroll="keep" :aria-modal="true" :active.sync="isBulkListFormVisible" :width="500" class="has-overflow">
      <subscriber-bulk-list :num-subscribers="this.numSelectedSubscribers" @finished="bulkChangeLists" />
    </b-modal>
    <b-modal scroll="keep" :aria-modal="true" :active.sync="isFormVisible" :width="850" @close="onFormClose">
      <subscriber-form :data="curItem" :is-editing="isEditing" @finished="querySubscribers" />
    </b-modal>
  </div>
</template>

<script>
import Vue from 'vue';
import { mapState } from 'vuex';
import EmptyPlaceholder from '../components/EmptyPlaceholder.vue';
import { uris } from '../constants';
import SubscriberBulkList from './SubscriberBulkList.vue';
import SubscriberForm from './SubscriberForm.vue';

export default Vue.extend({
  components: {
    SubscriberForm,
    SubscriberBulkList,
    EmptyPlaceholder,
  },

  data() {
    return {
      curItem: null,
      isSearchAdvanced: false,
      isEditing: false,
      isFormVisible: false,
      isBulkListFormVisible: false,
      showFilters: false,
      activeDropdown: null,

      bulk: {
        checked: [],
        all: false,
      },

      queryInput: '',

      queryParams: {
        queryExp: '',
        search: '',
        listID: null,
        page: 1,
        orderBy: 'id',
        order: 'desc',
        subStatus: null,
      },
    };
  },

  methods: {
    toggleActionsMenu(id) {
      this.activeDropdown = this.activeDropdown === id ? null : id;
    },

    closeDropdownOnClickOutside(event) {
      if (this.activeDropdown && !this.$el.contains(event.target)) {
        this.activeDropdown = null;
      }
    },

    listCount(lists) {
      if (!lists) return 0;
      return lists.reduce((defVal, item) => (defVal + (item.subscriptionStatus !== 'unsubscribed' ? 1 : 0)), 0);
    },

    showEditForm(sub) {
      this.curItem = sub;
      this.isFormVisible = true;
      this.isEditing = true;
      this.activeDropdown = null;
    },

    showNewForm() {
      this.curItem = {};
      this.isFormVisible = true;
      this.isEditing = false;
    },

    onFormClose() {
      if (this.$route.params.id) {
        this.$router.push({ name: 'subscribers' });
      }
    },

    onPageChange(p) {
      this.querySubscribers({ page: p });
    },

    onSimpleQueryInput(v) {
      const q = v.replace(/'/, "''").trim();
      this.queryParams.queryExp = '';
      this.queryParams.page = 1;
      this.queryParams.search = q.toLowerCase();
    },

    onSubmit() {
      this.querySubscribers({ page: 1 });
    },

    querySubscribers(params) {
      this.queryParams = { ...this.queryParams, ...params };
      const qp = {
        list_id: this.queryParams.listID,
        search: this.queryParams.search,
        query: this.queryParams.queryExp,
        page: this.queryParams.page,
        subscription_status: this.queryParams.subStatus,
        order_by: this.queryParams.orderBy,
        order: this.queryParams.order,
      };
      this.$api.getSubscribers(qp);
    },

    deleteSubscriber(sub) {
      this.$utils.confirm(
        null,
        () => {
          this.$api.deleteSubscriber(sub.id).then(() => {
            this.querySubscribers();
            this.$utils.toast(this.$t('globals.messages.deleted', { name: sub.name }));
          });
        },
      );
      this.activeDropdown = null;
    },

    exportSubscribers() {
      this.$utils.confirm(this.$t('subscribers.confirmExport', { num: this.subscribers.total }), () => {
        const q = new URLSearchParams();
        if (this.queryParams.search) q.append('search', this.queryParams.search);
        if (this.queryParams.listID) q.append('list_id', this.queryParams.listID);
        document.location.href = `${uris.exportSubscribers}?${q.toString()}`;
      });
    },

    // Keep other methods from original component if they are used by modals
    showBulkListForm() { this.isBulkListFormVisible = true; },
    bulkChangeLists() {
      /* ... original logic ... */
    },
    blocklistSubscribers() { /* ... original logic ... */ },
    deleteSubscribers() { /* ... original logic ... */ },
  },

  computed: {
    ...mapState(['subscribers', 'lists', 'loading']),
  },

  mounted() {
    if (this.$route.params.listID) {
      this.queryParams.listID = parseInt(this.$route.params.listID, 10);
    }
    if (this.$route.params.id) {
      this.$api.getSubscriber(parseInt(this.$route.params.id, 10)).then((data) => {
        this.showEditForm(data);
      });
    } else {
      this.querySubscribers();
    }
    document.addEventListener('click', this.closeDropdownOnClickOutside);
  },

  beforeDestroy() {
    document.removeEventListener('click', this.closeDropdownOnClickOutside);
  },
});
</script>

<style scoped>
/* Page layout */
.subscribers-page {
  background: #ffffff;
  min-height: 100%;
  padding: 0;
  display: flex;
  flex-direction: column;
}

.page-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 24px 32px;
  background: #ffffff;
  flex-shrink: 0;
}

.page-title {
  font-size: 32px;
  font-weight: 600;
  color: #000000;
  margin: 0;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 16px;
}

.action-btn,
.filter-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  background: #ffffff;
  border: 1px solid #dcdcdc;
  border-radius: 8px;
  padding: 8px 16px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.2s;
}

.filter-btn {
  background: #f7f3ff;
  border-color: #dcd0ff;
  color: #8b5cf6;
}

.action-btn:hover,
.filter-btn:hover {
  background-color: #f0f0f0;
}

.search-container-header {
  position: relative;
}

.search-input-header {
  background: #ffffff;
  border: 1px solid #dcdcdc;
  border-radius: 8px;
  padding: 8px 16px 8px 40px;
  width: 250px;
}

.search-icon-header {
  position: absolute;
  left: 12px;
  top: 50%;
  transform: translateY(-50%);
  color: #9a9a9a;
}

.new-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  background: #8b5cf6;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  padding: 9px 18px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.2s;
}

.new-btn:hover {
  background: #7c4ee4;
}

/* Table */
.table-container {
  position: relative;
  margin: 24px 32px 32px 32px;
  background: #ffffff;
  border-radius: 12px;
  border: 1px solid #e0e0e0;
  padding: 1.5rem;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  flex-grow: 1;
  min-height: 0;
}

.subscribers-table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0 1rem;
  display: flex;
  flex-direction: column;
  height: 100%;
}

.subscribers-table thead,
.subscribers-table tbody tr {
  display: table;
  width: 100%;
  table-layout: fixed;
  letter-spacing: 0.5px;
}

.subscribers-table thead {
  flex-shrink: 0;
  border-bottom: none;
}

.scrollable-tbody {
  display: block;
  overflow-y: auto;
  flex-grow: 1;
}

.subscribers-table th {
  border-bottom: none;
  background: #ffffff;
  padding: 0rem 1.25rem;
  text-align: left;
  font-weight: 500;
  color: #9a9a9a;
  font-size: 0.8rem;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.subscribers-table td {
  padding: 1.2rem 1.25rem;
  vertical-align: middle;
  background: #ffffff;
  border: 1px solid #e0e0e0;
  border-style: solid;
  border-width: 1px 0;
}

.table-row td:first-child {
  border-left-width: 1px;
  border-top-left-radius: 8px;
  border-bottom-left-radius: 8px;
}

.table-row td:last-child {
  border-right-width: 1px;
  border-top-right-radius: 8px;
  border-bottom-right-radius: 8px;
}

.table-row:hover td {
  background-color: #f8f8f8 !important;
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
}

.status-dot.status-blocklisted,
.status-dot.status-invalid {
  background-color: #ef4444;
}

.list-count-link {
  color: #8b5cf6;
  text-decoration: underline;
}

.options-header,
.opciones-cell {
  width: 80px;
  text-align: center;
}

/* Dropdown */
.opciones-dropdown-container {
  position: relative;
  display: inline-block;
}

.opciones-dropdown-arrow {
  background: transparent;
  border: none;
  cursor: pointer;
  padding: 4px;
  border-radius: 4px;
}

.opciones-dropdown-arrow:hover {
  background: #f0f0f0;
}

.actions-menu {
  position: absolute;
  right: 0;
  top: calc(100% + 5px);
  background: #ffffff;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  z-index: 100;
  width: 150px;
  overflow: hidden;
}

.menu-item {
  display: block;
  width: 100%;
  padding: 10px 16px;
  text-align: left;
  background: none;
  border: none;
  cursor: pointer;
  font-size: 14px;
}

.menu-item:hover {
  background: #f8f8f8;
}

.menu-item-danger {
  color: #ef4444;
}

/* Pagination */
.pagination {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
  padding-top: 24px;
  flex-shrink: 0;
}

.pagination-btn {
  background: #ffffff;
  border: 1px solid #e9ecef;
  color: #6c757d;
  padding: 8px 12px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
}

.pagination-btn:hover:not(:disabled) {
  background: #f8f9fa;
}

.pagination-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.pagination-current {
  background: #8b5cf6;
  color: #ffffff;
  padding: 8px 12px;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 500;
}

/* Loading & Empty */
.loading-overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(255, 255, 255, 0.8);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 10;
}

.spinner {
  width: 24px;
  height: 24px;
  border: 2px solid #f0f0f0;
  border-top: 2px solid #8b5cf6;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.empty-state {
  padding: 48px;
  text-align: center;
  color: #6c757d;
  flex-grow: 1;
  display: flex;
  align-items: center;
  justify-content: center;
}
</style>
