# BASE 2 — EL SISTEMA

> Obedece a BASE-1. Sustancia + inventario referenciado del mundo `oasis-sdk`.
> Primera pasada.

## 1 · La sustancia

**Un contenedor que arranca un nodo SSB completo (cliente web + replicación
P2P + IA opcional), con la identidad persistida en un volumen y guards que
impiden que el auto-update destructivo del upstream corra en Docker.**
⟨`docker-entrypoint.sh` · `src/backend/backend.js` (guard `/update`) ·
`src/server/ssb_config.js` (override por entorno)⟩

Categoría pública: **red social auto-alojada (FOSS, SSB)**.

## 2 · Elementos

| Elemento | Qué es | Imagen | Referencia real |
| -------- | ------ | ------ | --------------- |
| Cliente | GUI web + sbot, modo `full` | pantalla `:3000` | `docker-compose.yml` `oasis-client` |
| Pub | nodo de federación en VPS | terminal deploy | `pub/scripts/deploy.sh` |
| Identidad | clave SSB soberana | `secret` | volumen `.ssb`, `SSB_server.js` |
| IA local | modelo `gguf` en el nodo | prompt | `src/AI/`, `download_ai_model` |
| ECOin | wallet P2P opcional | wallet | `ecoin/`, servicio `ecoin-wallet` |
| Banco del pub | cartera del pub y renta básica | bot de cartera | `docs/PUB/ECOIN-PROTOCOL.md`, `devops/scripts/hub-wallet.sh` |
| HUB clearnet | lectura pública en la web de lo que cada habitante marca | `/c` | `docs/PUB/HUB-PROTOCOL.md`, `pub/config/hub/` |
| Teatro | obras como sitios estáticos firmados | catálogo | `docs/PUB/TEATRO-PROTOCOL.md` |
| Puertas | una receta por rol, con estado medido | sello | `docs/roles/`, `docs/.vitepress/theme/roles.data.mjs` |
| Fork-guards | 5 divergencias vs upstream | — | ver `docs/PUB/UPGRADE-PROTOCOL.md` §2 |

## 3 · Lecturas cruzadas

Hechos de la tabla, no consignas. Frase-puente: «no es una app en un servidor
de otro; es un nodo que es tuyo y habla con otros nodos».

## 4 · Por superficie

- Portada: §1 + puente.
- Proyecto: tabla de roles (cliente/pub) → flujo devops.
- Docs técnicas: los protocolos de operación como columna de referencia.
- Puertas: quién llega y qué le encarga a su agente; la secuencia en la receta, el detalle en el
  protocolo (D-O18).

## Decisiones tomadas (2026-07-21)

- El portal surfacea solo superficies propias + los 2 protocolos; la doc
  importada de upstream se enlaza a la forja (`srcExclude`), no se re-renderiza.
- Dominio del mundo: `o-sdk.escrivivir.co` (Pages, custom domain → base `/`).
- Legacy landing HTML preservado en `docs/public/legacy.html`.

## Decisiones tomadas (2026-10-01, D-O26)

- El portal gana **puertas por rol** (`docs/roles/`), de menos a más: cliente, pub, economía,
  «hazlo tuyo», mantener. Lo que había no se mueve ni se renombra.
- Los protocolos de operación son hoy once, no dos: se quedan en «Operación» y las puertas apuntan
  a ellos.
- La landing antigua deja de publicarse (enlazaba a la cuenta anulada y cargaba fuentes de
  terceros: WP-O72, WP-O65) y se conserva en `ARCHIVO/portal/legacy.html`.
- Excepción a «la doc de upstream no se re-renderiza»: la guía de Mastodon ya estaba publicada;
  se conserva su URL y se enlaza desde la puerta del cliente como guía de upstream.
