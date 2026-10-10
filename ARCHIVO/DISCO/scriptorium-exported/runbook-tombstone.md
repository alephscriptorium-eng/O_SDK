# Runbook · deshacer la siembra de Campamento (tombstones) desde el bot nº 3 (WP-O135, D-O33)

**Ejecutado el 2026-10-10** desde el retro ya mudado a la máquina operadora (`runbook-mudanza.md`), conectado
al pub real, con GO del custodio para todo y **un bloque cada vez, mirando** («que no la liemos»). Método:
`docs/PUB/TEMPLATE-PROTOCOL.md` §9. Herramienta: `pub/tools/seed-tombstone.js` por `pub/scripts/retro-tombstone.sh
--pub-id '@/snvahva…' --evidence o135 --yes <bloque>`. Entrada: el ledger de la siembra
(`oasis/keys/plantilla-campamento.json` = `vps/ledger-vps.json`). Salida: `vps/ledger-tombstones.json` (93
entradas, 2 saltadas) y `vps/tombstone-o135.jsonl` (un registro por bloque con `before/after`).

Revoca la decisión «sin tombstone de lo sembrado» del dosier de WP-O134 (2026-10-09), por decisión del custodio
(2026-10-10): se retira todo lo que se generó. Un tombstone solo esconde: los 147 mensajes de la siembra siguen
en los logs del bot, del pub, del HUB y de quien replicara.

Dry-run previo (gates `notPub · configPubFalse · isAuthor · pubConnected` todos `true`): 11 bloques, 117
mensajes previstos.

| # | Bloque | Objetivos | Δseq | seq | Nota |
|---|---|---|---|---|---|
| 1 | `clearnet` | 15 `clearnetItem on:false` (14 objetos + el post) | 15 | 151 → 166 | pub y HUB en 166 a los segundos; sitemap de 28 a 19 coincidencias (las 19 son de otros habitantes); **las rutas de detalle siguen 200** (no miran `clearnetItem off`) |
| 2 | `entrada` | 1 post | 1 | 166 → 167 | — |
| 3 | `maps` | 2 | 2 | 167 → 169 | HUB en 169; `/c/maps/<id>` sigue 200 por URL directa (la ruta lee por id sin tombstones: upstream) |
| 4 | `wiki` | 5 | 5 | 169 → 174 | — |
| 5 | `mailing` | 4 → 2 OPEN tombstonadas; 2 CLOSED **no retirables** | 2 | 174 → 176 | «Mailing list not found»: el ledger guarda la clave del primer privado y el modelo indexa por `listId`; resuelto el `listId`, el modelo sigue sin verlas porque por el socket `createLogStream` llega cifrado. Son privadas con **un solo miembro (el bot)**: `--skip mailing:lista_colectivos --skip mailing:lista_intercsos` |
| 6 | `events` | 7 | 7 | 176 → 183 | — |
| 7 | `calendars` | 7 | 1 + 6 | 183 → 184 → 190 | el público (asamblea general) con `deleteCalendarById`; los 6 de tribu paraban con «Not the author» (la punta es un sobre `tribe-msg` que el modelo no desenvuelve): tombstone **envuelto** con `createHelpers().encryptTombstone`, como `maps_model` |
| 8 | `rooms` | 7 | 7 | 190 → 197 | — |
| 9 | `invites` | 22 marcadores | 44 | 197 → 241 | `removeOpenInvite` no las veía (`TRIBE_LOG_TYPES` sin `tribe-open-invite` en 1.2.5): los dos tombstones por tribu se publican desde el feed propio |
| 10 | `subtribes` | 9 | 9 | 241 → 250 | — |
| 11 | `tribes` | 16 | 16 | 250 → 266 | 15 en claro + 1 envuelto (asamblea_internodos, privada) |

Total: **115 retiradas**; feed del bot `150 → 266` (1 `oasisVersion` + 115). Dry-run final: 0 pendientes.

Medidas al cierre: pub `seq_pub=266 pub_follows_feed=true`; HUB `seq 266`; `check pre-mudanza3` del host → pub,
HUB, bot **Δ0**; `snapshot retro-post-tombstone` (local) `seq=266 registros=266 → cuadra · sbot=266` con
`tombstone=50`, `tribe-invite-tombstone=22`, `tribe-open-invite-tombstone=22`, `clearnetItem=30`, `tribe-msg=32`
(25 de la siembra + 6 calendarios + 1 tribu envueltos). HUB: `hub-disk.sh prune-cache`; sitemap 188 URLs con **0**
del bot; portada `/c` sin Campamento; `/c/events/:id`, `/c/maps/:id`, `/c/calendars/:id` responden 200 por URL
directa (TEMPLATE §9, «lo que queda»). Sala 02 del sitio (`parlament/campamento/`): pendiente de retirar del sitio
(enlaza objetos retirados).

Hallazgos de código (Oasis 1.2.5) que la herramienta tuvo que rodear: `TRIBE_LOG_TYPES` sin `tribe-open-invite`;
`deleteCalendarById` no desenvuelve sobres `tribe-msg`; `mailing_model` no indexa listas CLOSED por el socket;
las rutas de detalle de `/c` no filtran tombstones ni `clearnetItem off`.
