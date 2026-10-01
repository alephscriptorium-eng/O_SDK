<script setup>
// Las puertas por rol, con el estado medido de cada encargo. Sale del frontmatter de docs/roles/*.md.
import { withBase } from 'vitepress';
import { data as roles } from './roles.data.mjs';
import Sello from './Sello.vue';
</script>

<template>
  <div class="zine-puertas">
    <section v-for="r in roles" :key="r.rol" class="zine-puerta">
      <a class="zine-puerta__nombre" :href="withBase(r.url)">{{ r.puerta }}</a>
      <p class="zine-puerta__lema">{{ r.lema }}</p>
      <ul class="zine-puerta__encargos">
        <li v-for="e in r.encargos" :key="e.id">
          <span class="zine-puerta__encargo">{{ e.titulo }}</span>
          <Sello :rol="r.rol" :id="e.id" corto />
        </li>
      </ul>
    </section>
    <!-- La sexta puerta ya existía: el manual del agente. No es una página de rol; se enlaza. -->
    <section class="zine-puerta">
      <a class="zine-puerta__nombre" :href="withBase('/AGENTES')">Agente</a>
      <p class="zine-puerta__lema">Si eres el agente que llega al repo: cinco leyes, las acciones sin vuelta atrás y las trampas que ya costaron una parada.</p>
    </section>
  </div>
</template>
