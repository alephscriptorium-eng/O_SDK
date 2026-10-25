# WP-O147 · Upgrade a Oasis 1.3.8 (1.3.2 → 1.3.8; 1.3.3-1.3.7 quedan dentro del salto)

Rama `upgrade/oasis-1.3.8` desde `main` befb7ed6 (merge de WP-O146). 2026-10-25 (local 17:06-17:34Z; host 17:40-18:11Z). Tercer ciclo con el protocolo v3
(`docs/PUB/UPGRADE-PROTOCOL.md`). Encargo del custodio: «vamos a lanzar el protocolo de upgrade». Alcance: pub, HUB y bot de
cartera de la instancia Scriptorium. Fuera: el cliente real (cerrado, D-O39), el bot retro (deprecated, D-O36), `ecoind`, la
maint-ui (prohibida durante el ciclo) y `caps.shs` (ciclo 6: «mantener»).

## 1. Estado de partida

**Host** (`deploy-status.sh`, 2026-10-25 ≈ 16:40Z, solo lectura):

- Journal: último registro `target=pub`, `oasisVersion=1.3.2`, `gitSha=d3432424`, 2026-10-18T10:49:30Z,
  `mode=server+hub+wallet-engine-on`.
- Piezas vivas: `oasis-pub-scriptorium` (server, `Up 36 hours`), `oasis-pub-hub` (backend), `oasis-pub-wallet-bot` (backend):
  los tres **1.3.2**, `running healthy`, «imagen al día». `src/` en disco del host: 1.3.2. Engine 26.1.5. HUB y bot `connected out`
  con el pub, 4 pares cada uno. `ecoind` `Up 5 weeks (healthy)`.
- Deriva: `Dockerfile`, entrypoint, compose, Caddyfile, plantilla nginx, configs de HUB y bot y `tools/*.js` **iguales que
  HEAD**. `.dockerignore` DISTINTO y fuera de la historia (layout `OASIS_PUB/`: no convergible hasta E0; cumple §4).
- Restos de rollback del ciclo anterior: `/opt/oasis-scriptorium/src.old-1.3.0`, `/srv/oasis/src-1.3.0.tgz`, imagen `:1.3.0`.
- Directorio: ciclo 6, `pub.escrivivir.co` **VERDE**. Disco `/` 43 %, `/srv/oasis` 47 %; `hub-disk`, `ecoin-disk` (`wallet.dat`
  600) OK; `capacity`: 1 aviso (capa del contenedor 716 MB, se vacía al recrear).

**Preflight** (`upgrade-preflight.sh`, tras `git fetch oasis-upstream`: trae 1.3.3 `ca3c2325` … 1.3.8 `09b829f8`, un commit
«Oasis release» por versión):

```
LOCAL=1.3.2  UPSTREAM=1.3.8  DESPLEGADA=1.3.2  OBJETIVO=1.3.8
OLD_REF=a44bce44  (Oasis release 1.3.2)      NEW_REF=09b829f8  (Oasis release 1.3.8 = punta de oasis-upstream/main)
pub en modo server: 19 de los 32 ficheros que carga · backends y cliente: 153 · activos: 22 · src/base: 13
  pub: long_text.js, opinion_categories.js, config-manager.js, state-manager.js, banking_model.js, comments_model.js,
       crypto_model.js, industry_model.js, karma_model.js, SSB_server.js, blob_prefetch.js, db2_legacy.js, feed_guard.js,
       long_content.js, network_pause.js, server/package.json, phone_module.js, ssb_config.js, ssb_metadata.js
caps.shs local = cap actual de la red (ciclo 6): MANTENER (§5)
WARN x1 (el esperado: upstream por delante)  rc=1
```

`SSB_server.js` cambia (+4/−1): carga **tres plugins nuevos** del sbot (`blob_prefetch`, `feed_guard`, `long_content`), sin
tocar la capa de base de datos (`db2_legacy.js` sigue siendo el puente a `ssb-db2`; `annex` de `db2.tsv` 0 rotos) → **sin
cambio de motor**: UM y UR no aplican.

**Local**: Docker Desktop 29.4.1; `oasis-pub-scriptorium:latest` = `420ceeb70182` (1.3.2, build de WP-O146), los tres nodos
del stack local parados 7 días en esa imagen; bot con el motor encendido (`ssb-config.engine-on`), como el host. Foto base
`pre138` (17:08:23Z, a los ≈ 120 s del arranque): pub seq 18 · HUB 16 · bot 35, los tres «cuadra · sbot=», v1.3.2,
`enlace-pub=connected(out)` en HUB y bot. (Esta vez cuadró a la primera: el bot no tenía que anunciar `pubAvailability`.)

## 2. Qué se entregó (rama)

| Commit | Pieza |
|---|---|
| `c6142620` | Overlay limpio `git rm -r src && git checkout 09b829f8 -- src/`, tal cual upstream (8 min en Windows). Se conservan `blockchain-cycle.json` y los guards de `updater.js` e `invite-codes.json` (upstream no los tocó: `git diff --shortstat a44bce44 09b829f8` vacío en los dos). **Upstream mueve `scripts/patch-node-modules.js` a `src/patches/`**: la copia del fork se retira (la nueva viaja con el overlay) |
| `6936bcc7` | Guards repuestos en los cuatro ficheros que upstream sí cambió (`backend.js` +1698/−600, `ssb_config.js` +9/−1, `settings_view.js` +32/−20, `clearnet_view.js` +181/−17): `git apply --3way` del diff de guards de 1.3.2; `ssb_config.js` y `settings_view.js` limpios; `backend.js` y `clearnet_view.js` con **tres conflictos de suma** (upstream añadió `canonicalUrl`/`ogImageUrl`, el enlace RSS, la búsqueda del HUB y el zoom de imágenes donde vive el sexto guard; `cnZoom` junto a `THEMES` en los exports): se conservan las dos partes. **El séptimo guard no se repone** (§3, «/c/blob», y §8: DECISIÓN) |
| `bfd54998` | Seguir al parcheador a `src/patches/`: `Dockerfile` (modos `OASIS_AI=nav\|full`), `upgrade-patches-audit.js` (busca por las dos rutas, `__dirname` falso en la carpeta del script), `upgrade-behaviour-diff.sh` (sección `patches`, línea `+` propia cuando se mueve), `hub.tsv` (la fila del séptimo guard mide el literal de upstream que lo sustituye) |
| `3e6d2602` | `regen-node-configs.js`: `inboxMutedBots += social` en `pub/config/hub/oasis-config.json` y en la plantilla del bot (upstream añade el aviso `SOCIAL_SUPPORTED` a `INBOX_BOTS`) |
| `cec7fd5b` | `link.tsv` al cupo configurable (+3 filas de upstream), `devops/scripts/feed-guard-status.js` (sonda), plantilla nginx (salas en clearnet sin búfer, `/c/pdf/page` cacheable; `nginx -t` ok) |
| `e1f7848f` | Protocolos (UPGRADE §0.2, §2, §3.1, §3.4, §4, §7; AGENTES §4; HUB §2; CAPACIDAD), frase canónica (AGENTS.md, README, PRÁCTICAS, mantener), D-O40 propuesto, backlog, CHANGELOG |
| `f526f6d1` | reporte del tramo local, build del portal |
| (este) | §10 aplicación en el host, cierre (journal, ficha, `mantener.md`, protocolo §7, backlog, CHANGELOG) |

