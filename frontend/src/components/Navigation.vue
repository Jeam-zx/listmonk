<template>
  <div class="sidebar-container">
    <nav class="main-nav">
      <!-- Dashboard -->
      <router-link :to="{ name: 'dashboard' }" class="nav-item" :class="{ 'is-active': activeItem.dashboard }" data-cy="dashboard">
        <b-icon icon="view-grid-outline" />
        <span class="nav-label">{{ $t('globals.terms.dashboard') }}</span>
      </router-link>

      <!-- Lists -->
      <router-link :to="{ name: 'lists' }" class="nav-item" :class="{ 'is-active': activeItem.lists }" data-cy="lists">
        <b-icon icon="format-list-bulleted-square" />
        <span class="nav-label">{{ $t('globals.terms.lists', 2) }}</span>
      </router-link>

      <!-- Campaigns -->
      <router-link :to="{ name: 'campaigns' }" class="nav-item" :class="{ 'is-active': activeItem.campaigns }" data-cy="campaigns">
        <b-icon icon="rocket-launch-outline" />
        <span class="nav-label">{{ $t('globals.terms.campaigns', 2) }}</span>
      </router-link>

      <!-- Subscribers -->
      <router-link :to="{ name: 'subscribers' }" class="nav-item" :class="{ 'is-active': activeItem.subscribers }" data-cy="subscribers">
        <b-icon icon="account-multiple-outline" />
        <span class="nav-label">{{ $t('globals.terms.subscribers', 2) }}</span>
      </router-link>

      <!-- Templates -->
      <router-link v-if="$can('templates:get')" :to="{ name: 'templates' }" class="nav-item" :class="{ 'is-active': activeItem.templates }" data-cy="templates">
        <b-icon icon="file-document-outline" />
        <span class="nav-label">{{ $t('globals.terms.templates') }}</span>
      </router-link>

      <!-- Media -->
      <router-link v-if="$can('media:*')" :to="{ name: 'media' }" class="nav-item" :class="{ 'is-active': activeItem.media }" data-cy="media">
        <b-icon icon="folder-multiple-image" />
        <span class="nav-label">{{ $t('menu.media') }}</span>
      </router-link>
    </nav>

    <nav class="secondary-nav">
      <!-- Analytics -->
      <router-link v-if="$can('campaigns:get_analytics')" :to="{ name: 'campaignAnalytics' }" class="nav-item" :class="{ 'is-active': activeItem.campaignAnalytics }" data-cy="analytics">
        <b-icon icon="chart-line" />
        <span class="nav-label">{{ $t('globals.terms.analytics') }}</span>
      </router-link>

      <!-- Settings -->
      <router-link v-if="$can('settings:*')" :to="{ name: 'settings' }" class="nav-item" :class="{ 'is-active': activeItem.settings }" data-cy="settings">
        <b-icon icon="cog-outline" />
        <span class="nav-label">{{ $t('menu.settings') }}</span>
      </router-link>
    </nav>
  </div>
</template>

<script>
export default {
  name: 'NavigationRedesigned',

  props: {
    activeItem: { type: Object, default: () => ({}) },
  },
};
</script>

<style scoped>
.sidebar-container {
  width: 250px;
  height: 90vh;
  background-color: #ffffff;
  border-right: 1px solid #e5e7eb;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  padding: 2rem 1.5rem;
  font-family: 'Inter', sans-serif;
}

.main-nav,
.secondary-nav {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.nav-item {
  display: flex;
  align-items: center;
  padding: 0.75rem 1rem;
  border-radius: 0.75rem;
  text-decoration: none;
  color: #4b5563;
  font-weight: 500;
  transition: background-color 0.2s ease, color 0.2s ease;
}

.nav-item:hover {
  background-color: #f3f4f6;
}

.nav-item.is-active {
  background-color: #ede9fe;
  color: #7c3aed;
  font-weight: 600;
}

.nav-item .icon {
  margin-right: 1rem;
}

.nav-label {
  font-size: 1rem;
}

@media (max-width: 768px) {
  .sidebar-container {
    width: 100%;
    height: auto;
    flex-direction: row;
    align-items: center;
    padding: 1rem;
    border-top: 1px solid #e5e7eb;
    border-right: none;
    position: fixed;
    bottom: 0;
    left: 0;
    background-color: #ffffff;
    z-index: 10;
  }

  .main-nav,
  .secondary-nav {
    flex-direction: row;
    justify-content: space-around;
    width: 100%;
  }

  .nav-label {
    display: none;
  }

  .nav-item {
    justify-content: center;
  }

  .nav-item .icon {
    margin-right: 0;
  }
}
</style>