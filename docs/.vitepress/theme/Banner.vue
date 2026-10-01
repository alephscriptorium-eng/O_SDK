<script setup>
import { withBase } from 'vitepress';
import Vivo from './Vivo.vue';
</script>

<template>
  <div class="zine-banner" role="note">
    <span class="zine-banner__tag">Nota · a quien corresponda</span>
    <span class="zine-banner__body">
      O_SDK es un <em>wrapper</em> Docker <strong>no oficial</strong> de
      <a href="https://solarnethub.com/" target="_blank" rel="noreferrer">Oasis · SolarNET.HuB</a>:
      unos ficheros para levantarlo en contenedores. Hoy lleva Oasis
      <Vivo k="oasisVersion" /> y sostiene un pub de verdad; lo probado y lo que
      sigue en obras, en <a :href="withBase('/roles/')">¿Quién llega?</a>
      Software libre, <em>work in progress</em>, sin prisa.
    </span>
  </div>
</template>