Verificación de invariantes (UPGRADE §2), tras `6936bcc7`: `git diff 09b829f8 --stat -- src/` = **7 ficheros** (110+/32−:
`backend.js`, `updater.js`, `blockchain-cycle.json`, `invite-codes.json`, `ssb_config.js`, `clearnet_view.js`,
`settings_view.js`); `-- src/base` vacío; `src/server/node_modules` modo `120000`; `node --check` ok en `backend.js`,
`clearnet_view.js`, `ssb_config.js`, `settings_view.js`; versión `1.3.8`; `upgrade-patches-audit.js 09b829f8` →
`# parches de 09b829f8:src/patches/patch-node-modules.js` · **20 parches** (upstream añade 7 desde 1.3.2: `ssb-conn` inbound
limits y «outgoing from node settings», `ssb-db2` history stream, `hyperaxe`, `html-element`, `on-wakeup`,
`async-append-only-log`) · `aplicado=12 silencioso=7 pendiente=0 sin-anclaje=0 ausente=1` (el ausente es `src/AI`, normal).
La verificación de invariantes de `scripts/patch-node-modules.js` ya no existe: el script vive bajo `src/` y lo cubre el
invariante de `src/`. `regen-node-configs.js --check`: NO al día antes de `3e6d2602` (solo por `social`), al día después.

## 3. Disposiciones

`upgrade-behaviour-diff.sh a44bce44 09b829f8` sobre el árbol con los guards repuestos (1 min 20 s en Windows): 370 líneas,
**254 piden disposición** (signo `+`, `-` o `!`), `annex` 88 `=` y **2 `!`** (los dos de `link.tsv`, abajo), `patches` 20 `=`
y 1 `+`. Agrupadas por causa:

**Guards y árbol (§2).** `roles +` 2ebe27e3, 8bd8630f, 11e046cb, bd892fc9, 9f6ad872, 82574c57, fcc37d75, 4763d574, c4ec6c5e,
dd4c8958, 5865b6e1, e6ef65b3, 6187684e, 7eb4865d, a7b2b8f1, aba81af3, 46f6e16c, 7c250c58, f870255c (los 19 ficheros que carga
el pub en modo `server`) → **gate** U2 (`SMOKE OK` en modo `server`) y U3 (el pub publica `oasisVersion` y nada más). Los que
cambian lo que el pub **hace solo** se leen aparte abajo: `feed_guard.js` (6187684e), `blob_prefetch.js` (5865b6e1),
`long_content.js` (7eb4865d), `network_pause.js` (a7b2b8f1), `db2_legacy.js` (e6ef65b3), `phone_module.js` (46f6e16c),
`ssb_config.js` (7c250c58), `ssb_metadata.js` (f870255c). `deps -/+` 2eeeb98f, 938856ac (versión 1.3.2 → 1.3.8) → **gate** U3
(`oasisVersion=+1` por nodo). `deps -/+` a1651dd5, 7ecbfd3d (`postinstall` apunta a `../patches/`), `patches +` 3558ca16,
`files +` 64f74cf9 y `outside -` f999e432 (el parcheador se muda de `scripts/` a `src/patches/`) → **adaptado** c6142620 (la
copia del fork se retira) y bfd54998 (`Dockerfile`, audit, diff), y medido (`pendiente=0`). `deps +` f1a3c7d2 (`mupdf`
^1.28.1) y 7f6eeb43 (`src/base`: 13 ficheros en 3 paquetes: `mupdf` nuevo (wasm, 11 ficheros), `ssb-conn/lib/conn-scheduler.js`,
`async-append-only-log/index.js`) → `mupdf`: **documentado** abajo (PDF en el visor); `ssb-conn`: **adaptado** (`link.tsv`,
abajo) y **gate** U6 invite completo (un `deps +` sobre `ssb-*` dispara el invite, §3.4); `async-append-only-log`: parche de
upstream ya aplicado en lo vendorizado (audit nº 20) → **gate** U3/US (el log se lee y se escribe igual: `seq = registros =
sbot` en las fotos, snapshot del pub construye). `files -` 00c6d0b5 y `+` e04e2d94 (`crypto.js` → `crypto_model.js`, renombre),
`+` 269a0cf1 (`comments_model.js`), `+` ab0c59fe (`scheduler_model.js`), `+` 43d9db13 (`pdf_view.js`), `-` dd204fdd, 6f3d68c3,
75f2d7e9 (visor PDF en el navegador, sustituido por el de servidor), `+` da5c31cc y `-` a13a982e (un activo del cliente) →
**no-afecta** al feed de nadie (modelos que la GUI o el visor invocan por petición; los que entran en el cierre del pub están
en `roles`); los nuevos `blob_prefetch`/`feed_guard`/`long_content` (26db0abf, ec80c4c9, 85bf06d0) **abajo**.

**`feed_guard.js` (6187684e, ec80c4c9; `timers +` 4346c2a0, a29a7380, e5528ae5).** Plugin nuevo del sbot que **carga también el
pub**. Al arrancar valida su propio feed (`selfCheck`, firma por firma) y, en cada `rpc:connect` y tras cada publicación, compara
su feed con la copia que tiene el par (`createHistoryStream` remoto): si el par tiene **más** cola de nuestro feed, la adopta
(`db.add`: no publica); si tiene **otra** cola desde un punto (bifurcación), o la cola propia no valida, **borra el feed local**
(`db.deleteFeed`), reconstruye con la copia del par y **republica** con la identidad del nodo los mensajes perdidos
(`repair`: `safety` JSON en `~/.ssb/oasis/content/feed-repairs/`, cooldown de 24 h). Además envuelve `publish`: rechaza
mensajes de más de 8192 caracteres. **No tiene interruptor** (ni config ni env) y solo escribe en el log con `OASIS_DEBUG`.
Para un feed coherente con la red no hace nada: `status()` (RPC `feedGuard.status`, manifest `sync`) lo dice. **Gate** U3/U5/U7
(cualquier `deleteFeed` o republicación saldría como Δseq distinto del declarado o «el feed ha cambiado») **y medida directa**
(§5, U3): tras recrear, `feedGuard.status()` en los tres nodos → `selfChecked: true`, `reportedOk: true`, `lastRepair: null`
(pub 6 comprobaciones, HUB 2, bot 2). **DECISIÓN** (§8): una reparación es irreversible y autónoma (AGENTES §3); el custodio
decide si acepta el plugin tal cual (recomendación abajo) o pide un interruptor como guard.

