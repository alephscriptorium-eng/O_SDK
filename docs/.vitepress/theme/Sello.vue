<script setup>
// Sello de estado de un encargo. Tres valores, y ninguno es marketing:
//   probado   → lo completó un agente en frío (solo el repo y el encargo); cita su reporte
//   ejercido  → se hizo en la demo, por quien escribió el protocolo; cita su reporte
//   en-obras  → todavía no se cumple entero; dice qué falta
import { computed } from 'vue';
import { useData } from 'vitepress';
import { data as roles } from './roles.data.mjs';

const props = defineProps({ rol: String, id: String });
const { theme } = useData();

const TEXTO = { probado: 'probado en frío', ejercido: 'ejercido en la demo', 'en-obras': 'en obras' };

const encargo = computed(() => {
  const puerta = roles.find((r) => r.rol === props.rol);
  return puerta ? puerta.encargos.find((e) => e.id === props.id) : null;
});
const prueba = computed(() =>
  encargo.value && encargo.value.prueba ? `${theme.value.back.repo}/blob/main/${encargo.value.prueba}` : null
);
</script>

<template>
  <span
    v-if="encargo"
    class="zine-sello"
    :data-estado="encargo.estado"
    :data-prueba="encargo.prueba || ''"
  ><strong>{{ TEXTO[encargo.estado] || encargo.estado }}</strong><template v-if="encargo.medido"> · {{ encargo.medido }}</template><template v-if="prueba"> · <a :href="prueba">reporte</a></template><template v-if="encargo.falta"> · falta: {{ encargo.falta }}</template></span>
  <span v-else class="zine-sello" data-estado="sin-estado" data-prueba=""><strong>sin estado</strong></span>
</template>
