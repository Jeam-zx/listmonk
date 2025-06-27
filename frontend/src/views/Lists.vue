<template>
  <section class="lists-container">
    <!-- Header moderno -->
    <header class="modern-header">
      <div class="header-left">
        <h1 class="page-title">
          Mis Listas
          <span v-if="!isNaN(lists.total)" class="count">({{ lists.total }})</span>
        </h1>
      </div>
      <div class="header-right">
        <!-- Restaurar el filtro original funcional -->
        <b-field>
          <b-button type="is-light" icon-left="filter-variant" @click="showFilters = !showFilters">
            Filter
          </b-button>
        </b-field>
        
        <div class="search-container">
          <form @submit.prevent="getLists">
            <div class="search-field">
              <input
                v-model="queryParams.query"
                type="text"
                placeholder="Buscar listas..."
                class="search-input"
                ref="query"
                data-cy="query"
              />
              <button type="submit" class="search-btn" data-cy="btn-query">
                <i class="icon-search"></i>
              </button>
            </div>
          </form>
        </div>
        <button 
          v-if="$can('lists:manage_all')" 
          class="new-btn" 
          @click="showNewForm" 
          data-cy="btn-new"
        >
          <i class="icon-plus"></i>
          Nuevo
        </button>
      </div>
    </header>

    <!-- Tabla moderna -->
    <div class="table-container">
      <div class="table-wrapper" v-if="!loading.listsFull">
        <table class="modern-table">
          <thead>
            <tr>
              <th class="table-header">Nombre</th>
              <th class="table-header text-center">
                <span class="subscriber-icon">👥</span>
              </th>
              <th class="table-header">Estatus</th>
              <th class="table-header">Creada en</th>
              <th class="table-header">Actualizada</th>
              <th class="table-header">Opciones</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="list in lists.results" :key="list.id" class="table-row">
              <td class="table-cell">
                <div class="list-name-container">
                  <a 
                    :href="`/lists/${list.id}`" 
                    @click.prevent="showEditForm(list)"
                    class="list-name"
                  >
                    {{ list.name }}
                  </a>
                  <div v-if="list.tags && list.tags.length > 0" class="tags-container">
                    <span 
                      v-for="tag in list.tags" 
                      :key="tag" 
                      class="tag"
                    >
                      {{ tag }}
                    </span>
                  </div>
                </div>
              </td>
              
              <td class="table-cell text-center">
                <template v-if="$can('subscribers:get_all', 'subscribers:get')">
                  <router-link 
                    :to="`/subscribers/lists/${list.id}`"
                    class="subscriber-count"
                  >
                    {{ $utils.formatNumber(list.subscriberCount) }}
                  </router-link>
                </template>
                <template v-else>
                  <span class="subscriber-count">
                    {{ $utils.formatNumber(list.subscriberCount) }}
                  </span>
                </template>
              </td>
              
              <td class="table-cell">
                <span 
                  :class="['status-badge', list.type === 'private' ? 'status-private' : 'status-public']"
                >
                  <i :class="list.type === 'private' ? 'icon-lock' : 'icon-globe'"></i>
                  {{ list.type === 'private' ? 'Privada' : 'Pública' }}
                </span>
              </td>
              
              <td class="table-cell date-cell">
                {{ $utils.niceDate(list.createdAt) }}
              </td>
              
              <td class="table-cell date-cell">
                {{ $utils.niceDate(list.updatedAt) }}
              </td>
              
              <td class="table-cell">
                <div class="options-container">
                  <div class="dropdown-modern">
                    <button class="options-trigger">
                      <i class="icon-document"></i>
                      <i class="icon-copy"></i>
                      <i class="icon-chevron-down"></i>
                    </button>
                    <div class="dropdown-menu-modern">
                      <a 
                        href="#" 
                        @click.prevent="showEditForm(list)" 
                        class="dropdown-item-modern"
                        data-cy="btn-edit"
                      >
                        Editar
                      </a>
                      <a 
                        v-if="$can('lists:manage') || $canList(list.id, 'list:manage')" 
                        href="#"
                        @click.prevent="deleteList(list)" 
                        class="dropdown-item-modern delete-option"
                        data-cy="btn-delete"
                      >
                        Eliminar
                      </a>
                    </div>
                  </div>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      
      <!-- Loading state -->
      <div v-if="loading.listsFull" class="loading-container">
        <div class="loading-spinner"></div>
        <p>Cargando listas...</p>
      </div>
      
      <!-- Empty state -->
      <div v-if="!loading.listsFull && lists.results && lists.results.length === 0" class="empty-state">
        <empty-placeholder />
      </div>
    </div>

    <!-- Paginación moderna -->
    <div v-if="lists.results && lists.results.length > 0" class="pagination-container">
      <div class="pagination-info">
        Mostrando {{ (queryParams.page - 1) * lists.perPage + 1 }} a 
        {{ Math.min(queryParams.page * lists.perPage, lists.total) }} de {{ lists.total }} resultados
      </div>
      <div class="pagination-controls">
        <button 
          @click="onPageChange(queryParams.page - 1)"
          :disabled="queryParams.page === 1"
          class="pagination-btn"
        >
          <i class="icon-chevron-left"></i>
        </button>
        
        <span class="pagination-pages">
          <button 
            v-for="page in getPaginationPages()" 
            :key="page"
            @click="onPageChange(page)"
            :class="['pagination-page', { active: page === queryParams.page }]"
          >
            {{ page }}
          </button>
        </span>
        
        <button 
          @click="onPageChange(queryParams.page + 1)"
          :disabled="queryParams.page >= Math.ceil(lists.total / lists.perPage)"
          class="pagination-btn"
        >
          <i class="icon-chevron-right"></i>
        </button>
      </div>
    </div>

    <!-- Modal del formulario (mantiene la funcionalidad original) -->
    <b-modal 
      scroll="keep" 
      :aria-modal="true" 
      :active.sync="isFormVisible" 
      :width="600" 
      @close="onFormClose"
    >
      <list-form :data="curItem" :is-editing="isEditing" @finished="formFinished" />
    </b-modal>

    <!-- Mensaje de cache (si aplica) -->
    <p v-if="settings['app.cache_slow_queries']" class="cache-notice">
      *{{ $t('globals.messages.slowQueriesCached') }}
      <a 
        href="https://listmonk.app/docs/maintenance/performance/" 
        target="_blank" 
        rel="noopener noreferer"
        class="cache-link"
      >
        <i class="icon-link"></i> {{ $t('globals.buttons.learnMore') }}
      </a>
    </p>
  </section>