**`blob_prefetch.js` (5865b6e1, 26db0abf).** Solo con `config.pub` (el pub; el bot con el motor encendido): por cada mensaje
nuevo de un autor **al que sigue**, pide a la red (`blobs.want`) los blobs que referencia; al arrancar repasa los últimos
`ssbLogStream.limit` (2000 en el pub) mensajes del log. No publica. Es disco del pub (`ssb-data/blobs`, sin recolector; el
tope por blob sigue en 50 MiB, guard de `ssb_config.js`) → **documentado** en `CAPACIDAD.md` (fila de blobs) y **gate**
U3/US (0 publicaciones); el pub de la casa sigue a sus habitantes y a sus nodos: lo que pedirá son sus blobs. El bot sigue
solo al pub (`contact=1`): nada que pedir.

**`long_content.js` (7eb4865d, 85bf06d0; `publish +` 4ab72436).** Envuelve `db.publish`/`db.create`: un contenido que excede el
tamaño de mensaje se parte en trozos (`long_text.autoChunk`, 2ebe27e3) y se publica la cabecera; `db2_legacy.js` (e6ef65b3)
los vuelve a unir al leer (`joinLong`) y deduplica `createHistoryStream`. Solo actúa al publicar: lo que publican solos
nuestros nodos (`oasisVersion`, `karmaScore`, `about`, `pubAvailability`) cabe de sobra → **no-afecta**; **gate** U3 (Δ
exacto).

**Cupo de conexiones salientes y ranking de pares (a7b2b8f1 `network_pause.js`, 11e046cb `config-manager.js`, `annex !`
38f14f8f, 8c03d6e9; `routes +` 0511ddd0 `POST /settings/connections`).** Hasta 1.3.2 `ssb-conn` mantenía **4** salientes
fijas para pares que no son room (el cupo que dejaba fuera al pub de la casa, WP-O143). Desde 1.3.3 el parche de upstream
«outgoing connections from the node settings» lee `ssb.oasisConnQuota()`, que `network_pause.js` sirve desde la clave
`connections` de la `oasis-config.json` del nodo (`connectionsOf`: 5-30, **10 por defecto**, TTL 5 s; la GUI la fija en
`/settings/connections`). HUB, bot y pub no la fijan → 10. Y `peerRank` pone en el primer nivel a los pares que **nos siguen**
(`carriesMe`): el pub sigue a sus nodos, así que ya no compite en igualdad con los externos por una plaza. El keepalive
`start_pub_link` y la libreta del pub (D-O38) siguen: son la garantía, el cupo es la holgura → **adaptado** (`link.tsv`:
literal nuevo del cupo + tres filas de upstream que lo sostienen; la del parcheador apunta a `src/patches/`) y **documentado**
(HUB-PROTOCOL §2, AGENTES §4). **Gate** U3/U5/U7: `enlace-pub=connected` en HUB y bot en todas las fotos (en U3 el bot salió
`connected(in)`: el pub entró él, por el ranking nuevo; `check` admite `in|out`).

**Centralita del pub (46f6e16c `phone_module.js`; `timers` b8a138e5, 868d40d5, 8ef6066f, 58ddaa8e, f6f9acc9, bb5d24ae,
d91deb31, 2322d7d8, 995900e2; `publish` 2d073f51, d44b4e12, 80928ade, f9a1a48a, f172e712, 82297f30, 4b0520bd, 875ca857; `env +`
40cc1a8c).** `publishFrame` sigue sin ser `ssb.publish` (empuja fotogramas JPEG o PCM a los observadores): 0 `ssb.publish` en
el fichero. Novedades: rejilla de vídeo **por sala** (`r.tag`, `startGrid`), **mezcla de sonido por sala** en JS
(`startViewerMedia`, `mixInto`, cada `FRAME_MS`), reproducción de ficheros en una sala por `ffmpeg` o `gst-launch-1.0`
(`OASIS_GST_LAUNCH`): **ninguno de los dos está en la imagen** (medido: `command -v` vacío) → esa parte queda inerte.
Retransmitir y mezclar no publica → **no-afecta** al feed (U3/U5/US a 0) y **documentado** en CAPACIDAD §4 (CPU del pub por
sala viva). La política del pub (`relay: true`, `roomMax: 12`, vídeo activo por decisión de 2026-10-18) no cambia.

**Salas en clearnet (HUB).** `routes +` 172c88fd (`GET /c/rooms/:id/:stream`), `timers +` 276429c3, 9d0469df
(`syncClearnetRooms` a los 20 s y cada 60 s, solo `config.public`), `headers +` 42829140 (`audio/wav`), d6f2b1cd
(`multipart/x-mixed-replace`), 2155533d (`no-store`), 1c822ff2 (`nosniff`), `loopback +` 8e16e0ed y `routes +` 2eb29e4b (`POST /rooms/stream`,
GUI), `routes +` e2494cd7, 05daa8fa (`/rooms/leave`, `/rooms/reopen`, GUI). El HUB **se une como oyente** (`viewerJoin`: RPC al
plugin de teléfono, **no publica**: medido en `rooms_model.js`, 0 `publish` en esa ruta) a las salas cuyo autor ha marcado
`rooms` en sus `visibilityPrefs` (`clearnetRoomOk` → `clearnetPublicSync`: el mismo opt-in del resto del visor) y retransmite su
audio (`wav` sin fin) o vídeo (`multipart`) a visitantes web, con tope `CLEARNET_ROOM_WATCHERS_MAX = 50` por sala y `no-store`.
→ **no-afecta** al feed; **adaptado**: la plantilla nginx gana una `location` para `/c/rooms/<id>/(live|sound)` **sin búfer ni
caché** (`proxy_buffering off`, `proxy_cache off`, idle 60 s): un flujo sin fin con `proxy_buffering on` iría a un fichero
temporal sin techo (§4, viaja al host); **gate** U4 (`hub --strict`, `nginx -t` en verde); **DECISIÓN** (§8): es ancho de banda
de salida del VPS (≈ 200 KB/s por espectador de vídeo); si el custodio no quiere salas en clearnet, la misma `location` pasa a
`return 404`.

**PDF en el visor (HUB).** `routes +` 2f602f0c, e3ab4ae6, fe38d210 (`/c/pdf`, `/c/pdf/embed`, `/c/pdf/page`), 0eab90b0,
0912777f, ad204e4b (los mismos en la GUI), `files +` 43d9db13, `deps +` f1a3c7d2, `timers +` 7d68a9fa, `headers +` ca746544
(`private, max-age=86400` en `/c/pdf/page`). Upstream retira el visor PDF del navegador (pdf.js) y **rasteriza en el servidor**
con `mupdf` (wasm vendorizado) en **un** `worker_thread` con cola, tope de memoria y 60 s por llamada (`pdf_view.js`): CPU del
HUB por página pedida. Con `private` nginx no cachearía nada y cada visita volvería a rasterizar → **adaptado**: `location
/c/pdf/page` que ignora `Cache-Control` y cachea 1 d por URL (`src`, `p`, `w`, `r`), con `limit_req`; en `/c` solo sale
contenido de la lista blanca clearnet. **Documentado** en CAPACIDAD; **gate** U4.

