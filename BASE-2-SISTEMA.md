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
| Cliente | GUI web + sbot, modo `full` | pantalla `:3000` | `docker-compose.yml` `oasis-dev` |
| Pub | nodo de federación en VPS | terminal deploy | `OASIS_PUB/scripts/deploy.sh` |
| Identidad | clave SSB soberana | `secret` | volumen `.ssb`, `SSB_server.js` |
| IA local | modelo `gguf` en el nodo | prompt | `src/AI/`, `download_ai_model` |
| ECOin | wallet P2P opcional | wallet | `ECOIN_DOCKERIZE/`, servicio `ecoin-wallet` |
| Fork-guards | 4 divergencias vs upstream | — | ver `docs/PUB/UPGRADE-PROTOCOL.md` §2 |

## 3 · Lecturas cruzadas

Hechos de la tabla, no consignas. Frase-puente: «no es una app en un servidor
de otro; es un nodo que es tuyo y habla con otros nodos».

## 4 · Por superficie

- Portada: §1 + puente.
- Proyecto: tabla de roles (cliente/pub) → flujo devops.
- Docs técnicas: los protocolos de operación como columna de referencia.

## Decisiones tomadas (2026-07-21)

- El portal surfacea solo superficies propias + los 2 protocolos; la doc
  importada de upstream se enlaza a la forja (`srcExclude`), no se re-renderiza.
- Dominio del mundo: `o-sdk.escrivivir.co` (Pages, custom domain → base `/`).
- Legacy landing HTML preservado en `docs/public/legacy.html`.