</template>

<script>
import Vue from 'vue';
import { mapState } from 'vuex';
import EmptyPlaceholder from '../components/EmptyPlaceholder.vue';
import ListForm from './ListForm.vue';

export default Vue.extend({
  components: {
    ListForm,
    EmptyPlaceholder,
  },

  data() {
    return {
      // Current list item being edited.
      curItem: null,
      isEditing: false,
      isFormVisible: false,
      lists: [],
      queryParams: {
        page: 1,
        query: '',
        orderBy: 'id',
        order: 'asc',
      },
      showFilters: false,
    };
  },

  methods: {
    onPageChange(p) {
      this.queryParams.page = p;
      this.getLists();
    },

    onSort(field, direction) {
      this.queryParams.orderBy = field;
      this.queryParams.order = direction;
      this.getLists();
    },

    // Show the edit list form.
    showEditForm(list) {
      this.curItem = list;
      this.isFormVisible = true;
      this.isEditing = true;
    },

    // Show the new list form.
    showNewForm() {
      this.curItem = {};
      this.isFormVisible = true;
      this.isEditing = false;
    },

    formFinished() {
      this.getLists();
    },

    onFormClose() {
      if (this.$route.params.id) {
        this.$router.push({ name: 'lists' });
      }
    },

    filterStatuses(list) {
      const out = { ...list.subscriberStatuses };
      if (list.optin === 'single') {
        delete out.unconfirmed;
        delete out.confirmed;
      }
      return out;
    },

    getLists() {
      this.$api.queryLists({
        page: this.queryParams.page,
        query: this.queryParams.query.replace(/[^\p{L}\p{N}\s]/gu, ' '),
        order_by: this.queryParams.orderBy,
        order: this.queryParams.order,
      }).then((resp) => {
        this.lists = resp;
      });

      // Also fetch the minimal lists for the global store that appears
      // in dropdown menus on other pages like import and campaigns.
      this.$api.getLists({ minimal: true, per_page: 'all' });
    },

    deleteList(list) {
      this.$utils.confirm(
        this.$t('lists.confirmDelete'),
        () => {
          this.$api.deleteList(list.id).then(() => {
            this.getLists();
            this.$utils.toast(this.$t('globals.messages.deleted', { name: list.name }));
          });
        },
      );
    },

    createOptinCampaign(list) {
      const data = {
        name: this.$t('lists.optinTo', { name: list.name }),
        subject: this.$t('lists.confirmSub', { name: list.name }),
        lists: [list.id],
        from_email: this.settings['app.from_email'],
        content_type: 'richtext',
        messenger: 'email',
        type: 'optin',
      };

      this.$api.createCampaign(data).then((d) => {
        this.$router.push({ name: 'campaign', hash: '#content', params: { id: d.id } });
      });
      return false;
    },

    getPaginationPages() {
      const totalPages = Math.ceil(this.lists.total / this.lists.perPage);
      const current = this.queryParams.page;
      const pages = [];
      
      // Mostrar páginas alrededor de la actual
      for (let i = Math.max(1, current - 2); i <= Math.min(totalPages, current + 2); i++) {
        pages.push(i);
      }
      
      return pages;
    },
  },

  computed: {
    ...mapState(['loading', 'settings']),
  },

  mounted() {
    if (this.$route.params.id) {
      this.$api.getList(parseInt(this.$route.params.id, 10)).then((data) => {
        this.showEditForm(data);
      });
    } else {
      this.getLists();
    }
  },
});
</script>

