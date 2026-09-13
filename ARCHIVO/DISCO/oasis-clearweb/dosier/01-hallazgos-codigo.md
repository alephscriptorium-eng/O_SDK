# 01 · Hallazgos en el código (Oasis 1.0.8, `src/`)

Todo **[V]** salvo marca contraria. Rutas relativas a la raíz del repo.

## 1. `backend.js` embebe su propio sbot (el hecho que cambia el diseño)

- `src/backend/backend.js:9` → `require('../server/SSB_server.js')` (carga plugins, registra `uncaughtException`).
- `src/client/gui.js:12-16`:
  ```js
  let internalSSB = null;
  try { const { server } = require('../server/SSB_server'); internalSSB = server; } catch {}
  ```
  El destructuring invoca el getter `src/server/SSB_server.js:252-255`:
  `get server() { if (!server) server = Server(config); return server; }`.
- `server` solo está pre-inicializado si `argv[0] === 'start'` (`SSB_server.js:102,144-150`). `backend.js`
  se lanza como `node backend.js …` → el getter **crea un sbot nuevo** en el mismo proceso.
- Si `Server(config)` falla por LOCK (otro sbot tiene ese `~/.ssb`), el `catch {}` lo silencia y
  `cooler.open()` cae a `ssb-client` sobre `unix:<path>/socket~noauth:<pub>` (`gui.js:23-25,50-76`).
- `docs/devs/install.md:17-24` solo describe el camino por socket («two-process architecture»); **la
  doc no menciona el sbot embebido**. El código sí.

Consecuencias:
1. Un contenedor con `backend.js` y un `~/.ssb` **propio** es un nodo SSB completo (replica, sirve web) sin `SSB_server.js`.
2. El backend **no puede** hablar con un sbot remoto por `net:…~shs`: `remote` es constante de módulo
   `unix:${socketPath}~noauth:${publicInteger}` (`gui.js:23-25`); `customConfig` de `ensureConnection`
   (`gui.js:80-108`) nunca se usa; no hay env `OASIS_REMOTE` (grep de `process.env.OASIS*` → solo
   `OASIS_TEST`, `OASIS_DEBUG`, `OASIS_SERVER_CONFIG_OVERRIDE`, `OASIS_STATE_DIR`, `OASIS_BANKING_DIR`, `OASIS_MOBILE`).
3. Montar el **mismo** `.ssb` que el pub colisiona por LOCK: precedente `pub/scripts/maint-ui.sh`
   (`--stop-pub` obligatorio; «do not run both writers at once»).

## 2. Opciones del backend por variables de entorno

`src/client/oasis_client.js:53-66`: `yargs(...).env("OASIS")`.

| Opción | Env | Default |
|---|---|---|
| `--open` | `OASIS_OPEN` | true |
| `--offline` | `OASIS_OFFLINE` | false |
| `--host` | `OASIS_HOST` | `localhost` |
| `--allow-host` | `OASIS_ALLOW_HOST` | `null` |
| `--port` | `OASIS_PORT` | 3000 |
| `--public` | `OASIS_PUBLIC` | false |
| `--debug` | `OASIS_DEBUG` | false |

El entrypoint en modo `client|backend` ejecuta `exec node backend.js --host 0.0.0.0`
(`docker-entrypoint.sh:521-524`); el resto de opciones entra por env. Presets desde
`envPaths("oasis").config/default.json` (`backend.js:14-20`).

## 3. Qué hace `--public`

- `backend.js:11284`: cualquier método ≠ GET → **403**.
- `config.public` se propaga como `isPublic` a ~50 modelos (`backend.js:791-796, 1042-1106`). La
  redacción por `publicWebHosting` está en `src/models/main_models.js:348,373,398,409,416` y afecta a
  listados internos, **no** a `/c` (ver §5).
