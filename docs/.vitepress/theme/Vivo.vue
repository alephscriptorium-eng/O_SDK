<script setup>
// Dato vivo: se lee del sistema al construir (docs/.vitepress/config.mjs → themeConfig.vivo), no se
// escribe a mano en ninguna página. El atributo data-vivo es el centinela del gate de verdad.
import { useData } from 'vitepress';

defineProps({ k: String });
const { theme } = useData();
</script>

<template><span :data-vivo="k">{{ theme.vivo ? theme.vivo[k] : '' }}</span></template>
