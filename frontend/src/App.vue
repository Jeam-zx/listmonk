<template>
  <div id="app">
    <b-navbar :fixed-top="true" v-if="$root.isLoaded">
      <template #brand>
        <div class="logo">
          <router-link :to="{ name: 'dashboard' }">
            <img class="full" src="@/assets/logo.svg" alt="" />
            <img class="favicon" src="@/assets/favicon.png" alt="" />
          </router-link>
        </div>
      </template>
      <template #end>
        <navigation v-if="isMobile" :is-mobile="isMobile" :active-item="activeItem" :active-group="activeGroup"
          @toggleGroup="toggleGroup" @doLogout="doLogout" />

        <b-navbar-dropdown class="user" tag="div" right v-else>
          <template v-if="profile.username" #label>
            <span class="user-avatar">
              <img v-if="profile.avatar" :src="profile.avatar" alt="" />
              <span v-else>{{ profile.username[0].toUpperCase() }}</span>
            </span>
          </template>

          <b-navbar-item class="user-name" tag="router-link" to="/user/profile">
            <strong>{{ profile.username }}</strong>
            <div class="is-size-7">{{ profile.name }}</div>
          </b-navbar-item>

          <b-navbar-item href="#">
            <router-link to="/user/profile">
              <b-icon icon="account-outline" /> {{ $t('users.profile') }}
            </router-link>
          </b-navbar-item>
          <b-navbar-item href="#">
            <a href="#" @click.prevent="doLogout"><b-icon icon="logout-variant" /> {{ $t('users.logout') }}</a>
          </b-navbar-item>
        </b-navbar-dropdown>
      </template>
    </b-navbar>

    <div class="wrapper" v-if="$root.isLoaded">
      <section class="sidebar">
        <div class="sidebar-container">
          <b-sidebar position="static" mobile="hide" :fullheight="true" :open="true" :can-cancel="false">
            <div class="sidebar-content">
              <b-menu :accordion="false">
                <navigation v-if="!isMobile" :is-mobile="isMobile" :active-item="activeItem" :active-group="activeGroup"
                  @toggleGroup="toggleGroup" />
              </b-menu>
            </div>
          </b-sidebar>
        </div>
      </section>

      <div class="main">
        <div class="global-notices" v-if="isGlobalNotices">
          <div v-if="serverConfig.needs_restart" class="notification is-danger">
            {{ $t('settings.needsRestart') }}
            &mdash;
            <b-button class="is-primary" size="is-small"
              @click="$utils.confirm($t('settings.confirmRestart'), reloadApp)">
              {{ $t('settings.restart') }}
            </b-button>
          </div>

          <template v-if="serverConfig.update">
            <div v-if="serverConfig.update.update.is_new" class="notification is-success">
              {{ $t('settings.updateAvailable', {
                version: `${serverConfig.update.update.release_version}
              (${$utils.getDate(serverConfig.update.update.release_date).format('DD MMM YY')})`,
              }) }}
              <a :href="serverConfig.update.update.url" target="_blank" rel="noopener noreferer">View</a>
            </div>

            <template v-if="serverConfig.update.messages && serverConfig.update.messages.length > 0">
              <div v-for="m in serverConfig.update.messages" class="notification"
                :class="{ [m.priority === 'high' ? 'is-danger' : 'is-info']: true }" :key="m.title">
                <h3 class="is-size-5" v-if="m.title"><strong>{{ m.title }}</strong></h3>
                <p v-if="m.description">{{ m.description }}</p>
                <a v-if="m.url" :href="m.url" target="_blank" rel="noopener noreferer">View</a>
              </div>
            </template>
          </template>

          <div v-if="serverConfig.has_legacy_user" class="notification is-danger">
            <b-icon icon="warning-empty" />
            Remove the <code>admin_username</code> and <code>admin_password</code> fields from the TOML
            configuration file or environment variables. If you are using APIs, create and use new API credentials
            before removing them. Visit
            <router-link :to="{ name: 'users' }">
              Admin -> Settings -> Users
            </router-link> dashboard. <a href="https://listmonk.app/docs/upgrade/#upgrading-to-v4xx" target="_blank"
              rel="noopener noreferer">Learn more.</a>
          </div>
        </div>

        <router-view :key="$route.fullPath" />
      </div>
    </div>

    <b-loading v-if="!$root.isLoaded" active />
  </div>
