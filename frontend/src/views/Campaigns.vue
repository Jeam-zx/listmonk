<template>
  <div class="campaigns-page">
    <!-- Header -->
    <div class="page-header">
      <h1 class="page-title">Mis Campañas</h1>
      <div class="header-actions">
        <button type="button" class="filter-btn">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polygon points="22,3 2,3 10,12.46 10,19 14,21 14,12.46" />
          </svg>
          Filter
        </button>

        <!-- Search integrated in header -->
        <div class="search-container-header">
          <input
            v-model="queryParams.query"
            @input="getCampaigns"
            type="text"
            placeholder="Nombre o asunto"
            aria-label="Nombre o asunto"
            class="search-input-header"
          />
          <svg class="search-icon-header" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="11" cy="11" r="8" />
            <path d="m21 21-4.35-4.35" />
          </svg>
        </div>

        <button
          v-if="$can('campaigns:manage')"
          type="button"
          @click="$router.push({ name: 'campaign', params: { id: 'new' } })"
          class="nuevo-btn"
          data-cy="btn-new"
        >
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="12" y1="5" x2="12" y2="19" />
            <line x1="5" y1="12" x2="19" y2="12" />
          </svg>
          Nuevo
        </button>
      </div>
    </div>

    <!-- Table -->
    <div class="table-container">
      <div v-if="loading.campaigns" class="loading-overlay">
        <div class="spinner" />
      </div>

      <table class="campaigns-table">
        <thead>
          <tr>
            <th @click="onSort('name', queryParams.order === 'asc' ? 'desc' : 'asc')">
              Nombre
            </th>
            <th>Listas</th>
            <th @click="onSort('views', queryParams.order === 'asc' ? 'desc' : 'asc')">
              Aperturas
            </th>
            <th @click="onSort('clicks', queryParams.order === 'asc' ? 'desc' : 'asc')">
              Clicks
            </th>
            <th @click="onSort('bounces', queryParams.order === 'asc' ? 'desc' : 'asc')">
              Rebotes
            </th>
            <th /> <!-- Columna para opciones -->
          </tr>
        </thead>
        <tbody class="scrollable-tbody">
          <tr
            v-for="campaign in campaigns.results"
            :key="campaign.id"
            :class="{ 'row-running': campaign.status === 'running' }"
            class="table-row"
          >
            <!-- Nombre -->
            <td class="nombre-cell">
              <router-link :to="{ name: 'campaign', params: { id: campaign.id } }" class="campaign-name">
                {{ campaign.name }}
              </router-link>
            </td>

            <!-- Listas -->
            <td class="listas-cell">
              <div class="list-dropdown-container">
                <select class="list-select" aria-label="Listas de la campaña">
                  <option
                    v-for="list in campaign.lists"
                    :key="list.id"
                    :value="list.id"
                  >
                    {{ list.name }}
                  </option>
                </select>
                <svg class="dropdown-arrow" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <polyline points="6,9 12,15 18,9" />
                </svg>
              </div>
            </td>

            <!-- Aperturas -->
            <td class="stats-cell">
              {{ formatNumber(campaign.views) }}
            </td>

            <!-- Clicks -->
            <td class="stats-cell">
              {{ formatNumber(campaign.clicks) }}
            </td>

            <!-- Rebotes -->
            <td class="stats-cell">
              <router-link
                :to="{ name: 'bounces', query: { campaign_id: campaign.id } }"
                class="bounces-link"
              >
                {{ formatNumber(campaign.bounces) }}
              </router-link>
            </td>

            <!-- Opciones (solo flecha hacia abajo) -->
            <td class="opciones-cell">
              <div class="opciones-dropdown-container">
                <button
                  type="button"
                  class="opciones-dropdown-arrow"
                  @click.stop="toggleActionsMenu(campaign.id)"
                  :class="{ 'active': activeDropdown === campaign.id }"
                >
                  <svg class="dropdown-arrow-only" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <polyline points="6,9 12,15 18,9" />
                  </svg>
                </button>

                <!-- Dropdown Menu -->
                <div
                  v-if="activeDropdown === campaign.id"
                  class="actions-menu"
                  @click.stop
                >
                  <button
                    type="button"
                    @click="editCampaign(campaign)"
                    class="menu-item"
                  >
                    Editar
                  </button>
                  <button
                    type="button"
                    @click="deleteCampaign(campaign)"
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
      <div v-if="!loading.campaigns && campaigns.results.length === 0" class="empty-state">
        <empty-placeholder />
      </div>

      <!-- Pagination -->
      <div v-if="campaigns.total > campaigns.perPage" class="pagination">
        <button
          type="button"
          @click="onPageChange(queryParams.page - 1)"
          :disabled="queryParams.page <= 1"
          class="pagination-btn"
        >
          ‹
        </button>
        <span class="pagination-current">{{ queryParams.page }}</span>
        <button
          type="button"
          @click="onPageChange(queryParams.page + 1)"
          :disabled="queryParams.page >= Math.ceil(campaigns.total / campaigns.perPage)"
          class="pagination-btn"
        >
          ›
        </button>
      </div>
    </div>

    <!-- Campaign Preview Modal -->
    <campaign-preview
      v-if="previewItem"
      type="campaign"
      :id="previewItem.id"
      :title="previewItem.name"
      @close="closePreview"
    />
  </div>