- `/json/:message` lanza error en público (`backend.js:4543-4547`).
- Nada se desmonta: el árbol de rutas completo sigue registrado (`backend.js:11281`). La exposición la
  decide el proxy (solo `/c*` + assets).

## 4. Middleware HTTP (`src/client/middleware.js`)

- `:50-56` `isClearnetPath` = `/c`, `/c/…`, `/c?…` → `isValidRequest` devuelve `method === 'GET'` **sin
  comprobar Host**.
- `:57-63` resto de rutas: Host debe estar en `validHosts`; no-GET exige `Referer` cuyo host esté en
  `validHosts` y cuyo path no empiece por `/blob/`. Fallo → `ctx.assert(…, 400)` (`:160-164`).
- `:100` `/assets` (koa-static) se monta **antes** de la validación → tampoco valida Host.
- `:123-150` CSP para `/c*`: `default-src 'self'; script-src 'none'; style-src 'self' 'unsafe-inline';
  img-src 'self' data:; media-src 'self' blob:; connect-src 'self'; form-action 'self'; object-src
  'none'; base-uri 'none'; frame-ancestors 'none'`.
- `:150-156` cabeceras fijas del backend: `X-Frame-Options: SAMEORIGIN`, `X-Content-Type-Options:
  nosniff`, `Referrer-Policy: same-origin`, `Permissions-Policy: speaker=(self)`.
- `:168-173` minificación del HTML clearnet (`obfuscateClearnetHtml`, `:8-26`).
- `:185-208` `validHosts` = `allowHost` + `address.address` + `host` + IPv4 locales + `localhost`/`127.0.0.1`.
- `:183` al arrancar llama `updater.getRemoteVersion()` (egress a code.03c8.net/github; inocuo).

## 5. Rutas del HUB y qué muestran

| Ruta | Línea |
|---|---|
| `GET /clearnet` → redirect `/c` | `backend.js:6260` |
| `GET /c` | `:6261-6281` |
| `GET /c/inhabitant/:feedId` | `:6282-6318` |
| `GET /c/blob/:cnBlobId` | `:4557-4591` |
| `GET /c/school/:id`, `/c/shops/:id` | `:6319-6353` |
| `GET /c/{audios,podcasts,videos,images,documents,torrents}/:id`, `/c/blog/:msgKey` | `:6163-6259` |
| `GET /c/projects/:id` | `:6724` |
| `GET /qr/:feedId` (PNG, `no-store`) — **no lo usa la vista clearnet** | `:4592-4607` |

**`/c` lista autores del log local, no solo seguidos**:
- `inhabitantsModel.listInhabitants({filter:'all', includeInactive:true})` →
  `src/models/inhabitants_model.js:132-168` → `listAllBase` (`:90-105`) → `readTyped(ssb, [], {limit:
  logLimit, withWindow:true})` = autores únicos de la ventana del log. No consulta `friends.graph`
  (eso solo para `filter:'contacts'`, `:169-179`).
- `logLimit = getConfig().ssbLogStream?.limit || 1000` (`inhabitants_model.js:12`, **leído una vez al
  cargar el módulo**); `src/configs/oasis-config.json:77-79` = 2000.
- `readTyped` con ventana (`src/models/typed_log.js:77-116`) → `ssb.createLogStream({reverse:true, limit})`.
- Único gate: `prefs.clearnet !== true → continue` (`backend.js:6268-6269`).
- Por cada habitante: `visibilityPrefs`, `name`, `collectClearnetItems(feedId, prefs, {max:20})` → O(N·k)
  por petición. **No usar `/c` como healthcheck.**

`collectClearnetItems` (`backend.js:368-536`): por sub-preferencia activa consulta el modelo y filtra
`author === feedId`; `clearnetBookmarks` está en las prefs (`:4427,4465`) pero **no** lo implementa;
comprueba `blobs.has` de cada imagen (`:509-533`).

