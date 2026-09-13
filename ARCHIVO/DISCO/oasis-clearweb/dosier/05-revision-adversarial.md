# 05 · Revisión adversarial del diseño v2 (2026-09-13)

Un agente de diseño recibió el esquema v2 con los hechos de `01`-`04` y la orden de buscar fallos
concretos verificables, no alternativas globales. Devolvió 20 hallazgos. Cada uno lleva su corrección
y dónde quedó recogida en `../v2.md` / `06-fragmentos.md`.

| # | Hallazgo | Evidencia | Corrección aplicada |
|---|---|---|---|
| F1 | Los precedentes de invite no sirven tal cual: `join-client.sh:25` y `test-invite.sh:76-79` hacen POST **sin `Referer`**; el middleware lo exige para todo no-GET → 400 | `middleware.js:57-63, 160-164` | El bootstrap manda `-H 'Referer: http://localhost:3000/invites'`; documentado que esos scripts no son reutilizables |
| F2 | `POST /settings/invite/accept` **nunca falla por HTTP**: `try{}catch(_){}` + 302 (`safeRefererRedirect`). Un invite caducado o un pub inalcanzable devuelven 302 igual | `backend.js:10736-10750, 163-175` | Verificación **por estado**: `conn.json`/`gossip.json` del HUB contienen `oasis-pub` **y** el pub publica +1 `contact` (conteo `grep -a -c '"type":"contact"' flume/log.offset`, `test-invite.sh:46`) |
| F3 | `publish-about` vía `ssb-admin.js` no es fiable en el HUB: `manifest.json` solo se escribe en modo `start`; `ssb-admin.js` conecta con `ssbClient(config.keys, config)` y ssb-client 4.9.0 tendría que pedir el manifest remoto **[NV]** | `SSB_server.js:100,150`; `ssb-admin.js:17`; `package-lock.json:14352` | **No usar ssb-admin en el HUB.** En fase `PUBLIC=false`: `POST /profile/edit` (multipart `name`/`description` → `publishProfileEdit`, `backend.js:4382, 4481-4484`). Sin `vis_*` → `visibilityPrefs.clearnet=false` → el HUB **no se lista a sí mismo** en `/c` (`:6268-6269`) |
| F4 | El HUB publica un **PM de bienvenida** a sí mismo a los ~3 s del primer arranque (`welcomePmTick` → `pmModel.sendMessage([],…)` → `private.publish`) | `backend.js:11477-11484`; `pm_model.js:43-58`; `onboarding_model.js:103-106` (`firstContactSeen()` sin feedId = `flag.exists`) | **Pre-crear `oasis-first-contact`** en el ssb-data del HUB antes del primer `up` (contenido `welcome=dismissed`) |
| F5 | `oasisVersion` y la dirección bancaria del server **no corren en modo backend**: están dentro de `if (argv[0]==='start')` | `SSB_server.js:144-150, 220-246` | Corregido el «hecho» de la v1; la única `oasisVersion` posible es la del backend (`backend.js:1843-1854`, exige `latestSeq≠0`) |
| F6 | `ssb-lan` se carga siempre con `pub:false`; `lanRouter.startRouter` no arranca si `lanBroadcasting === false` | `SSB_server.js:83-86`; `lanRouter.js:55-58` | `lanBroadcasting:false` en el `oasis-config.json` del HUB; broadcast confinado al bridge en todo caso |
| F7 | `profiles: ["hub"]` sería **contraproducente**: `deploy.sh:16` (`up -d --build`), `down.sh:7`, `status.sh:7` no verían el HUB → `down` lo dejaría vivo, `deploy` no lo recrearía con la imagen nueva (`latest` cambia de ID) → versión vieja huérfana. WP-O50 exige profiles para un sidecar *opcional*; el HUB es permanente | `pub/scripts/{deploy,down,status}.sh`; `plan/BACKLOG.md:452-460` | **Sin `profiles`.** Mitigación del arrastre: todo `up` del plan es `--no-deps <svc>`; el `deploy.sh` del VPS ya está proscrito. Añadir `OASIS_HUB_*` a `common.sh:75-95` |
| F8 | **Cabeceras triplicadas y contradictorias**: backend `X-Frame-Options: SAMEORIGIN`, `Referrer-Policy: same-origin`, `nosniff`; Caddy `DENY`/`nosniff`/`strict-origin…` sin `defer` | `middleware.js:150-156`; `Caddyfile:4-8` | nginx `proxy_hide_header` de las cuatro del backend (incl. `Permissions-Policy`); el `header {}` de Caddy **no se toca** (sin `defer`). `frame-ancestors 'none'` ya está en la CSP → `DENY` coherente |
| F9 | `GET /c/blob/<id>` ausente **cuelga hasta 30 s** (`blobs.want` + timeout) y luego 404; con `proxy_cache_lock on` los concurrentes esperan 5 s (default) y van todos al upstream → N wants. Además escribe el blob dos veces (ssb-blobs + `fs.writeFile`) | `main_models.js:531-556, 549-552`; `backend.js:4561-4564` | Location de blobs: `proxy_cache_lock_timeout 35s; proxy_cache_lock_age 35s; proxy_read_timeout 40s` |
| F10 | «404» que son **200**: `/c/inhabitant/<sin opt-in>` devuelve 200 con `renderClearnetNotFound()` → la caché negativa por status no aplica; se cachea como HTML 60 s | `backend.js:6284-6293` | Aceptado y documentado en la sala («not accessible» = 200 por diseño upstream) |
| F11 | `/c` es **O(N·k)** (por habitante: `visibilityPrefs`, `name`, `collectClearnetItems({max:20})`) → el healthcheck no debe pegar a `/c` cada 30 s | `backend.js:6261-6279` | Healthcheck a `/c/inhabitant/@AAAA…AAA=.ed25519` (pasa `isFeedId`, una consulta backlinks, 200), `interval 60s` |
| F12 | **Indexing gate**: `allowDuringSync` incluye `startsWith('/c/')` pero no `/c` exacto ni `/clearnet`; solo actúa si el retraso > 1 MB (rebuild/primera sync). nginx cachearía `indexingView` (200) 60 s | `backend.js:11305-11323` | Residual aceptado; `hub-disk.sh prune-cache` tras un rebuild |
| F13 | `limit_req` por `$binary_remote_addr` es inútil: todo llega desde la IP de Caddy | lógica | `limit_req_zone $http_x_forwarded_for` (Caddy añade XFF por defecto **[NV-doc]**) |
| F14 | **`/qr/*` no lo usa el clearnet**: la vista solo enlaza `/c/blob` y `/c/inhabitant` + `/assets/images/snh-oasis.jpg`; `/qr/:feedId` codifica `http://localhost:3000/qr-action/…` → inútil en público | `clearnet_view.js:244` (grep `/qr` → 0); `backend.js:537, 4597` | **`/qr/*` fuera del `@hub`** (cambio respecto a v1 y a UPGRADE-PROTOCOL §8). Se mantienen `/assets/{styles,themes,images}/*` por seguridad |
| F15 | **Hairpin**: el invite sale con host `pub.escrivivir.co` (`external`); desde el bridge depende de NAT/DNS. `toLegacyInvite` acepta cualquier host | `pub/config/ssb/config:40`; `main_models.js:153-162` | Reescribir a `oasis-pub:8008:@…~seed` → tráfico en `oasis_pub_net`. Cinturón: `seeds` top-level en la config del HUB **[NV que ssb-conn 6 lo lea]** |
| F16 | `mergeDeep` **reemplaza arrays enteros** → el `connections.incoming.net` del HUB sustituye al de `server-config.json` y debe ser completo. El override apunta al mismo fichero que ya lee `ssb-config/inject` → se aplica dos veces, inocuo | `ssb_config.js:14-27` | `ssb-config` del HUB con `connections` completo |
| F17 | `/app/logs` es **peso muerto**: ningún escritor en `src/` (grep `writeFile|appendFile|createWriteStream` × `logs`); solo `mkdir`. Los logs reales van a stdout | `Dockerfile:32`; `docker-entrypoint.sh:18` | `logging.max-size/max-file` es lo que acota; el bind se mantiene por simetría con el pub |
| F18 | Egress y escrituras de arranque inocuas: `updater.getRemoteVersion()` (code.03c8.net/github) y `.update_required` en FS del contenedor; `apply_node_patches` reescribe node_modules; **`chown -R` de cada subdir de `.ssb` en cada arranque → O(ficheros en blobs/)** | `middleware.js:183`; `updater.js:6-7,33-38`; `docker-entrypoint.sh:24,90+` | Anotado; otro motivo para `prune-blobs` |
| F19 | `saveConfig` fuera de POST: `fediverse_model.js:97-105` (`setModuleFlag`) dentro de `try{}` → con `:ro` lanza EROFS y se traga. Resto en rutas POST (`backend.js:11126-11261` [V]; `5651`, `10712` [NV]). Gotcha del bind de fichero: si el editor reemplaza el inode en el host, el contenedor sigue viendo el viejo | `config-manager.js:115-117` | `:ro` aceptado; regla «sobrescribir in place» (igual que el Caddyfile); G2 busca `EROFS` en logs |
| F20 | Sweeps: `runSweepOnce`→`parliamentModel.sweepProposals` y `courtsModel.sweepCases` se disparan desde rutas GET no-clearnet y pueden `publish`. `larpModel.init()` solo publica con «casa»; mantiene `createLogStream({live:true})` y hace `unbox` de cada `.box` (CPU). `pubEngine` off | `backend.js:62-66, 3869, 11435`; `parliament_model.js:77,1474-1511`; `larp_model.js:807-852`; `banking_model.js:214-218` | **No exponer nada fuera de `/c*`, `/clearnet` y los tres subárboles de `/assets`** (nginx `location / { return 404; }` + Caddy solo `@hub`) |