<style scoped>
/* Estilos modernos para replicar el diseño de la imagen */
.lists-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 24px;
  background-color: #ffffff;
}

/* Header moderno */
.modern-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
  padding-bottom: 16px;
}

.header-left .page-title {
  font-size: 24px;
  font-weight: 600;
  color: #1f2937;
  margin: 0;
}

.header-left .count {
  color: #6b7280;
  font-weight: 400;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 12px;
}

.filter-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;
  background: #ffffff;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  color: #374151;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.filter-btn:hover {
  background: #f9fafb;
  border-color: #9ca3af;
}

.search-container {
  position: relative;
}

.search-field {
  display: flex;
  align-items: center;
  position: relative;
}

.search-input {
  width: 240px;
  padding: 8px 40px 8px 12px;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 14px;
  outline: none;
  transition: border-color 0.2s;
}

.search-input:focus {
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.search-btn {
  position: absolute;
  right: 8px;
  padding: 4px;
  background: none;
  border: none;
  color: #6b7280;
  cursor: pointer;
}

.new-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.2s;
}

.new-btn:hover {
  background: #2563eb;
}

/* Tabla moderna */
.table-container {
  background: white;
  border-radius: 12px;
  border: 1px solid #e5e7eb;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.modern-table {
  width: 100%;
  border-collapse: collapse;
}

.table-header {
  padding: 16px;
  text-align: left;
  font-weight: 500;
  font-size: 14px;
  color: #374151;
  background: #f9fafb;
  border-bottom: 1px solid #e5e7eb;
}

.table-header.text-center {
  text-align: center;
}

.subscriber-icon {
  font-size: 16px;
}

.table-row {
  border-bottom: 1px solid #f3f4f6;
  transition: background-color 0.2s;
}

.table-row:hover {
  background: #f9fafb;
}

.table-cell {
  padding: 16px;
  font-size: 14px;
  color: #1f2937;
  vertical-align: middle;
}

.table-cell.text-center {
  text-align: center;
}