`/c/inhabitant/:feedId` (`:6282-6318`): acepta cualquier feedId válido; si no tiene opt-in devuelve
**HTTP 200** con `renderClearnetNotFound()` (`:6284-6293`).

Opt-in: `visibilityPrefs` se lee por `backlinks.read` filtrando `type==='about'` **y** `author===feedId`
(`main_models.js:305-345, 166-199`) → autodeclarado, viaja con el feed. `clearnet` es el OR de las 13
sub-prefs (`backend.js:4453`); `POST /profile/clearnet-toggle` (`:4525-4541`). `publicWebHosting` es
otro campo (`main_models.js:294-300`) y no interviene en `/c`.

Assets que referencia la vista: `src/views/clearnet_view.js:244` → `/assets/images/snh-oasis.jpg`.
CSS inline (`clearnet_view.js:209-249`); paleta desde `getConfig().themes.current` (`:175-183`, tabla `:142-173`).

## 6. Gate de indexado y refresco

- `backend.js:11305-11323`: `allowDuringSync` incluye `startsWith('/c/')` pero **no** `/c` exacto ni
  `/clearnet`; `/qr`, `/assets` van por la rama binaria. Solo actúa si el retraso de índices > 1 MB
  (tras rebuild o primera sincronización) → devuelve `indexingView` con 200.
- `:11336-11338` el refresco de `sharedState` cada 60 s salta `/c/`, `/qr`, `/assets`, `/image/`, `/blob/`.

## 7. Cachés en memoria

- `src/models/typed_log.js:11-20`: `WeakMap` por objeto `ssb`; por tipo y ventana; sin TTL; refresco por
  *tail probe* (`TAIL_PROBE=50`, `LOG_TAIL_PROBE=20`, `:3-4`). Es la única caché que toca `/c`.
- `CARBON_TTL_MS` 5 min (`backend.js:200-206`), `blobCache` por llamada (`:512`), `nameCache` — no
  intervienen en `/c`.
- `docs/PUB/clearnet.md:59`: «The HUB reads the replicated log on each request. On a large PUB a
  caching proxy in front of `/c` keeps it snappy.» → no hay caché de página.

## 8. Config del sbot (`src/server/ssb_config.js`, 52 líneas)

| Paso | Línea | Efecto |
|---|---|---|
| 1 | `:3,29` | `ssb-config/inject('ssb')`: defaults + `~/.ssb/config` + args tras `--` |
| 2 | `:6-7,30` | `src/configs/server-config.json` con `mergeDeep` **encima** |
| 3 | `:32-35` | `--debug`/`OASIS_DEBUG` → `logging.level=debug` |
| 4 | `:37-41` | `OASIS_SERVER_CONFIG_OVERRIDE=<ruta>` mergeado **último** (guard del fork) |
| 5 | `:43-45` | `config.blobs.max = 50 MB` **forzado** |
| 6 | `:47-50` | `config.statePath(name)` → `OASIS_STATE_DIR/name` o `config.path/name` |

`mergeDeep` (`:14-27`) **reemplaza arrays enteros** → `connections.incoming.net` de un override debe ir completo.

`src/configs/server-config.json`: `caps.shs` ciclo 6, `pub:false`, `local:true`, `friends {dunbar:300,
hops:2}`, `gossip {connections:30, local:true, friends:true, seed:true, global:true}`,
`replicationScheduler {autostart:true}`, `autofollow {enabled:false}`, `connections.seeds: []`,
incoming net `scope ["device","local"]` 8008, unix noauth, outgoing net shs.

**No existen** en el repo: `ebt`, `conn`, `blobs.path`, `blobs.sympathy/stingy/legacy/pushy`, `pubs`,
`blobsPath`, claves `cache`/`hubCache`/`clearnet` en `oasis-config.json`, `--follow` CLI.

## 9. Plugins y modo `start` (`src/server/SSB_server.js`)