</template>

<script>
import dayjs from 'dayjs';
import Vue from 'vue';
import { mapState } from 'vuex';
import CampaignPreview from '../components/CampaignPreview.vue';
import EmptyPlaceholder from '../components/EmptyPlaceholder.vue';

export default Vue.extend({
  components: {
    CampaignPreview,
    EmptyPlaceholder,
  },

  data() {
    return {
      previewItem: null,
      queryParams: {
        page: 1,
        query: '',
        orderBy: 'created_at',
        order: 'desc',
      },
      pollID: null,
      campaignStatsData: {},
      activeDropdown: null,
    };
  },

  methods: {
    // Campaign statuses
    canStart(c) {
      return c.status === 'draft' && !c.sendAt;
    },
    canSchedule(c) {
      return c.status === 'draft' && c.sendAt;
    },
    canPause(c) {
      return c.status === 'running';
    },
    canCancel(c) {
      return c.status === 'running' || c.status === 'paused';
    },
    canResume(c) {
      return c.status === 'paused';
    },
    isSheduled(c) {
      return c.status === 'scheduled' || c.sendAt !== null;
    },
    isDone(c) {
      return c.status === 'finished' || c.status === 'cancelled';
    },
    isRunning(id) {
      return id in this.campaignStatsData;
    },

    formatNumber(num) {
      return num || 0;
    },

    getCancelaciones(campaign) {
      const stats = this.getCampaignStats(campaign);
      return stats.unsubscribes || campaign.unsubscribes || 12;
    },

    toggleActionsMenu(campaignId) {
      if (this.activeDropdown === campaignId) {
        this.activeDropdown = null;
      } else {
        this.activeDropdown = campaignId;
      }
    },

    editCampaign(campaign) {
      this.$router.push({ name: 'campaign', params: { id: campaign.id } });
      this.activeDropdown = null;
    },

    onPageChange(p) {
      this.queryParams.page = p;
      this.getCampaigns();
    },

    onSort(field, direction) {
      this.queryParams.orderBy = field;
      this.queryParams.order = direction;
      this.getCampaigns();
    },

    previewCampaign(c) {
      this.previewItem = c;
      this.activeDropdown = null;
    },

    closePreview() {
      this.previewItem = null;
    },

    getCampaigns() {
      this.$api.getCampaigns({
        page: this.queryParams.page,
        query: this.queryParams.query.replace(/[^\p{L}\p{N}\s]/gu, ' '),
        order_by: this.queryParams.orderBy,
        order: this.queryParams.order,
        no_body: true,
      });
    },

    getCampaignStats(c) {
      if (c.id in this.campaignStatsData) {
        return this.campaignStatsData[c.id];
      }
      return c;
    },

    pollStats() {
      clearInterval(this.pollID);
      this.pollID = setInterval(() => {
        this.$api.getCampaignStats().then((data) => {
          if (data.length === 0) {
            clearInterval(this.pollID);
            if (Object.keys(this.campaignStatsData).length > 0) {
              this.getCampaigns();
              this.campaignStatsData = {};
            }
          } else {
            this.campaignStatsData = data.reduce((obj, cur) => ({ ...obj, [cur.id]: cur }), {});
          }
        }, () => {
          clearInterval(this.pollID);
        });
      }, 1000);
    },

    changeCampaignStatus(c, status) {
      this.$api.changeCampaignStatus(c.id, status).then(() => {
        this.$utils.toast(this.$t('campaigns.statusChanged', { name: c.name, status }));
        this.getCampaigns();
        this.pollStats();
      });
      this.activeDropdown = null;
    },

    async cloneCampaign(name, c) {
      let body = '';
      let bodySource = null;
      await this.$api.getCampaign(c.id).then((data) => {
        body = data.body;
        bodySource = data.bodySource;
      });

      const now = this.$utils.getDate();
      const sendLater = !!c.sendAt;
      let sendAt = null;
      if (sendLater) {
        sendAt = dayjs(c.sendAt).isAfter(now) ? c.sendAt : now.add(7, 'day');
      }

      const data = {
        name,
        subject: c.subject,
        lists: c.lists.map((l) => l.id),
        type: c.type,
        from_email: c.fromEmail,
        content_type: c.contentType,
        messenger: c.messenger,
        tags: c.tags,
        template_id: c.templateId,
        body,
        body_source: bodySource,
        altbody: c.altbody,
        headers: c.headers,
        send_later: sendLater,
        send_at: sendAt,
        archive: c.archive,
        archive_template_id: c.archiveTemplateId,
        archive_meta: c.archiveMeta,
        media: c.media.map((m) => m.id),
      };

      if (c.archive) {
        data.archive_slug = `${name.toLowerCase().replace(/[^a-z0-9]/g, '-')}-${Date.now().toString().slice(-4)}`;
      }

      this.$api.createCampaign(data).then((d) => {
        this.$router.push({ name: 'campaign', params: { id: d.id } });
      });
      this.activeDropdown = null;
    },

    deleteCampaign(c) {
      this.$utils.confirm(this.$t('campaigns.confirmDelete', { name: c.name }), () => {
        this.$api.deleteCampaign(c.id).then(() => {
          this.getCampaigns();
          this.$utils.toast(this.$t('globals.messages.deleted', { name: c.name }));
        });
      });
      this.activeDropdown = null;
    },
  },

  computed: {
    ...mapState(['campaigns', 'loading']),
  },

  mounted() {
    this.getCampaigns();
    this.pollStats();

    document.addEventListener('click', () => {
      this.activeDropdown = null;
    });
  },

  destroyed() {
    clearInterval(this.pollID);
    document.removeEventListener('click', () => {
      this.activeDropdown = null;
    });
  },
});
</script>

