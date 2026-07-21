import DefaultTheme from 'vitepress/theme';
import { h } from 'vue';
import './custom.css';
import Banner from './Banner.vue';

// Banner de cabecera (slot layout-top): primero que se ve, en la piel fanzine.
export default {
  extends: DefaultTheme,
  Layout() {
    return h(DefaultTheme.Layout, null, {
      'layout-top': () => h(Banner)
    });
  }
};
