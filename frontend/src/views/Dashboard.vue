<template>
  <div class="dashboard-layout">
    <!-- Main Content -->
    <section class="dashboard-content">
      <!-- Header -->
      <header class="dashboard-header">
        <h1 class="dashboard-title">
          {{ $utils.niceDate(new Date()) }}
        </h1>
      </header>

      <!-- Messages Sent Card -->
      <div class="messages-card">
        <div class="messages-content">
          <div class="messages-info">
            <svg class="message-icon" width="24" height="24" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 4.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
            </svg>
            <span class="messages-label">{{ $t('dashboard.messagesSent') || 'Mensajes enviados' }}</span>
          </div>
          <span class="messages-count">
            {{ isCountsLoading ? '...' : $utils.niceNumber(counts.messages) }}
          </span>
        </div>
      </div>

      <!-- Stats Cards Grid -->
      <div class="stats-grid">
        <!-- Mis Listas -->
        <div class="stat-card lists-card">
          <div v-if="isCountsLoading" class="loading-overlay">
            <div class="spinner"></div>
          </div>
          <div class="stat-content">
            <div class="stat-header">
              <svg class="stat-icon" width="24" height="24" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 10h16M4 14h16M4 18h16" />
              </svg>
              <span class="stat-title">{{ $tc('globals.terms.list', 2) || 'Listas' }}</span>
            </div>
            <div class="stat-details">
              <div class="detail-item">{{ $utils.niceNumber(counts.lists.public || 0) }} {{ $t('lists.types.public') || 'Pública' }}</div>
              <div class="detail-item">{{ $utils.niceNumber(counts.lists.private || 0) }} {{ $t('lists.types.private') || 'Privada' }}</div>
              <div class="detail-item">{{ $utils.niceNumber(counts.lists.optinSingle || 0) }} {{ $t('lists.optins.single') || 'Confirmación simple' }}</div>
              <div class="detail-item">{{ $utils.niceNumber(counts.lists.optinDouble || 0) }} {{ $t('lists.optins.double') || 'Confirmación doble' }}</div>
            </div>
          </div>
          <div class="stat-number">
            {{ isCountsLoading ? '...' : $utils.niceNumber(counts.lists.total || 0) }}
          </div>
        </div>

        <!-- Suscriptores -->
        <div class="stat-card subscribers-card">
          <div v-if="isCountsLoading" class="loading-overlay">
            <div class="spinner"></div>
          </div>
          <div class="stat-content">
            <div class="stat-header">
              <svg class="stat-icon" width="24" height="24" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
              </svg>
              <span class="stat-title">{{ $tc('globals.terms.subscriber', 2) || 'Suscriptores' }}</span>
            </div>
            <div class="stat-details">
              <div class="detail-item">{{ $utils.niceNumber(counts.subscribers.blocklisted || 0) }} {{ $t('subscribers.status.blocklisted') || 'Bloqueada' }}</div>
              <div class="detail-item">{{ $utils.niceNumber(counts.subscribers.orphans || 0) }} {{ $t('dashboard.orphanSubs') || 'Huérfanos' }}</div>
            </div>
          </div>
          <div class="stat-number">
            {{ isCountsLoading ? '...' : formatLargeNumber(counts.subscribers.total || 0) }}
          </div>
        </div>

        <!-- Campañas -->
        <div class="stat-card campaigns-card">
          <div v-if="isCountsLoading" class="loading-overlay">
            <div class="spinner"></div>
          </div>
          <div class="stat-content">
            <div class="stat-header">
              <svg class="stat-icon" width="24" height="24" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5.882V19.24a1.76 1.76 0 01-3.417.592l-2.147-6.15M18 13a3 3 0 100-6M5.436 13.683A4.001 4.001 0 017 6h1.832c4.1 0 7.625-1.234 9.168-3v14c-1.543-1.766-5.067-3-9.168-3H7a3.988 3.988 0 01-1.564-.317z" />
              </svg>
              <span class="stat-title">{{ $tc('globals.terms.campaign', 2) || 'Campañas' }}</span>
            </div>
            <div class="stat-details">
              <div v-for="(num, status) in counts.campaigns.byStatus" :key="status" class="detail-item">
                {{ $utils.niceNumber(num) }} {{ $t(`campaigns.status.${status}`) || getStatusLabel(status) }}
                <span v-if="status === 'running'" class="running-indicator">
                  <div class="mini-spinner"></div>
                </span>
              </div>
            </div>
          </div>
          <div class="stat-number">
            {{ isCountsLoading ? '...' : $utils.niceNumber(counts.campaigns.total || 0) }}
          </div>
        </div>
      </div>

      <!-- Charts Section -->
      <div class="charts-grid">
        <div class="chart-card">
          <div v-if="isChartsLoading" class="loading-overlay">
            <div class="spinner"></div>
          </div>
          <h3 class="chart-title">
            {{ $t('dashboard.campaignViews') || 'Vista de campaña' }}
          </h3>
          <div class="chart-container">
            <Chart v-if="campaignViews && !isChartsLoading" type="line" :data="campaignViews" />
            <div v-else class="chart-placeholder">
              <div class="chart-zero">1</div>
            </div>
          </div>
        </div>

        <div class="chart-card">
          <div v-if="isChartsLoading" class="loading-overlay">
            <div class="spinner"></div>
          </div>
          <h3 class="chart-title chart-title-right">
            {{ $t('dashboard.linkClicks') || 'Enlaces cliqueados' }}
          </h3>
          <div class="chart-container">
            <Chart v-if="campaignClicks && !isChartsLoading" type="line" :data="campaignClicks" />
            <div v-else class="chart-placeholder">
              <div class="chart-zero">1</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Cache Notice -->
      <p v-if="settings && settings['app.cache_slow_queries']" class="cache-notice">
        *{{ $t('globals.messages.slowQueriesCached') }}
        <a href="https://listmonk.app/docs/maintenance/performance/" target="_blank" rel="noopener noreferrer" class="cache-link">
          <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
          </svg>
          {{ $t('globals.buttons.learnMore') }}
        </a>
      </p>
    </section>

    <!-- Right Sidebar -->
    <aside class="right-sidebar">
      <!-- Recent Campaigns -->
      <div class="sidebar-card recent-campaigns">
        <div class="sidebar-header">
          <svg class="sidebar-icon" width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
          </svg>
          <h3 class="sidebar-title">{{ $t('dashboard.recentCampaigns') || 'Campañas Recientes' }}</h3>
        </div>
        <div class="sidebar-content">
          <div v-if="recentCampaigns.length === 0" class="empty-state">
            <p class="empty-text">{{ $t('campaigns.noRecentCampaigns') || 'No hay campañas recientes' }}</p>
          </div>
          <div v-else class="campaigns-list">
            <div v-for="campaign in recentCampaigns" :key="campaign.id" class="campaign-item">
              <div class="campaign-info">
                <h4 class="campaign-name">{{ campaign.name }}</h4>
                <p class="campaign-date">{{ $utils.niceDate(campaign.created_at) }}</p>
              </div>
              <span class="campaign-status" :class="`status-${campaign.status}`">
                {{ $t(`campaigns.status.${campaign.status}`) || getStatusLabel(campaign.status) }}
              </span>
            </div>
          </div>
        </div>
      </div>

      <!-- Notifications and Alerts -->
      <div class="sidebar-card notifications">
        <div class="sidebar-header">
          <svg class="sidebar-icon notification-icon" width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-5 5v-5zM4.868 19.718A10.968 10.968 0 016.75 19h2.5A10.968 10.968 0 0112 19.718M4.868 19.718A10.968 10.968 0 014 16.25v-2.5A10.968 10.968 0 014.868 11M4.868 19.718L11 13.75M19.132 19.718A10.968 10.968 0 0117.25 19h-2.5A10.968 10.968 0 0112 19.718M19.132 19.718A10.968 10.968 0 0120 16.25v-2.5A10.968 10.968 0 0119.132 11M19.132 19.718L13 13.75" />
          </svg>
          <h3 class="sidebar-title">{{ $t('dashboard.notifications') || 'Notificaciones y Alertas' }}</h3>
        </div>
        <div class="sidebar-content">
          <div v-if="notifications.length === 0" class="empty-state">
            <p class="empty-text">{{ $t('dashboard.noNotifications') || 'No hay notificaciones' }}</p>
          </div>
          <div v-else class="notifications-list">
            <div v-for="notification in notifications" :key="notification.id" class="notification-item">
              <div class="notification-indicator" :class="`type-${notification.type}`"></div>
              <div class="notification-content">
                <p class="notification-message">{{ notification.message }}</p>
                <span class="notification-time">{{ $utils.niceDate(notification.created_at) }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </aside>
  </div>
</template>

<script>
import dayjs from 'dayjs';
import { mapState } from 'vuex';
import { colors } from '../constants';
import Chart from '../components/Chart.vue';

export default {
  name: 'Dashboard',
  components: {
    Chart,
  },

  data() {
    return {
      isChartsLoading: true,
      isCountsLoading: true,
      campaignViews: null,
      campaignClicks: null,
      counts: {
        lists: {},
        subscribers: {},
        campaigns: {},
        messages: 0,
      },
      recentCampaigns: [],
      notifications: [],
    };
  },

  computed: {
    ...mapState(['settings']),
  },

  methods: {
    makeChart(data) {
      if (data.length === 0) {
        return {};
      }
      return {
        labels: data.map((d) => dayjs(d.date).format('DD MMM')),
        datasets: [
          {
            data: [...data.map((d) => d.count)],
            borderColor: colors.primary,
            borderWidth: 2,
            pointHoverBorderWidth: 5,
            pointBorderWidth: 0.5,
          },
        ],
      };
    },

    formatLargeNumber(num) {
      if (num >= 1000) {
        return (num / 1000).toFixed(1) + 'K';
      }
      return this.$utils.niceNumber(num);
    },

    getStatusLabel(status) {
      const labels = {
        'draft': 'Borrador',
        'scheduled': 'Programada',
        'running': 'En progreso',
        'paused': 'Pausada',
        'finished': 'Finalizada',
        'cancelled': 'Cancelada'
      };
      return labels[status] || status;
    },

    loadRecentCampaigns() {
      // Simulated data - replace with actual API call
      this.recentCampaigns = [
        {
          id: 1,
          name: 'Newsletter Semanal',
          status: 'finished',
          created_at: new Date('2025-06-19')
        },
        {
          id: 2,
          name: 'Promoción Especial',
          status: 'running',
          created_at: new Date('2025-06-18')
        }
      ];
    },

    loadNotifications() {
      // Simulated data - replace with actual API call
      this.notifications = [
        {
          id: 1,
          type: 'success',
          message: 'Campaña enviada exitosamente',
          created_at: new Date('2025-06-20')
        },
        {
          id: 2,
          type: 'warning',
          message: 'Lista con suscriptores inactivos',
          created_at: new Date('2025-06-20')
        }
      ];
    },
  },

  mounted() {
    // Pull the counts.
    this.$api.getDashboardCounts().then((data) => {
      this.counts = data;
      this.isCountsLoading = false;
    });

    // Pull the charts.
    this.$api.getDashboardCharts().then((data) => {
      this.isChartsLoading = false;
      this.campaignViews = this.makeChart(data.campaignViews);
      this.campaignClicks = this.makeChart(data.linkClicks);
    });

    // Load sidebar data
    this.loadRecentCampaigns();
    this.loadNotifications();
  },
};
</script>

<style scoped>
.dashboard-layout {
  display: flex;
  min-height: 100vh;
  background-color: #ffffff;
}

.dashboard-content {
  flex: 1;
  padding: 2rem;
  overflow-y: auto;
  max-height: 100vh;
}

.right-sidebar {
  width: 320px;
  padding: 2rem 1.5rem;
  border-left: 1px solid #e5e7eb;
  background-color: #ffffff;
  overflow-y: auto;
  max-height: 100vh;
}

.dashboard-header {
  margin-bottom: 2rem;
}

.dashboard-title {
  font-size: 1.5rem;
  font-weight: 600;
  color: #1f2937;
  margin: 0;
}

.messages-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 0.5rem;
  padding: 1.5rem;
  margin-bottom: 2rem;
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1);
}