**Karma y banca (c4ec6c5e `karma_model.js`, 9f6ad872 `banking_model.js`, 4763d574 `industry_model.js`).** El pub los carga
(cierre de `SSB_server.js` vía `banking_model`) pero no ejecuta el backend: ningún temporizador ni `publish` nuevo en esos
ficheros (secciones `timers`/`publish` sin líneas suyas). En HUB y bot el refresco de fondo sigue publicando `karmaScore` a las
24 h si cambia el valor → dentro del `+0..1` declarado; en U3 salió **uno en el HUB** (`karmaScore+1`: valor recalculado por
el algoritmo nuevo) → **gate** U3/U5 (dentro del rango).

**Publicaciones programadas (bot).** `publish +` 1aa72dee, fe45de29, a5599b92, 5d7c356e, def8e147, 6d8504ff (`publishScheduled`
en cada `GET` de un backend **no público**: blogs, podcasts, eventos, encuestas y votaciones con fecha), 25d457d2, 27a68b81,
d662a80c, a7afca01, e00d7b54, 76a5a3f7 (`publishDue` de cada modelo), `files +` ab0c59fe, `state +` 18106a6a
(`scheduled.json`), `routes +` 4cf07869, 9638d725, a8ef6d23, b6881937, 1145dcaf, 52cd18a7, 7dcdaa74, 321e38c7, 8989c93e,
1977b67d, bc8691d1 (programar o retirar desde la GUI). Solo publica lo que alguien programó desde la GUI: en el bot
`scheduled.json` nace vacío y nadie usa su GUI (el HUB es público: no entra) → **no-afecta**; **gate** U5 (las cinco páginas del
peor caso son `GET` del bot: Δ0).

**Aviso automático nuevo.** `publish +` f8d2e610 (`notifyBot('SOCIAL_SUPPORTED', …)`: alguien empieza a apoyarte), `state +`
0fd1194b (`supporters-seen.json`), `routes +` 8a0cdc83 (`POST /feed-status/seen`, GUI) → **adaptado** 3e6d2602
(`inboxMutedBots += social` en HUB y bot; sin ello el nodo se enviaría un cifrado a sí mismo: HUB §2). **Gate** U3/U5:
`(cifrado)` Δ0.

**Publicaciones de la GUI.** `publish -/+` ddda467c → 2890d80a, e8517098 (comentarios por `comments_model`), 920f4e2f,
13474bca (`BLOG_NEW` cambia de sitio, misma lista silenciada), 97dfbebb (texto de error), 743ad6b3 → 6d91d681 (perfil con
`aiAgent`), 520dc45b → 5057fc45 (`POST /settings/invite/follow`: el `contact` lleva `following: true`), 2c354dbd → 8837fa59,
13f05f1d → 9479838c, 0084eec4 → 75c3282a, 75b1b7a6 → 51f9297b, dffb81f4 → d1b5bd06, b9c699e3 → 3f6df8fa (`tribeCrypto` →
`cryptoModel`, renombre), 25b6bd61, 3458e94e, 864ba6e3, 7e913d4e, 4d9ab85f (tribus: sobre sellado y troceado), d8680e65
(mercado: PM al vendedor); `routes +` a36c61ef, f49438a9, de2bc8f5, 629d3f63, fa0d6b3d, 00b3c072, 1d1c97da, c2ec6157, 3f6d8ec8
(comentarios y opiniones nuevos), d6fe5bec (`/versions/:id`), 445ac821 (`/avatar/:feedId`), 4fc58802
(`/c/shops/:shopId/product/:productId`), 7792ff2c (`/c/podcasts/:id/rss`), 5a4880ec (`GET /c/rss`, portada RSS); `routes -`
5fd9a8cf (`POST /files/:fileId/fetch`) → **no-afecta** a los nodos de soporte: nadie usa su GUI (su único tráfico es el
healthcheck, el `worst` de U5 y el visor `/c`, que es solo lectura); el pub no carga el backend. Las tres rutas nuevas bajo
`/c/` son GET de lectura y caen en la `location` genérica de nginx (60 s; las RSS traen `public, max-age=600`, 5facaab8, que
nginx respeta) → **gate** U4. `routes -` 974eafea (`GET /c/sitemap.xml`) es un **falso borrado**: la ruta pasa a
`.get(["/c/sitemap.xml", "/sitemap.xml"], …)` (array de rutas, que el diff no reconoce) → **gate** U4 (`hub --strict` pide el
sitemap); el protocolo lo anota (§7).

**Cabeceras y host (D-O25).** `headers -/+` 8851784c → 6a7aebbd, b2d6fe94 (`protocol` honra `X-Forwarded-Proto` si es
`http|https`: nginx manda `https` fijo, así que las URL absolutas de sitemap y RSS salen `https://` ya desde el backend; el
`sub_filter` de nginx queda redundante y se mantiene), 8c19edd8 (`refererPath(…, ctx.host)`: el `Referer` de la GUI, no del
visor), 34fe0512, 029cbdd3 → 2227eae0 (CSP: `pageFrames(ctx, isClearnet)` decide por ruta y host, no por cookie), faadaea1
(`/avatar`, fuera de `/c`), 5facaab8 (RSS, arriba) → **no-afecta** a la caché (nada depende de una cabecera del visitante que
nginx no vacíe ya: `Accept-Language` y `Cookie` van vacíos, `Host` es el del vhost) y **gate** U4 (`hub --strict`: 0 cruces en
18 peticiones de 6 idiomas, variante `?theme=`, sitemap y RSS https).

**Entorno.** `env +` 3a7e1e10 (`EXTERNAL_STORAGE`: raíces de almacenamiento del explorador de ficheros de la GUI, Android),
f73d3bba (`OASIS_FFMPEG`: ruta de `ffmpeg` para limpiar metadatos de un medio **subido desde la GUI**; sin binario, no hace
nada), 40cc1a8c (`OASIS_GST_LAUNCH`, arriba), 2b12e129 (`ssb_port` en `ssb_config.js`: si existe esa variable de entorno,
manda sobre el puerto del sbot; **ningún compose ni el entrypoint la definen**: medido con `grep`), f71dd23f (`OASIS_DEBUG`:
17 → 23 usos; sigue sin definirse), 79dd6ac8 (`OASIS_MOBILE`) → **no-afecta**. `7c250c58` `ssb_config.js`: además de
`ssb_port`, el nivel de log en modo debug pasa de `debug` a `info` → **no-afecta** (nadie arranca con `--debug`); el guard
(`mergeDeep`, override, `blobs.max 50`) repuesto en 3-way limpio.

**Estado.** `state +` 18106a6a, 0fd1194b (arriba) → **documentado** aquí: dos ficheros de estado nuevos bajo
`~/.ssb/oasis/content/` que un rollback de imagen no deshace (UPGRADE §6); en los nodos de soporte nacen vacíos.