.list-name-container {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.list-name {
  font-weight: 500;
  color: #1f2937;
  text-decoration: none;
  transition: color 0.2s;
}

.list-name:hover {
  color: #3b82f6;
}

.tags-container {
  display: flex;
  gap: 4px;
  flex-wrap: wrap;
}

.tag {
  padding: 2px 8px;
  background: #f3f4f6;
  color: #6b7280;
  border-radius: 4px;
  font-size: 12px;
  font-weight: 400;
}

.subscriber-count {
  color: #3b82f6;
  text-decoration: none;
  font-weight: 500;
  transition: color 0.2s;
}

.subscriber-count:hover {
  color: #2563eb;
}

.status-badge {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px 12px;
  border-radius: 16px;
  font-size: 12px;
  font-weight: 500;
}

.status-private {
  background: #fef3c7;
  color: #92400e;
}

.status-public {
  background: #d1fae5;
  color: #065f46;
}

.date-cell {
  color: #6b7280;
}

/* Opciones modernas según la imagen */
.options-container {
  display: flex;
  justify-content: center;
}

.dropdown-modern {
  position: relative;
}

.options-trigger {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 8px 12px;
  background: #f8f9fa;
  border: 1px solid #e9ecef;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s;
}

.options-trigger:hover {
  background: #e9ecef;
  border-color: #dee2e6;
}

.dropdown-menu-modern {
  position: absolute;
  right: 0;
  top: 100%;
  background: white;
  border: 1px solid #e9ecef;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  min-width: 120px;
  z-index: 10;
  opacity: 0;
  visibility: hidden;
  transform: translateY(-8px);
  transition: all 0.2s;
  margin-top: 4px;
}

.dropdown-modern:hover .dropdown-menu-modern {
  opacity: 1;
  visibility: visible;
  transform: translateY(0);
}

.dropdown-item-modern {
  display: block;
  padding: 12px 16px;
  color: #495057;
  text-decoration: none;
  font-size: 14px;
  transition: background-color 0.2s;
  border-bottom: 1px solid #f8f9fa;
}

.dropdown-item-modern:last-child {
  border-bottom: none;
}

.dropdown-item-modern:hover {
  background: #f8f9fa;
  color: #212529;
}

.dropdown-item-modern.delete-option:hover {
  background: #f8d7da;
  color: #721c24;
}

/* Iconos para las opciones */
.icon-document::before { content: "📄"; }
.icon-copy::before { content: "📋"; }
.icon-chevron-down::before { content: "⌄"; }

/* Paginación */
.pagination-container {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 24px;
  padding-top: 16px;
}

.pagination-info {
  color: #6b7280;
  font-size: 14px;
}

.pagination-controls {
  display: flex;
  align-items: center;
  gap: 8px;
}

.pagination-btn {
  padding: 8px;
  background: white;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  cursor: pointer;
  color: #374151;
  transition: all 0.2s;
}

.pagination-btn:hover:not(:disabled) {
  background: #f9fafb;
  border-color: #9ca3af;
}

.pagination-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.pagination-pages {
  display: flex;
  gap: 4px;
}

.pagination-page {
  padding: 8px 12px;
  background: white;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  cursor: pointer;
  color: #374151;
  font-size: 14px;
  transition: all 0.2s;
}

.pagination-page:hover {
  background: #f9fafb;
  border-color: #9ca3af;
}

.pagination-page.active {
  background: #3b82f6;
  border-color: #3b82f6;
  color: white;
}

/* Estados de carga y vacío */
.loading-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 48px;
  color: #6b7280;
}

.loading-spinner {
  width: 32px;
  height: 32px;
  border: 3px solid #e5e7eb;
  border-top: 3px solid #3b82f6;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: 16px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.empty-state {
  padding: 48px;
}

.cache-notice {
  margin-top: 16px;
  color: #6b7280;
  font-size: 12px;
}

.cache-link {
  color: #6b7280;
  text-decoration: none;
}

.cache-link:hover {
  color: #374151;
}

/* Iconos (usando clases CSS para iconos) */
.icon-filter::before { content: "⚙️"; }
.icon-search::before { content: "🔍"; }
.icon-plus::before { content: "+"; }
.icon-more::before { content: "⋯"; }
.icon-edit::before { content: "✏️"; }
.icon-upload::before { content: "⬆️"; }
.icon-rocket::before { content: "🚀"; }
.icon-trash::before { content: "🗑️"; }
.icon-lock::before { content: "🔒"; }
.icon-globe::before { content: "🌐"; }
.icon-chevron-left::before { content: "‹"; }
.icon-chevron-right::before { content: "›"; }
.icon-link::before { content: "🔗"; }

/* Responsive */
@media (max-width: 768px) {
  .modern-header {
    flex-direction: column;
    gap: 16px;
    align-items: stretch;
  }
  
  .header-right {
    justify-content: space-between;
  }
  
  .search-input {
    width: 200px;
  }
  
  .pagination-container {
    flex-direction: column;
    gap: 16px;
  }
}
</style>