.messages-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.messages-info {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.message-icon {
  color: #6b7280;
}

.messages-label {
  color: #1f2937;
  font-weight: 500;
}

.messages-count {
  font-size: 2rem;
  font-weight: bold;
  color: #1f2937;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.stat-card {
  border-radius: 0.75rem;
  padding: 1.5rem;
  position: relative;
  min-height: 200px;
  display: flex;
  flex-direction: column;
}

.lists-card {
  background: linear-gradient(135deg, #f7d2fd 0%, #f5b4ff 100%);
}

.subscribers-card {
  background: linear-gradient(135deg, #e4daff 0%, #d9beff 100%);
}

.campaigns-card {
  background: linear-gradient(135deg, #d9beff 0%, #c69dff 100%);
}

.stat-content {
  flex: 1;
}

.stat-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 1rem;
}

.stat-icon {
  color: #1f2937;
}

.stat-title {
  color: #1f2937;
  font-weight: 600;
  font-size: 1.1rem;
}

.stat-details {
  margin-bottom: 1rem;
}

.detail-item {
  color: #1f2937;
  font-size: 0.875rem;
  margin-bottom: 0.25rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.stat-number {
  font-size: 4rem;
  font-weight: bold;
  color: #1f2937;
  text-align: right;
  line-height: 1;
  align-self: flex-end;
  margin-top: auto;
}

.charts-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.chart-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 0.5rem;
  padding: 1.5rem;
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1);
  position: relative;
  height: 300px;
  display: flex;
  flex-direction: column;
}

.chart-title {
  font-size: 1.125rem;
  font-weight: 600;
  color: #1f2937;
  margin: 0 0 1rem 0;
  flex-shrink: 0;
}

.chart-title-right {
  text-align: right;
}

.chart-container {
  flex: 1;
  min-height: 0;
  position: relative;
}

.chart-placeholder {
  height: 100%;
  background-color: #f3f4f6;
  border-radius: 0.5rem;
  display: flex;
  align-items: flex-end;
  padding: 1rem;
}

.chart-zero {
  font-size: 0.875rem;
  color: #6b7280;
}

/* Sidebar Styles */
.sidebar-card {
  background: white;
  border: 2px solid #3b82f6;
  border-radius: 1rem;
  margin-bottom: 1.5rem;
  overflow: hidden;
}

.sidebar-card.notifications {
  border-color: #e5e7eb;
}

.sidebar-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 1.25rem;
  border-bottom: 1px solid #f3f4f6;
}

.sidebar-icon {
  color: #6b7280;
}

.notification-icon {
  color: #10b981;
}

.sidebar-title {
  font-size: 1rem;
  font-weight: 600;
  color: #1f2937;
  margin: 0;
}

.sidebar-content {
  max-height: 300px;
  overflow-y: auto;
}

.empty-state {
  padding: 2rem 1.25rem;
  text-align: center;
}

.empty-text {
  color: #6b7280;
  font-size: 0.875rem;
  margin: 0;
}

.campaigns-list,
.notifications-list {
  padding: 0.5rem 0;
}

.campaign-item,
.notification-item {
  padding: 1rem 1.25rem;
  border-bottom: 1px solid #f3f4f6;
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.campaign-item:last-child,
.notification-item:last-child {
  border-bottom: none;
}

.campaign-info {
  flex: 1;
}

.campaign-name {
  font-size: 0.875rem;
  font-weight: 500;
  color: #1f2937;
  margin: 0 0 0.25rem 0;
}

.campaign-date {
  font-size: 0.75rem;
  color: #6b7280;
  margin: 0;
}

.campaign-status {
  font-size: 0.75rem;
  padding: 0.25rem 0.5rem;
  border-radius: 0.375rem;
  font-weight: 500;
}

.status-finished {
  background-color: #d1fae5;
  color: #065f46;
}

.status-running {
  background-color: #dbeafe;
  color: #1e40af;
}

.status-draft {
  background-color: #f3f4f6;
  color: #374151;
}

.notification-indicator {
  width: 0.5rem;
  height: 0.5rem;
  border-radius: 50%;
  flex-shrink: 0;
}

.type-success {
  background-color: #10b981;
}

.type-warning {
  background-color: #f59e0b;
}

.type-error {
  background-color: #ef4444;
}

.notification-content {
  flex: 1;
}

.notification-message {
  font-size: 0.875rem;
  color: #1f2937;
  margin: 0 0 0.25rem 0;
}

.notification-time {
  font-size: 0.75rem;
  color: #6b7280;
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
  border-radius: inherit;
  z-index: 10;
}

.spinner {
  width: 2rem;
  height: 2rem;
  border: 2px solid #e5e7eb;
  border-top: 2px solid #7c3aed;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

.mini-spinner {
  width: 0.75rem;
  height: 0.75rem;
  border: 1px solid #e5e7eb;
  border-top: 1px solid #1f2937;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  display: inline-block;
}

.running-indicator {
  margin-left: 0.25rem;
}

.cache-notice {
  color: #6b7280;
  font-size: 0.875rem;
  margin: 0;
}

.cache-link {
  color: #6b7280;
  text-decoration: none;
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
}

.cache-link:hover {
  color: #4b5563;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

@media (max-width: 1024px) {
  .dashboard-layout {
    flex-direction: column;
  }
  
  .right-sidebar {
    width: 100%;
    border-left: none;
    border-top: 1px solid #e5e7eb;
    max-height: none;
  }
  
  .stats-grid {
    grid-template-columns: 1fr;
  }
  
  .charts-grid {
    grid-template-columns: 1fr;
  }
  
  .dashboard-content {
    padding: 1rem;
    max-height: none;
  }
  
  .stat-number {
    font-size: 3rem;
  }
}
</style>