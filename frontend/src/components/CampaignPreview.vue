<template>
  <div class="side-preview-panel">
    <div class="side-preview-card">
      <header class="side-preview-head">
        <h4>{{ title }}</h4>
        <b-button icon-left="close" class="is-pulled-right is-small" @click="close" />
      </header>
      <section class="side-preview-body preview">
        <b-loading :active="isLoading" :is-full-page="false" />
        <form v-if="isPost" method="post" :action="previewURL" target="iframe" ref="form">
          <input v-if="templateId" type="hidden" name="template_id" :value="templateId" />
          <input v-if="contentType" type="hidden" name="content_type" :value="contentType" />
          <input v-if="templateType" type="hidden" name="template_type" :value="templateType" />
          <input v-if="archiveMeta" type="hidden" name="archive_meta" :value="archiveMeta" />
          <input v-if="body" type="hidden" name="body" :value="body" />
        </form>

        <iframe id="iframe" name="iframe" ref="iframe" :title="title" :src="isPost ? 'about:blank' : previewURL"
          @load="onLoaded" />
      </section>
      <footer class="side-preview-foot has-text-right">
        <b-button @click="close">
          {{ $t('globals.buttons.close') }}
        </b-button>
      </footer>
    </div>
  </div>
</template>

<script>
import { uris } from '../constants';

export default {
  name: 'CampaignPreview',

  props: {
    isPost: { type: Boolean, default: false },
    id: { type: Number, default: 0 },
    title: { type: String, default: '' },
    type: { type: String, default: '' },
    templateType: { type: String, default: '' },
    archiveMeta: { type: String, default: null },
    body: { type: String, default: '' },
    contentType: { type: String, default: '' },
    templateId: { type: [Number, null], default: null },
    isArchive: { type: Boolean, default: false },
  },

  data() {
    return {
      isLoading: true,
    };
  },

  methods: {
    close() {
      this.$emit('close');
    },

    onLoaded(l) {
      if (l.srcElement.contentWindow.location.href === 'about:blank') {
        return;
      }
      this.isLoading = false;
    },
  },

  computed: {
    previewURL() {
      let uri = 'about:blank';

      if (this.type === 'campaign') {
        uri = this.isArchive ? uris.previewCampaignArchive : uris.previewCampaign;
      } else if (this.type === 'template') {
        if (this.id) {
          uri = uris.previewTemplate;
        } else {
          uri = uris.previewRawTemplate;
        }
      }

      return uri.replace(':id', this.id);
    },
  },

  mounted() {
    setTimeout(() => {
      if (this.isPost) {
        this.$refs.form.submit();
      }
    }, 100);
  },
};
</script>

<style scoped>
.side-preview-panel {
  position: fixed;
  top: 0;
  right: 0;
  width: 50%; /* O un valor fijo como 600px */
  max-width: 700px;
  height: 100vh;
  background-color: white;
  box-shadow: -3px 0 10px rgba(0, 0, 0, 0.15);
  z-index: 1050; /* Asegúrate de que sea un valor alto */
  display: flex;
  flex-direction: column;
  transition: transform 0.3s ease-in-out;
}

/* Opcional: para animar la salida si se controla con una clase */
/* .side-preview-panel.is-hidden {
  transform: translateX(100%);
} */

.side-preview-card {
  display: flex;
  flex-direction: column;
  height: 100%;
  width: 100%;
}

.side-preview-head {
  padding: 1rem 1.5rem;
  border-bottom: 1px solid #dbdbdb;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-shrink: 0;
}

.side-preview-head h4 {
  font-size: 1.25rem;
  font-weight: 600;
  margin: 0;
  line-height: 1.2;
}

.side-preview-body {
  flex-grow: 1;
  padding: 1.5rem;
  overflow-y: auto;
  position: relative; /* Para b-loading */
}

.side-preview-body iframe {
  width: 100%;
  height: 100%;
  border: 1px solid #ccc; /* Para visualizar mejor el iframe */
}

.side-preview-foot {
  padding: 1rem 1.5rem;
  border-top: 1px solid #dbdbdb;
  flex-shrink: 0;
}
</style>