- `:54-86`: `ssb-db` (flume), master, gossip, ebt, friends, blobs, meme, plugins, conn, box, search,
  private, friend-pub, **`config.pub ? 'ssb-invite' : 'ssb-invite-client'`** (`:70`), logging,
  replication-scheduler, partial-replication, about, onion, unix-socket, no-auth, backlinks, links,
  tangle, query. Si `!config.pub`: `ssb-lan` + `./lanRouter` (`:83-86`).
- `ssb-autofollow` solo si `autofollow` queda no vacío (`:88-98`); `enabled:false` → `null` → no se carga.
- Solo en `argv[0]==='start'` (`:144-248`): escribe `manifest.json` (`:100,150`), alias CLI, log de
  conexiones, **publica dirección bancaria a los 5 s** (`:220-226`) y **`oasisVersion` a los 7 s**
  (`:228-246`). El getter (modo backend) **no** hace nada de esto.
- `lanRouter.startRouter` no arranca si `oasis-config.json` tiene `lanBroadcasting === false`
  (`src/server/lanRouter.js:55-58`).

## 10. Seguir y replicar a otro nodo

- Aceptar invite: `meta.acceptInvite` (`main_models.js:927-933`) → `toLegacyInvite` (`:153-163`,
  `net:h:p~shs:k~invite:x` → `h:p:@k.ed25519~x`; acepta cualquier host) → `ssb.invite.accept`.
- Única ruta HTTP: `POST /settings/invite/accept` (`backend.js:10736-10751`): comprueba `~/.ssb/gossip.json`
  + `gossip_unfollowed.json` (rutas con `os.homedir()` hardcodeado, `:2153-2161`), `try{}catch{}` y
  **302 siempre** (`safeRefererRedirect`, `:163-175`). No hay GET ni comando CLI (`scripts/oasis-pub.js:33-80`
  solo whoami|invite|name|announce|follow|status|gossip).
- Follow: `GET /qr-action/follow/:feedId` (`:2716-2721`, GET → pasa en `--public` si Host válido);
  `POST /invites/inhabitant/follow` (`:10752-10770`); `POST /peers/connect` (`:10799-10825`:
  `conn.remember` + `conn.connect` + `contact`); CLI `oasis.sh follow` (`scripts/oasis-pub.js:62-68`).
- `hops` efectivo: `config.conn?.hops ?? config.friends?.hops ?? 2` (`src/server/ssb_metadata.js:87`).
- Semántica interna de `ssb-ebt`, `ssb-replication-scheduler`, `ssb-conn` (6.0.3), `ssb-invite-client`:
  **[NV]** (no hay `src/server/node_modules`).

## 11. Escrituras automáticas del backend en su propio feed

| Qué | Dónde | Condición | En el HUB |
|---|---|---|---|
| PM de bienvenida a sí mismo | `backend.js:11437-11484` → `pm_model.js:43-58` | salta si existe `~/.ssb/oasis-first-contact` (`onboarding_model.js:103-106`: sin feedId = solo existencia) | **suprimido** pre-creando el flag |
| `oasisVersion` | `backend.js:1843-1854` y `SSB_server.js:228-246` | la del backend exige `latestSeq≠0`; la del server solo en `start` | no en el arranque limpio; puede aparecer en arranques posteriores por la del backend **[V parcial]** |
| dirección bancaria | `SSB_server.js:220-226` | solo `start` | no |
| pub engine | `backend.js:11423-11433` | `isPubNode()` = `walletPub.pubId === keys.id` (`banking_model.js:214-218`) | no (`pubId:""` en el config del HUB) |
| LARP | `backend.js:11435` → `larp_model.js:870-884` | publica solo con «casa» (`:807-846`); mantiene `createLogStream({live:true})` y hace `unbox` de cada `.box` | no publica; CPU en ráfagas |
| sweeps parlamento/tribunales | `backend.js:62-66, 3869` | desde rutas GET no clearnet | no expuestas por Caddy |
| `.update_required` | `middleware.js:183`, `updater.js:33-38` | FS del contenedor | inocuo |
| `contact` (follow al pub) | `invite.accept` | deliberado | sí |
| `about` (nombre/descr.) | `POST /profile/edit` (`backend.js:4382, 4481-4484`) | deliberado, fase bootstrap | sí |