**Otros temporizadores.** `timers +` fbe8e3e2, 5cfc1f39 (carreras con tope de espera al cargar relaciones e índices de
comentarios para una página: no publican), `-` 15a3acaf (`logClearnetStatus` a los 8 s desaparece; f870255c
`ssb_metadata.js`: el arranque ya no espera 25 s a los módulos clearnet para imprimir la cabecera: `waitForClearnet` y
`setTimeout(tick, 250)` (dfac02b0) se van), `-` 845a761a, 4879cae0, 2ba67afa, a08a3fbc (pdf.js del navegador, borrado) →
**no-afecta**.

**`db2_legacy.js` (e6ef65b3).** `createHistoryStream` deduplicado por clave y unión de contenidos largos al leer; sin cambio de
versión de índice (`oasisLinks` 1, `oasisActivity` 2: no reindexa) → **no-afecta** al log; **gate** U3/US (`seq = registros =
sbot`; snapshot construye).

**Fuera de `src/`.** `outside +` 65c44fee (`install.sh`), 67d375cc (`oasis.sh`), 235384d9, 2089d634, d998eb13 (`scripts/`),
4f1ccd7c, 253e341f, bd71af45, 597d595e, eb0d23c5, 7bca7c6a, 57190f53, 1f358158, 170a5ae4, 0d4fbf70, fd450682, b53d5335,
d48c8b32, 1f9c7de3, b9b0afb6, 16730b38, 320cac9c, 51a13174, d9d69cc2, 891aa50a, 22fe179b, 9f81de2f, 6323a904, d5f8ab58,
e039b630, 73638de7, a5c00aa4, d68e20a8, e6d8a5af, 324970be, cfc92448, 4a0683a8, 54f988e1, b1a48984, 393e32fb, 2be436b1,
7b4f2b8b, 919e4b55, 5e7baf16, 767050e6, bf7d552a, dc5afb84, a34a372c, 4e783380, 20c8356b, 1101ea11, c878c3b5, 9dac9833,
9c90040a, ef96b084, 27b19e3d, 148eda3d, 5e0882a3, 8a359d0f, 6e8ab8ae, 417fc7e4, a19a5737, 2e7ce600, 4cc4d803, 823bf828,
9208e86c, 01cc7d7c, cc95e2b5, 88e2b2f3, cb5fdaad y `-` 08fcec21 (tests de upstream) → **no-afecta**: camino bare-metal y
tests de upstream; el overlay no los trae (UPGRADE §2). Los tests nuevos `test/mods/db2/fork*.test.js` y
`test/mods/peers/feed_guard.test.js` son la especificación del guardián de feeds y se leyeron para la disposición de arriba.

**Séptimo guard (`/c/blob`) — retirado.** No es una línea del diff (está en `annex` como `=` tras `hub.tsv`), pero es la
disposición de más peso del árbol: upstream 1.3.3+ en `.get("/c/blob/:cnBlobId")` hace `getLocal` y, si el blob falta,
`wantClearnetBlob(blobId)` (pide a la red en segundo plano, con reintento acotado) + `sendPendingContent(ctx)` (`no-store`;
un SVG «todavía no disponible» si lo pide una `<img>`, 404 si no); además **pre-pide al indexar** los blobs de todo objeto
clearnet (`for (const id of set) if (!hasLocalBlob(id)) wantClearnetBlob(id)`). Cubre lo que D-O31 perseguía («un blob que el
HUB no tiene nunca saldría en `/c`») sin colgar la petición hasta 30 s. La `location /c/blob/` de nginx no ignora
`Cache-Control`: el «pendiente» no se cachea (medido en la plantilla) → **adaptado** 6936bcc7 (no se repone), bfd54998
(`hub.tsv` mide el literal de upstream), y **DECISIÓN** §8 (supera D-O31; la frase canónica pasa a «6 guards en 6 ficheros»).

`upgrade-behaviour-diff.sh a44bce44 09b829f8 --check <este fichero> --from-tsv` sobre el TSV regenerado tras `link.tsv`
(373 líneas, 252 piden disposición, `annex` 0 rotos) → «todas las líneas tienen disposición» (§5, U1).

## 4. Qué viaja al host

- `src/` entero (1.3.8 + 6 guards), por `git archive` LF desde `upgrade/oasis-1.3.8` (§4 paso 4). **Cambia la comprobación
  previa al `mv`**: `grep -c 'guard o-sdk (WP-O135' src.new/src/backend/backend.js` debe dar **0** (y `wantClearnetBlob` ≥ 1).
- `pub/config/hub/oasis-config.json` (`inboxMutedBots += social`): bind in place (`cat >`) + recrear el HUB (paso 8).
- `pub/config/wallet-bot/oasis-config.json.tpl` (ídem): plantilla in place + render con `sudo` + recrear el bot (paso 9).
- `pub/config/hub/nginx.conf.template`: dos `location` nuevas (`/c/rooms/<id>/(live|sound)` sin búfer ni caché; `/c/pdf/page`
  cacheable 1 d) y el comentario de `/c/blob/`: a un temporal del host · `nginx -t` en un contenedor desechable · in place ·
  `up -d --no-deps --force-recreate hub-cache` · `hub` · salud de los vhosts del edge (paso 5: inocuo con el HUB en 1.3.2, que
  no tiene esas rutas). Si el custodio decide **no** retransmitir salas en clearnet, la primera `location` lleva
  `return 404;` en vez del `proxy_pass` (§8).
- `.dockerignore` del host: **no se converge** (otro layout, E0); cumple §4; `smoke` lo mide.
- Nada más: `Dockerfile` cambia (ruta del parcheador para `OASIS_AI=nav|full`) pero pub, HUB y bot se construyen con `none`:
  **viaja igualmente** (la imagen del host se construye desde esa raíz y `deploy-status` compararía con HEAD): sha del vivo =
  blob de HEAD~ antes de pisar, `cat >` in place, y el build del paso 6 lo usa. Compose, Caddy, `ssb-config` de los nodos,
  `tools/*.js`, entrypoint: sin cambio.

## 5. Gates U0-U7, UM, UR, US

Stack local sobre `volumes-dev/` (identidades desechables), `$G = upgrade-gates.sh --local`, 2026-10-25 17:06-17:34 UTC.
UM y UR no aplican (el ciclo no cambia el motor, §1).