## Escrituras en el feed del HUB — lista final

| # | Escritura | Estado |
|---|---|---|
| 1 | `contact` follow → pub al aceptar el invite | deseado **[NV comportamiento ssb-invite-client]** |
| 2 | `about` (nombre/descripción) por `/profile/edit` | deliberado, fase bootstrap |
| 3 | PM de bienvenida | **suprimido** (F4) |
| 4 | `oasisVersion` / dirección bancaria del server | no corren (F5) |
| 5 | LARP | no (sin casa) |
| 6 | sweeps parlamento/tribunales | solo si se visitan rutas no expuestas → no |
| 7 | pub engine | off (`walletPub.pubId:""`) |

Contraevidencia para el revisor: tras 24 h, `grep -a -c '"private":true'` en `flume/log.offset` del HUB
= 0 y los únicos `content.type` del propio feed son `contact` y `about`.

## Correcciones que el diseño incorporó (resumen)

1. Sin `profiles`; `OASIS_HUB_*` en `common.sh` y `.env*.example`.
2. Pre-crear `oasis-first-contact`.
3. `about` por `POST /profile/edit`; nada de `ssb-admin.js` en el HUB.
4. Invite reescrito a `oasis-pub:8008`; verificación por `conn.json`/`gossip.json` + follow-back.
5. `oasis-config.json` del HUB: `lanBroadcasting:false`, `aiMod/aiNavMod:off`, `ssbLogStream.limit` mayor, `walletPub.pubId:""`.
6. nginx: `proxy_hide_header` ×4 (+ `Set-Cookie`), `limit_req` por XFF, lock largo en blobs, `resolver 127.0.0.11` + `proxy_pass` con variable **sin URI**, `location / { return 404; }`.
7. Caddy: `@hub` sin `/qr/*`; `header {}` global intacto.
8. Healthcheck a `/c/inhabitant/@AAAA…`, `interval 60s`.
9. `NODE_OPTIONS=--max-old-space-size` ≈ 70 % de `mem_limit`; `mem_limit` desde el primer `up` (el pub no tiene límite: un pico del HUB podría empujarlo al OOM-killer → WP-O47).

## Riesgos residuales que el revisor dejó abiertos

- **[NV]** `ssb-invite-client.accept` (follow + `conn.remember`), lectura de `seeds` por ssb-conn 6.0.3,
  reconexión tras reinicio → los cubre G3 empíricamente.
- **[NV-doc]** Caddy conserva `Host` y añade `X-Forwarded-For`; nginx `proxy_pass $var` sin URI pasa
  `$request_uri` intacto; envsubst de `nginx:alpine` solo sustituye variables definidas → G1/G4.
- Indexing gate cacheado 60 s tras rebuild (F12).
- El HUB replica a hops 2 también `.box` privados (disco) y `larp_model` los intenta desencriptar en vivo (CPU).
- `chown -R` de `blobs/` en cada arranque (F18).
- Los HTML de `/c` no llevan `Cache-Control` → nginx aplica `proxy_cache_valid`; el navegador no cachea.
- OOM del pub (sin `mem_limit`) por un pico del HUB → dependencia real de la medición de memoria; WP-O47.