</template>

<script>
import Vue from 'vue';
import { mapState } from 'vuex';
import { uris } from './constants';

import Navigation from './components/Navigation.vue';

export default Vue.extend({
  name: 'App',

  components: {
    Navigation,
  },

  data() {
    return {
      activeItem: {},
      activeGroup: {},
      windowWidth: window.innerWidth,
    };
  },

  watch: {
    $route(to) {
      this.activeItem = { [to.name]: true };
      if (to.meta.group) {
        this.activeGroup = { [to.meta.group]: true };
      } else {
        this.activeGroup = {};
      }
    },
  },

  methods: {
    toggleGroup(group, state) {
      this.activeGroup = state ? { [group]: true } : {};
    },

    reloadApp() {
      this.$api.reloadApp().then(() => {
        this.$utils.toast('Reloading app ...');

        const pollId = setInterval(() => {
          this.$api.getHealth().then(() => {
            clearInterval(pollId);
            document.location.reload();
          });
        }, 500);
      });
    },

    doLogout() {
      this.$api.logout().then(() => {
        document.location.href = uris.root;
      });
    },

    listenEvents() {
      const reMatchLog = /(.+?)\.go:\d+:(.+?)$/im;
      const evtSource = new EventSource(uris.errorEvents, { withCredentials: true });
      let numEv = 0;
      evtSource.onmessage = (e) => {
        if (numEv > 50) {
          return;
        }
        numEv += 1;

        const d = JSON.parse(e.data);
        if (d && d.type === 'error') {
          const msg = reMatchLog.exec(d.message.trim());
          this.$utils.toast(msg[2], 'is-danger', null, true);
        }
      };
    },
  },

  computed: {
    ...mapState(['serverConfig', 'profile']),

    isGlobalNotices() {
      return (this.serverConfig.needs_restart
        || this.serverConfig.has_legacy_user
        || (this.serverConfig.update
        && this.serverConfig.update.messages
        && this.serverConfig.update.messages.length > 0));
    },

    version() {
      return import.meta.env.VUE_APP_VERSION;
    },

    isMobile() {
      return this.windowWidth <= 768;
    },
  },

  mounted() {
    this.$api.getLists({ minimal: true, per_page: 'all' });

    window.addEventListener('resize', () => {
      this.windowWidth = window.innerWidth;
    });

    this.listenEvents();
  },
});
</script>

<style lang="scss">
@import "assets/style.scss";
@import "assets/icons/fontello.css";

/* Simple sidebar styling to match the screenshot */
.sidebar {
  padding: 1rem;
}

.sidebar-container {
  background-color: white;
  overflow: hidden;
  height: calc(100vh - 2rem);
  margin-top: 1rem;
  border: 1px solid #f3f4f6;
}

.sidebar-content {
  height: 100%;
  overflow-y: auto;
  padding: 0;
}

/* Override Buefy sidebar styles */
.sidebar .sidebar-container .sidebar {
  background-color: transparent !important;
  border-right: none !important;
  box-shadow: none !important;
}

.sidebar .sidebar-container .sidebar-content {
  background-color: transparent !important;
}

/* Layout adjustments */
.wrapper {
  display: flex;
  min-height: calc(100vh - 3.25rem);
}

.main {
  flex: 1;
  padding-left: 1rem;
}

/* Mobile adjustments */
@media (max-width: 768px) {
  .sidebar {
    padding: 0.5rem;
  }
  
  .sidebar-container {
    border-radius: 1rem;
    margin-top: 0.5r  em;
    height: calc(100vh - 1rem);
  }
  
  .main {
    padding-left: 0.5rem;
  }
}
</style>