| Gate | Comando | Salida |
|---|---|---|
| **U0** | nodos parados · `$G backup pre138` · `$CL up -d` (17:06:19Z) · `$G snapshot pre138` | copia 3,2 MB; `healthy` los tres a los ≈ 3 s; foto a los ≈ 120 s (17:08:23Z): pub 18 · hub 16 · bot 35, «cuadra · sbot=», v1.3.2, `enlace-pub=connected(out)` en HUB y bot; bot `dirección=EYMWF4…`, `motor:pub=true`, `épocas=2026-09,2026-10` |
| **U1** | `git diff 09b829f8 --stat -- src/` · `-- src/base` · `git ls-files -s src/server/node_modules` · `node --check` ×4 · `upgrade-patches-audit.js 09b829f8` · `regen-node-configs.js --check` · `--check --from-tsv` | **7 ficheros** (110+/32−) · vacío · `120000` · ok · `pendiente=0 sin-anclaje=0` (20 parches) · al día tras 3e6d2602 · `annex`: 2 `!` en `link.tsv` (cupo de 4 y ruta del parcheador) → corregidos en esta rama; `--check`: pendiente de la regeneración |
| **U2** | `docker tag :latest :1.3.2-vieja` · `compose build oasis-pub` (17:10:35Z) · `$G smoke oasis-pub-scriptorium:latest` | imagen `6b6f3f7401c7` (1,56 GB; la vieja `420ceeb70182`) · **`SMOKE OK`** (17:12:44-57Z): 1.3.8, `node --check` ×3, enlace a `src/base`, **0 `secret`**, nada del fork en `/app`, `server` socket a los 2 s, `backend` `GET /c` 200 a los 2 s y `start_pub_link` anunciado, 3 parches ×2, 0 errores ×2 |
| **U3** | `$G up pub` (17:14:17Z) · `$G up hub` · `$G up bot` · `$G check pre138 --wait` | `healthy` a los **4 s** cada uno (24 s en total) · **`GATE OK` (76 s)**: pub `oasisVersion+1` (18 → 19) · HUB `oasisVersion+1` **+ `karmaScore+1`** (16 → 18; dentro de `+0..1`) · bot `oasisVersion+1` (35 → 36); **nada más** (ni `about`, ni `pubAvailability`, ni cifrados); `enlace-pub` HUB `connected(out)`, bot `connected(in)`. **`feedGuard.status()`** en los tres (sonda `ssb-client` dentro del contenedor): `selfChecked: true`, `reportedOk: true`, `lastRepair: null` (pub `checks: 6`, HUB 2, bot 2) |
| **U4** | `$CL up -d --no-deps --force-recreate hub-cache` (plantilla nueva, 17:16:56Z) · `pub-web` arriba · `$G hub --strict` | **`GATE OK`** (17:17:07Z), 16 ok: `/c` 200, MISS→HIT, una CSP, idioma «es» igual con de/es/fr y cookies, `?lang=`, **0 cruces en 18 peticiones de 6 idiomas**, `?lang=ar`, selector de tema, `?theme=` Clear/Matrix/desconocido, enlaces con `lang` (24) y `theme` (32), variante `?theme=` en caché, 0 cruces de tema en 9, `/c?type=files` 200, sitemap 9 URLs https, RSS feed/files https. La plantilla nueva pasó `nginx -t` en un `nginx:alpine` efímero antes de recrear |
| **U5** | `$G snapshot u5` (17:17:15Z) · `$G worst` · `$G check u5 --wait --expect 'bot:karmaScore=+0..1'` | 5 GET → 200 · **`GATE OK`** (76 s): los tres Δ0, «sin publicaciones»; `wallet=1` y `(cifrado)` quietos, misma dirección `EYMWF4…`; enlaces `connected` |
| **U6** invite | `$G snapshot u6` (17:25:34Z) · `invite.create({uses:1, external:'gate.example.org'})` por `ssb-client` en el pub (114 caracteres, no impreso) · host → `172.20.0.3` (IP del pub en el bridge) · desechable `docker run --network oasis-pub-scriptorium_oasis_pub_net -e OASIS_SNAPSHOT=off -e OASIS_PUB_LINK_HOST= … :latest backend` (socket a los ≈ 60 s: el entrypoint parchea y arranca la pila) · `ssb-probe.js` `SSB_ACTION=invite-accept` · `$G check u6 --wait --expect 'pub:contact=+1 hub:=0 bot:about=+0..1'` · `docker rm -f` | el pub (`@eDyDjJ…`) como par `connected` (`type: pub`, saliente) del desechable; **`GATE OK`** (76 s): **pub `contact+1`**, HUB y bot 0. Desechable retirado 17:28:16Z |
| **U6** cliente | fuera de alcance: el cliente real está cerrado (D-O39) y no se sube. El cambio del `Dockerfile` (`OASIS_AI=nav\|full`) se comprueba en la imagen: `MSYS_NO_PATHCONV=1 docker run --rm --network none --entrypoint node …:latest /app/src/patches/patch-node-modules.js --verbose` | el script se encuentra por la ruta nueva y recorre los 20 parches: todos «already patched» (salvo `@xenova`, `file not found`: sin pila de IA), rc 0. (Sin `MSYS_NO_PATHCONV=1`, Git Bash convierte `/app/…` y node busca `/app/src/server/C:/Program Files/Git/app/…`: trampa de AGENTES §4) |
| **U7** | `$CL stop` ×3 (17:30:35Z) · `$G restore pre138 --yes` · `render-wallet-bot-config.sh pub/.env.local` (vuelve a llevar `social`) · `$G up` ×3 · `$G check pre138 --wait` | `healthy` a los 4 s ×3 · **`GATE OK` (107 s)**: **mismo delta que la primera vez** (pub `oasisVersion+1`; HUB `oasisVersion+1`, `karmaScore+1`; bot `oasisVersion+1`; nada más); enlaces `connected`. `feedGuard.status()` ×3 tras U7: `lastRepair: null`, `reportedOk: true` (pub 3 comprobaciones, HUB 3, bot 4) |
| **US** | `$G snapshot us` (17:33:18Z) · `pub-snapshot.sh --local build` · `$G check us --expect 0` · `status` | `{"ok":true,"messages":228,"feeds":6,"boxed":5,"bytes":69655,"ms":60}` · **`GATE OK`**: los tres Δ0 (construir no publica) · snapshot de hace 0 h, reconstrucción cada 6 h |

## 6. Delta de publicación

**Local** (U3 y U7, idénticos): pub `oasisVersion+1` · HUB `oasisVersion+1`, `karmaScore+1` (el algoritmo nuevo de
`karma_model.js` recalcula el valor y el refresco de fondo lo publica: dentro del `+0..1` declarado) · bot `oasisVersion+1`.
Nada más: ni `about`, ni `pubAvailability` (el bot lo había anunciado hace < 12 h), ni `ubiAllocation` (época abierta), ni
cifrados (`social` ya silenciado). U6: pub `contact+1` (el invite, solo porque se usó). `feedGuard`: `lastRepair: null` en
los tres nodos, en U3 y en U7.

**Host** (`pre138` 17:40:05Z → `post138` 18:11:04Z): pub `oasisVersion+1` (28 → 29) · HUB `oasisVersion+1` (27 → 28) · bot
`oasisVersion+1`, `karmaScore+1` (107 → 109). Ni `about`, ni `pubAvailability` (motor apagado y encendido en el ciclo; < 12 h del
último anuncio), ni `ubiAllocation` (época abierta), ni cifrados. **Mismo delta que en local** salvo que el `karmaScore` del
`+0..1` salió en el bot y no en el HUB. `feedGuard.status()` tras cada GO: `lastRepair: null` en los tres (el pub, con 16
comprobaciones contra pares externos).
Delta declarado (`expect.conf`, sin cambios): pub `oasisVersion=+1`; HUB `oasisVersion=+1,karmaScore=+0..1`; bot
`oasisVersion=+1,karmaScore=+0..1,about=+0..1,pubAvailability=+0..1`. Medida adicional de este ciclo: `feedGuard.status()`
con `lastRepair: null` en cada nodo (arriba).