## 12. Almacenamiento del nodo

| Ruta | Quién | Ref |
|---|---|---|
| `<path>/flume/` (`log.offset` + índices) | `ssb-db` | `SSB_server.js:57`; `docs/PUB/RECOVERY-PROTOCOL.md:106,114` |
| `<path>/blobs/sha256/xx/…` | `ssb-blobs` **y** `blob.getResolved` escribe a mano | `main_models.js:485-494, 549-553` |
| `<path>/blobs/tmp` | uploads | `backend.js:2101,…` |
| `<path>/ebt/` | `ssb-ebt` | RECOVERY-PROTOCOL §derivados |
| `conn.json`, `gossip.json`, `gossip_unfollowed.json` | `ssb-conn` / rutas de invites | `docker-entrypoint.sh:385-390`; `backend.js:2153-2161` |
| `secret`, `socket`, `manifest.json` (solo `start`), `config` | identidad / unix-socket / server / entrypoint | `gui.js:23`; `SSB_server.js:100,150`; `docker-entrypoint.sh:50-84` |
| `oasis-first-contact`, `keys/*.asc`, `pad-keys.json`, `content_favorites.json`, `backup.json` | backend/modelos | `backend.js:11441, 4408`; `pads_model.js:40`; `ssb_config.js:47-50` |

- **Crecimiento**: `log.offset` con la replicación (hops); `blobs/` con cada `GET /c/blob/<id>` ausente
  (`blobs.want` + espera hasta 30 s + escritura, `main_models.js:531-557`; 404 si no llega,
  `backend.js:4561-4564`). Blobs son content-addressed → podables (re-fetch por `want`) **[NV ssb-blobs]**.
- `/app/logs`: sin escritores en `src/` (grep `writeFile|appendFile|createWriteStream` × `logs`); solo
  `mkdir` en `Dockerfile:32` y `docker-entrypoint.sh:18`. Los logs van a stdout.
- Rutas con `os.homedir()` hardcodeado (ignoran `config.path`): `backend.js:2101,2153-2154,4723`;
  `main_models.js:486`; `stats_model.js:466-472`. Irrelevante con HOME propio por contenedor.

## 13. `oasis-config.json` (`src/configs/config-manager.js`)

- `getConfig()` relee el fichero en **cada** llamada (`:95-113`) con normalizaciones en memoria.
- Escribe solo si el fichero no existe (`:92`) o en `saveConfig` (`:115-117`). Llamadas a `saveConfig`:
  rutas POST (`backend.js:11126-11261` [V], `5651`, `10712` [NV no leídas]) y
  `src/models/fediverse_model.js:97-105` (`setModuleFlag`, dentro de `try{}`) → un bind `:ro` no rompe.
- Claves relevantes para el HUB: `modules.aiMod`/`aiNavMod` (repo: `"on"`; `startAI()` solo desde rutas
  `backend.js:2422,7149,7429`), `ssbLogStream.limit`, `themes.current`, `lanBroadcasting`, `walletPub.pubId`, `language`.
- Los módulos (`modules.*`) **no** se consultan en ninguna ruta `/c*` (sin `checkMod` en `:6163-6353`, `:4557`).

## 14. `blockchain-cycle.json`

`src/configs/blockchain-cycle.json` = `{"cycle": 6, "url": "https://laplaza.solarnethub.com"}`. No lo
lee ningún código de `src/` (grep); único consumidor `pub/scripts/deploy.sh:24` (journal). Fork-only,
preservado en el overlay (`docs/PUB/UPGRADE-PROTOCOL.md:11-18,55,82,94`; `MAPA.md:240`).