<style scoped>
.campaigns-page {
  background: #ffffff;
  min-height: 100%;
  padding: 0;
  display: flex;
  flex-direction: column;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 24px 32px;
  background: #ffffff;
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

.filter-btn {
  background: transparent;
  border: 1px solid #8b5cf6;
  color: #8b5cf6;
  border-radius: 24px;
  padding: 8px 16px;
  font-size: 14px;
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  transition: all 0.2s;
}

.filter-btn:hover {
  background: #8b5cf6;
  color: #ffffff;
}

.search-container-header {
  position: relative;
  display: flex;
  align-items: center;
}

.search-input-header {
  padding: 8px 40px 8px 12px;
  border: 1px solid #e0e0e0;
  border-radius: 6px;
  font-size: 14px;
  color: #333333;
  outline: none;
  width: 200px;
}

.search-input-header::placeholder {
  color: #999999;
}

.search-icon-header {
  position: absolute;
  right: 12px;
  color: #666666;
  pointer-events: none;
}

.nuevo-btn {
  background: #8b5cf6;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  padding: 8px 16px;
  font-size: 14px;
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.nuevo-btn:hover {
  background: #7c3aed;
}

.table-container {
  position: relative;
  margin: 24px 32px 32px 32px;
  background: #ffffff;
  border-radius: 12px;
  border: 1px solid #e0e0e0;
  padding: 1.5rem;
  display: block; /* Permite el scroll */
  max-height: 100%; /* Ocupa el espacio disponible */
  display: flex; /* Nuevo */
  flex-direction: column; /* Nuevo */
  flex-grow: 1; /* Nuevo: permite que el contenedor crezca */
}

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

.campaigns-table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0 1rem; /* Añade espacio vertical entre filas */
  display: table; /* Nuevo */
  flex-shrink: 1; /* Nuevo */
  flex-grow: 1; /* Nuevo */
}

.campaigns-table thead {
  display: table;
  width: 100%;
  table-layout: fixed; /* Fija el ancho de las columnas del header */
}

.scrollable-tbody {
  display: block; /* Permite el scroll */
  max-height: 100%; /* Ocupa el espacio disponible */
}

.scrollable-tbody tr {
  display: table;
  width: 98%;
  table-layout: fixed; /* Fija el ancho de las columnas de las filas */
}

.campaigns-table th {
  background: #ffffff;
  padding: 0rem 1.25rem ;
  width: 98%;
  text-align: left;
  font-weight: 500;
  color: #9a9a9a;
  border-bottom: none; /* Elimina la línea inferior de los headers */
  cursor: pointer;
  font-size: 0.8rem;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

/* Elimina el borde inferior por defecto de las celdas */
.campaigns-table td {
  padding: 1.2rem 1.25rem;
  border-bottom: none;
  vertical-align: middle;
  background: #ffffff; /* Fondo para que el borde se vea bien */
}

.table-row td {
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

/* Constrain the options column to a minimal width */
.campaigns-table th:last-child,
.campaigns-table td.opciones-cell {
  width: 80px;
  text-align: center;
}

.table-row:hover td {
  background-color: #f8f8f8 !important;
}

.table-row.row-running td {
  background: #fff8e1;
}

.campaign-name {
  color: #000000;
  text-decoration: none;
  font-weight: 500;
  font-size: 16px;
}

.campaign-name:hover {
  color: #8b5cf6;
}

.list-dropdown-container {
  position: relative;
  display: inline-block;
}

.list-select {
  background: #f8f9fa;
  border: 1px solid #e9ecef;
  border-radius: 6px;
  padding: 8px 32px 8px 12px;
  font-size: 14px;
  color: #495057;
  cursor: pointer;
  appearance: none;
  min-width: 120px;
}

.opciones-dropdown-container {
  position: relative;
  display: inline-block;
}

.opciones-dropdown-arrow {
  background: transparent;
  border: none;
  padding: 8px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  transition: background-color 0.2s;
}

.opciones-dropdown-arrow:hover {
  background: #f8f9fa;
}

.opciones-dropdown-arrow.active {
  background: #f8f9fa;
}

.dropdown-arrow-only {
  color: #6c757d;
  transition: transform 0.2s;
}

.opciones-dropdown-arrow.active .dropdown-arrow-only {
  transform: rotate(180deg);
}

.opciones-dropdown {
  background: transparent;
  border: none;
  padding: 8px 24px 8px 8px;
  font-size: 14px;
  color: #000000;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
  position: relative;
}

.opciones-dropdown.active {
  background: #f8f9fa;
  border-radius: 6px;
}

.dropdown-arrow {
  position: absolute;
  right: 8px;
  top: 50%;
  transform: translateY(-50%);
  pointer-events: none;
  color: #6c757d;
}

.actions-menu {
  position: absolute;
  top: 100%;
  right: 0;
  background: #ffffff;
  border: 1px solid #e9ecef;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  z-index: 1000;
  min-width: 140px;
  overflow: hidden;
}

.menu-item {
  display: block;
  width: 100%;
  padding: 12px 16px;
  background: none;
  border: none;
  text-align: left;
  font-size: 14px;
  color: #495057;
  cursor: pointer;
  transition: background-color 0.2s;
}

.menu-item:hover {
  background: #f8f9fa;
}

.menu-item-danger:hover {
  background: #f8d7da;
  color: #dc3545;
}

.menu-link {
  text-decoration: none;
  color: #495057;
}

.menu-link:hover {
  background: #f8f9fa;
  color: #495057;
}

.stats-cell {
  font-size: 16px;
  color: #000000;
  font-weight: 500;
}

.bounces-link {
  color: #000000;
  text-decoration: none;
  font-weight: 500;
}

.bounces-link:hover {
  color: #8b5cf6;
}

.empty-state {
  padding: 48px;
  text-align: center;
  color: #6c757d;
}

.pagination {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
  padding: 24px;
  border-top: 1px solid #f0f0f0;
  flex-shrink: 0; /* Evita que la paginación se encoja */
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
</style>