## 7. Correcciones al protocolo

- **Un fichero de guard puede quedarse sin razón de ser.** Upstream absorbió el séptimo guard (`/c/blob`); reponerlo a ciegas
  habría dejado al HUB colgando peticiones 30 s para lo que upstream ya resuelve en segundo plano. La regla de §2 pasa a decir:
  antes de reponer un guard sobre un fichero que upstream cambió, mirar si el cambio de upstream **cubre lo que el guard
  perseguía** (la decisión D-O que lo creó); si lo cubre, se retira con asiento y se mide lo de upstream en el `.tsv`. Aplicado.
- **El parcheador de upstream vive en `src/patches/` desde 1.3.3.** §2 (overlay, verificación), AGENTES §4 y los dos scripts de
  medida apuntaban a `scripts/`; los scripts buscan ahora por las dos rutas. Aplicado.
- **El cupo de salientes de `ssb-conn` ya no es 4.** HUB-PROTOCOL §2 y AGENTES §4 («cupo de 4 salientes») pasan a «cupo
  configurable (`connections`, 10 por defecto desde 1.3.3; 4 hasta 1.3.2)»; `link.tsv` mide el literal nuevo. Aplicado.
- **`routes -` puede ser un falso borrado**: una ruta que pasa a declararse con un array de paths (`.get([a, b], …)`) sale
  como borrada. Se anota en §3.1 (tabla de secciones). Aplicado.
- **Una barra dentro de código en una celda de tabla rompe el build del portal.** `(live|sound)` entre backticks en una fila de
  CAPACIDAD partió la celda y dejó `<id>` fuera del código: Vue lo leyó como etiqueta sin cierre (`npm run docs:build` rc 1,
  WP-O146 ya cazó el caso de `<pendiente>`). En tablas, `·` o `\|`. Corregido; build y `verificar-sitio` en verde.
- **`/srv/oasis` es de root: el tgz de rollback de `src` (§4 paso 3) va con `sudo`.** El primer `tar` dio `Permission denied`
  sin escribir nada; §4 lo dice ahora. Aplicado.
- **Sonda del guardián de feeds.** Desde 1.3.8 cada nodo lleva `feedGuard`; su `status()` es la medida de que no ha reparado
  nada. Entra en U3 y en §4 (paso 7-9, tras cada `check`). Aplicado.

## 8. Decisiones que pide este ciclo (antes del host)

**Refrendadas por el custodio el 2026-10-25** («sí las decisiones. Go entero»): las tres, con la recomendación de cada una.

1. **Séptimo guard retirado (supera D-O31).** Propuesta: asiento D-O40 «desde 1.3.8 `/c/blob` es el de upstream; la frase
   canónica es 6 guards en 6 ficheros, invariante de 7 ficheros». Si el custodio prefiere conservarlo, se repone
   `getResolved` sobre la rama de upstream (1 línea) y se repiten U1-U4.
2. **Guardián de feeds (`feed_guard.js`) sin interruptor.** Para un feed coherente no hace nada (medido en local). Si en el
   host un par tuviera una copia **distinta** del feed de un nodo nuestro, el nodo borraría su cola y la republicaría solo.
   Recomendación: aceptarlo tal cual (es lo que upstream despliega en toda la red; nuestros feeds no han bifurcado: ningún
   registro de ello en RECOVERY ni en la ficha), con la sonda `feedGuard.status()` tras cada GO y, antes de GO-2, una lectura
   en frío de la cola del pub frente a la copia del HUB y del bot. Alternativa: un guard de entorno (`OASIS_FEED_GUARD=off`
   → `init` devuelve `api` sin enganchar nada) para pub, HUB y bot: un fichero más en el invariante.
3. **Salas en clearnet.** Upstream retransmite a visitantes web las salas cuyo autor ha marcado `rooms` en clearnet (opt-in,
   mismo criterio que el resto del visor), con tope de 50 espectadores por sala. Recomendación: permitirlo con la `location`
   sin búfer (preparada); alternativa: `return 404` en esa `location`.

## 10. Aplicación en el host (2026-10-25 UTC)

GO del custodio para el ciclo entero («sí las decisiones. Go entero»), con parada ante cualquier salida distinta de la esperada.
Una orden por paso. Estado de partida: §1 y foto `pre138` (remote, 17:40:05Z): pub 1.3.2 `server` seq 28 · HUB 1.3.2 `backend`
seq 27 · bot 1.3.2 `backend` seq 107 (`pubAvailability=70`, `ubiAllocation=16`, `wallet=1`, motor encendido), los tres «cuadra ·
sbot=», `enlace-pub=connected(out)` en HUB y bot. `/` 43 %, `/srv/oasis` 47 %, `sudo -n` ok.

