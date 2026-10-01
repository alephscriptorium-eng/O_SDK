import DefaultTheme from 'vitepress/theme';
import { h } from 'vue';
import './custom.css';
import Banner from './Banner.vue';
import Vivo from './Vivo.vue';
import Sello from './Sello.vue';
import Puertas from './Puertas.vue';

// Banner de cabecera (slot layout-top): primero que se ve, en la piel fanzine.
export default {
  extends: DefaultTheme,
  Layout() {
    return h(DefaultTheme.Layout, null, {
      'layout-top': () => h(Banner)
    });
  },
  // Tres piezas para las puertas por rol, usables desde cualquier página en markdown:
  // Vivo (dato leído del sistema al construir), Sello (estado medido de un encargo), Puertas (la lista).
  enhanceApp({ app }) {
    app.component('Vivo', Vivo);
    app.component('Sello', Sello);
    app.component('Puertas', Puertas);
  }
};