| # | Paso | Hecho | Puerta |
|---|---|---|---|
| 1 | Backups | pub → `devops/backups/oasis-pub/` (archivo de `ssb-data`, 17:40-17:43Z); `wallet.dat` → `devops/backups/ecoin/` (hot, 94 208 B, 17:43Z). En el host `oasis-hub.bak-o147-2026-10-25.tgz` (956 MB: solo `ssb-data`, sin `http-cache`) y `oasis-wallet-bot.bak-o147-2026-10-25.tgz` (214 MB), root 600. Los cuatro ficheros que cambian: sha256 del vivo = blob de `main` (medido) → `.bak-o147-2026-10-25` → `cat >` in place con el de la rama (`Dockerfile`, `oasis-config.json` del HUB, `oasis-config.json.tpl` del bot: sha = HEAD, 0 CR). `.dockerignore` del host no se toca | **GO-1** |
| 2 | Disco | 0 contenedores sobre `:1.3.0` → `rm` de `src.old-1.3.0` y `src-1.3.0.tgz`, `rmi :1.3.0` (`8639c5f9`), `image prune` 0 B, `builder prune` 512 MB; `/` 43 % → 40 % | |
| 3 | Rollback | `oasis-pub-scriptorium:1.3.2` = `96a5a32c` (= `latest`) · `/srv/oasis/src-1.3.2.tgz` (94 MB, root 600). **Tropiezo**: el primer `tar` fue sin `sudo` y `/srv/oasis` es de root: `Permission denied`, nada escrito; repetido con `sudo` (§4 del protocolo lo dice ahora) | |
| 4 | `src/` | `git archive` LF de `upgrade/oasis-1.3.8` → `src.new` (17:41Z). Antes del `mv`: 1.3.8, 0 CR en `backend.js` e `is-map`, enlace a `src/base` + `ssb-db2`, 5.º guard (`url` = dominio del pub), 6.º (4 + 2), **7.º = 0 y `wantClearnetBlob…sendPendingContent` = 1**, `blobs.max 50`, `mergeDeep`, 0 `git reset --hard`, aviso del fork en `/update`, `src/patches/patch-node-modules.js` presente, 4 JSON en `configs/`, `src.old-1.3.2` no existía. `mv src src.old-1.3.2` · `src/` = 1.3.8 | |
| 5 | Lo demás que viaja | render de la config del bot (`sudo bash scripts/render-wallet-bot-config.sh .env.prod`: OK, 400, con `social`). Plantilla nginx: a `/tmp` del host · `nginx -t` en `nginx:alpine` efímero (ok) · in place (sha = HEAD) · `up -d --no-deps --force-recreate hub-cache` · `$R hub` → **`GATE OK`** con el HUB aún en 1.3.2 (sitemap 211 URLs https). Caddy sin tocar (los demás vhosts no cambian) | |
| 6 | Build y humo | `compose build oasis-pub` (17:44-17:45Z) → `latest` = `b6fd46db0ca0` (1,07 GB), `:1.3.2` = `96a5a32c`; `/` 46 %. `$R smoke oasis-pub-scriptorium:latest` → **`SMOKE OK`** a la primera: 1.3.8, `node --check` ×3, enlace a `src/base`, **0 `secret`**, 0 `.env` reales, `server` socket a los 2 s, `backend` `GET /c` 200 a los 2 s y `start_pub_link`, 3 parches ×2, 0 errores ×2 | |
| 7 | Pub (17:46:39Z) | `up -d --no-deps --no-build oasis-pub` → `healthy` a los **6 s** (imagen `b6fd46db`; log: `Version: 1.3.8`, parches, snapshot programado, 0 errores). `$R check pre138 --wait --max 900 --expect 'pub:oasisVersion=+1 hub:karmaScore=+0..1 bot:karmaScore=+0..1,pubAvailability=+0..1'` → **`GATE OK` (316 s)**: pub `oasisVersion+1` (28 → 29), HUB Δ0, bot Δ0, enlaces `connected` (ahora `in`: el pub entra él, por el ranking nuevo). `feedGuard.status()`: `checks: 16` con pares externos, `reportedOk: true`, `lastRepair: null`. `/public/status` → `1.3.8`, `running`, `healthy`, invite presente (121 caracteres, no copiado) | **GO-2** |
| 8 | HUB (17:52:53Z) | `oasis-config.json` (con `social`) y `ssb-config` del host = HEAD (sha). `up -d --no-deps --no-build oasis-hub` → `healthy` a los **18 s** (1.3.8, parches, «Admin access» presente y no copiado, `Media cache limit: 2048 MB`, 0 errores; `~/.ssb/oasis/oasis-config.json` lleva `social`). `$R check … hub:oasisVersion=+1,karmaScore=+0..1 …` → **`GATE OK` (287 s)**: **HUB `oasisVersion+1`** (27 → 28) y nada más. `feedGuard.status()`: `checks: 4`, `lastRepair: null`. `hub-disk.sh prune-cache` (2,05 GB → 52 KB, `nginx -s reload`) · `$R hub --strict` → **`GATE OK`**, 16 ok: MISS→HIT, **0 cruces en 18 peticiones de 6 idiomas**, tema por `?theme=`, 185 enlaces con `lang` y 193 con `theme`, sitemap 229 URLs https, RSS 37 + 4; `/c/rss` y `/c/pdf` (rutas nuevas) → 200 | **GO-3** |
| 9a | Bot (17:59:16Z) | `hub-wallet.sh pause` → 1.3.8 con `pub=false`, `healthy`; `status`: `wallet=1`, cartera `EYdruX…` (la misma), saldo 0, `pares: 10 · pub: connected` (el cupo nuevo, 10), `ecoind` healthy (blocks 63838), 0 errores, config con `social`. `$R check … bot:oasisVersion=+1,karmaScore=+0..1,about=+0..1` → **`GATE OK` (261 s)**: **bot `oasisVersion+1` y `karmaScore+1`** (107 → 109; el `karmaScore` dentro de `+0..1`), `motor: pub=true → pub=false`, nada más. `feedGuard.status()`: `checks: 4`, `lastRepair: null` | **GO-4a** |
| 9b | Motor (18:05:09Z) | `hub-wallet.sh on --yes` → `ready` en verde (pub `CONNECTED`; aviso de siempre: saldo ≤ 500, la época 2026-10 ya estaba abierta) → recreado con `pub=true`, `healthy`, «PUB engine on», `pares: 10 · pub: connected out`, cartera `EYdruX…`, saldo 0, 0 errores. `$R check pre138 --wait` (delta vigente completo, `expect.conf`) → **`GATE OK` (261 s)**: bot `oasisVersion+1` y `karmaScore+1` (los de 9a), **sin `pubAvailability` nuevo** (el último anuncio tenía < 12 h), sin `about`, sin `ubiAllocation` (época 2026-10 ya abierta), sin cifrados; pub y HUB sin cambios. `backup-ecoin.sh` después (hot, 94 208 B, 18:11Z) | **GO-4b** |
| 10 | Cierre (18:11Z) | `snapshot post138`: pub 29 · HUB 28 · bot 109, los tres «cuadra · sbot=», v1.3.8 · journal `1.3.8`, `server+hub+wallet-engine-on` (18:11:12Z) · `deploy-status.sh`: tres nodos **1.3.8 `healthy` «imagen al día»**, `src/` 1.3.8, `Dockerfile`, entrypoint, compose, plantilla nginx, configs y `tools/*.js` **iguales que HEAD** (deriva solo en `.dockerignore`, esperada), restos = el rollback de este ciclo (`src.old-1.3.2`, `src-1.3.2.tgz`, `:1.3.2`), HUB `connected in` (6 pares) y bot `connected out` (10 pares: el cupo nuevo), pub **VERDE** en el directorio (ciclo 6), `/` 43 %, `/srv/oasis` 45 %, `hub-disk` y `ecoin-disk` OK, `capacity` **0 avisos** (la capa del contenedor se vació al recrear) | |

Pub sin sbot ≈ 6 s; HUB ≈ 18 s; bot ≈ 0 s. **Nada publicado con identidad real fuera de lo declarado.** El bot retro sigue deprecated y
parado (D-O36); el cliente real sigue cerrado (D-O39).

### 10.1 Tiempos

GO-1 (17:40Z) → cierre (18:11Z): **31 min**, de los que 4 × ≈ 4,5 min son los `--min-age 300` de los `check` remotos. Los tgz de
`ssb-data` (1,2 GB) tardaron 3 min; el build en el host, 1 min 40 s.

## 9. Seguimiento

- Tiempos del tramo local: overlay 8 min 10 s (Windows), diff de comportamiento 1 min 20 s, build 2 min, camino U0 → US
  28 min de reloj (incluidos U4, U6 con nodo desechable y las esperas de estabilidad de 60 s).

- Backups viejos en `/srv/oasis` fuera de la máquina: pendiente desde WP-O128.
- Cliente real: cerrado (D-O39); el cerrojo en el entrypoint sigue pendiente (WP-O146 §8).
