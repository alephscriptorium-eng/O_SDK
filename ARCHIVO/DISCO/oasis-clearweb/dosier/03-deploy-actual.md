# 03 · Despliegue actual del pub (estado antes del WP-O46)

## 1. `pub/docker-compose.pub.yml` (102 líneas) — `name: oasis-pub-scriptorium`

| Servicio | Imagen | Puertos | Volúmenes (bind) | Notas |
|---|---|---|---|---|
| `oasis-pub` (`:4-32`) | `oasis-pub-scriptorium:latest` (build `..`/`Dockerfile`) | `${OASIS_PUB_SSB_PORT:-8008}:8008` | `${OASIS_PUB_SSB_DATA_DIR}:/home/oasis/.ssb` · `${OASIS_PUB_LOGS_DIR}:/app/logs` · `${OASIS_PUB_SSB_CONFIG_FILE}:/home/oasis/.ssb/config:ro` | **`command: ["server"]`** · env `OASIS_SKIP_AI_MODEL=true`, `OASIS_SERVER_CONFIG_OVERRIDE=/home/oasis/.ssb/config`, `HOME`, `SSB_PATH` · healthcheck por socket unix (`:25-30`) · **3000 no se publica** · **sin `OASIS_PUB_WEB_HOST`** |
| `pub-panel-api` (`:34-56`) | `oasis-pub-panel-api:latest` | `127.0.0.1:8787` | `/var/run/docker.sock` | `PUB_PANEL_TOKEN` obligatorio; rutas públicas `/public/status`, `/public/network` |
| `pub-web` (`:58-78`) | `caddy:2-alpine` | 80, 443 | `./caddy/Caddyfile:/etc/caddy/Caddyfile:ro` (**fichero**) · `./site:/srv/site:ro` · `${OASIS_PUB_TEATRO_DIR}:/srv/site/teatro:ro` · caddy-data/config | `OASIS_PUB_WEB_HOST` |
| `pub-frontend` (`:80-97`) | — | — | — | `profiles: ["frontend"]`; contexto inexistente (WP-O45) |

Red única `oasis_pub_net` (bridge). **Ningún `mem_limit`** en ningún servicio. Todos bind mounts, ningún named volume.

## 2. `docker-entrypoint.sh` (544 líneas)

- `:10-15` `CURRENT_DIR=/app`, `CONFIG_FILE=/app/src/configs/oasis-config.json`.
- `:17-28` re-exec como `oasis` si arranca root; `:23` `find /home/oasis/.ssb -mindepth 1 -maxdepth 1 ! -name
  config -exec chown -R oasis:oasis {} +` (excluye `config`; **`-R` sobre cada subdir** → O(blobs) por arranque).
- `setup_ssb_config` (`:48-85`): **reasigna `CONFIG_FILE=/home/oasis/.ssb/config`** (`:49`, bug preexistente
  que pisa el path de `setup_oasis_config`); si el fichero existe **no genera nada** (`:50,83`); si no,
  escribe una config con `caps.shs` aleatorio, un solo listener 8008 y `blobs.max` 50 MB (sin hops/friends).
- `check_and_recover_ssb` (`:310-420`) **comentado** (`:462`).
- `:468/475/488`: `SKIP_AI_MODEL=true || MODE=server` salta descarga IA, enlace y `setup_oasis_config`.
- `:482` `install_runtime_deps`; `:485` `apply_node_patches` (reescribe `node_modules` en cada arranque).
- Modos (`:515-544`):
  - `server` → `exec node SSB_server.js start` (solo sbot).
  - `client|backend` → `exec node backend.js --host 0.0.0.0`.
  - `full|*` → `exec node backend.js --host 0.0.0.0` (bloque IA comentado).
  **No existe `server-hub`.** Ningún modo pasa `--public`; entra por `OASIS_PUBLIC`.
- `Dockerfile`: `node:20-bookworm-slim`, instala `curl` (`:10`), usuario `oasis` (`:23`), `npm install` como
  `oasis` (`:46-47`), vuelve a root para runtime (`:50`), `EXPOSE 8008 3000`, `CMD ["full"]`.

## 3. `pub/caddy/Caddyfile` (107 líneas)

Vhost del pub (`:1-20`): `encode zstd gzip`; `header { X-Content-Type-Options nosniff; X-Frame-Options DENY;
Referrer-Policy strict-origin-when-cross-origin }`; `@public path /public/*` → `pub-panel-api:8787`;
`handle { root * /srv/site; try_files {path} {path}/index.html /index.html; file_server }`.
**Sin `@hub`, sin `reverse_proxy` a 3000.** `/assets/*` cae en `file_server` (`pub/site/assets/fanzine.css`).

Edge compartido (`:22-107`), 5 vhosts con `/healthz` propio y `reverse_proxy` por alias de red:

| Vhost | upstream |
|---|---|
| `scriptorium.escrivivir.co` (`:26`) | `scriptorium-nodered:1880` |
| `admin.scriptorium.escrivivir.co` (`:42`, `X-Robots-Tag noindex`) | `scriptorium-nodered:1880` |
| `mcp.scriptorium.escrivivir.co` (`:59`) | `scriptorium-mcp-devops:3003` |
| `npm.scriptorium.escrivivir.co` (`:75`) | `scriptorium-verdaccio:4873` |
| `rooms.scriptorium.escrivivir.co` (`:92`) | `scriptorium-rooms:3010` |

Regla WP-O74 / UPGRADE-PROTOCOL §4 `:128-132`: `caddy validate` + `caddy reload`, **nunca `restart pub-web`**.
`MAPA.md:157-161`: los upstreams se resuelven por alias de red → un contenedor nuevo en `oasis_pub_net`
funciona sin tocar IPs.

## 4. Config SSB del pub (`pub/config/ssb/config`, 71 líneas)

`caps.shs` ciclo 6 · `pub:true` · `local:false` · `friends {dunbar:300, hops:3}` · `gossip {connections:50,
local:false, friends:true, seed:true, global:true}` · `replicationScheduler {autostart:true}` ·
`autofollow {enabled:true, feeds:["@0qSCyK3xyL71X4qKkmf84Cb2riP6OeUqxCvbP2Z6HWs=.ed25519"]}` (La Plaza) ·
`connections.seeds: []` · incoming net `[ {scope [device,local,public], shs, 8008, host 0.0.0.0, external
pub.escrivivir.co}, {8008, localhost, device} ]` · incoming unix `noauth` · outgoing net shs.
`config.local` idéntico con puerto 8009 y `external: localhost`. **Sin clave `blobs`** (la fuerza `ssb_config.js:44`).

Identidad del pub: `@/snvahvaTP5obvdiYva9OX9NNnTSlUQbEUBSuDRzrZA=.ed25519` (empieza por `@/` → URLs
`/c/inhabitant/%40%2F…`). Journal: `mode: server`, `gitSha f98cb6f`, `oasisVersion 1.0.8`, `cycle 6`.

## 5. Scripts

### `pub/scripts/` (todos `source common.sh`)

- `common.sh`: `compose_pub()` = `docker compose --env-file $PUB_ENV_PATH -f docker-compose.pub.yml` (`:12-17`);
  `is_canonical_vps_layout()` = `PUB_DIR == /opt/oasis-scriptorium/pub` (`:36-38`, **no se cumple en el VPS**);
  `validate_vps_persistent_paths()` valida `OASIS_PUB_{SSB_DATA,LOGS,CADDY_DATA,CADDY_CONFIG,TEATRO}_DIR`
  (`:75-86`); `ensure_runtime_dirs()` (`:88-95`). **Añadir `OASIS_HUB_*_DIR`.**
- `deploy.sh`: `compose_pub up -d --build` de **todo** (`:16`) + journal con `--mode server` **hardcodeado**
  (`:26-27`). UPGRADE-PROTOCOL §4 `:124-125`: «No uses el `deploy.sh` del VPS».
- `invite.sh`: `ssb-admin.js invite.create $USES` dentro de `oasis-pub` (`:9`).
- `join-client.sh:25`: `curl -X POST …/settings/invite/accept --data-urlencode invite=…` **sin `Referer`**
  (→ 400 con el middleware actual; ver `05` F1).
- `whoami.sh`, `publish-profile.sh`, `announce-pub.sh`, `join-info.sh`, `maint-ui.sh` (segundo backend sobre
  el `.ssb` del pub con `--stop-pub` obligatorio; `MODE=client`; puerto 3001).
- `pub/tools/ssb-admin.js`: comandos `whoami`, `invite.create`, `publish-about`, `announce-pub`, `follow`,
  `publish-json`; conecta con `ssbClient(config.keys, config)` (`:17`) → necesita `manifest.json` o
  manifest remoto (**[NV]** ssb-client 4.9.0, `src/server/package-lock.json:14352-14353`) → **no fiable en
  el HUB** (modo backend no escribe `manifest.json`).

### `devops/scripts/`

- `lib-host.sh`: carga `devops/hosts/<DEVOPS_HOST>/host.env` (`scriptorium`: `REMOTE_USER=debian`,
  `REMOTE_HOST=92.243.24.163`, `KEY_FILE=gandi_pub_ed25519`, `PUB_CONTAINER=oasis-pub-scriptorium`,
  `EXPECTED_SHS`, `SNH_FEED`).
- `deploy-site.sh:24`: `rsync -az --checksum --delete` **sin exclusiones** (borraría `*.bak-*` de `site/`).
- `deploy-log.sh`: append de una línea JSON al journal (`:44-47`).
- `deploy-status.sh`: última línea del journal + `pub-federation.sh status` + directorio `oasis-project.pub`.
- `backup-oasis-pub.sh`: identidad (`secret, config, gossip.json, gossip_unfollowed.json, manifest.json`)
  con sha256 + tarball de `ssb-data` en streaming; **no consulta `df`**.
- `deploy-teatro.sh:52-61`: patrón ssh + `df -h /srv/oasis` (modelo de `hub-disk.sh`).
- `test-invite.sh`: `diagnose` (crea invite) y `redeem <URL>` (POST sin Referer + cuenta `contact` en
  `flume/log.offset` del pub, `:46`) — el conteo sí es reutilizable.
- `upgrade-preflight.sh`: git limpio, drift de versión y de `caps.shs`; **no** mira disco ni VPS.

### npm (`package.json:40-76`)

`pub:*` → `.env`; `pub:local:*` → `env-run.sh .env.local`; `devops:status|preflight|backup|federation|invite|
test-invite`; `devops:site:deploy`. No hay script para `deploy-teatro.sh` ni `bootstrap/verify-debian13`.
**Añadir `devops:hub-disk`.**

## 6. Precedente: `pub/blobstore-sidecar/` (preparado, no desplegado)

- `Dockerfile`: `node:20-bookworm-slim` (sodium-native), `EXPOSE 8790`.
- `deploy/compose.blobstore.fragmento.yml`: fragmento **separado a propósito** del compose vivo (`:1-5`);
  monta **todo** `${OASIS_PUB_SSB_DATA_DIR}:/ssb` (`:28`) para hablar por `unix:/ssb/socket~noauth`
  (`src/cableado-sbot.mjs:8-16`, manifest mínimo `blobs.{add,get,has,want,size}` + `whoami`); publica solo
  en `127.0.0.1:8790`; sin `mem_limit`, sin healthcheck; corre como root.
- Contraevidencia recogida: contradice la CA de WP-O50 «montar **solo** el socket, no el directorio con
  la identidad» (`plan/BACKLOG.md:456-459`; `MAPA.md:191-192`). Es la razón de que WP-O50 no tenga GO.
- **La v2 no reutiliza este patrón**: el HUB tiene `.ssb` propio y no ve nada del pub.

## 7. Estado del HUB en el repo antes del WP

- El HUB `/c` existe solo en `backend.js`; `oasis.sh:65-71` (modo `server|pub`) hace `exec node
  SSB_server.js start`, igual que el entrypoint. `docs/PUB/clearnet.md:30-36` describe el `oasis.sh
  server` de **upstream** (sbot + `backend.js --public`), que este fork no hace (reconocido en
  `UPGRADE-PROTOCOL.md:169-171`).
- `UPGRADE-PROTOCOL.md §8` («no activado por defecto», `:167-201`) describe la receta v1 (entrypoint +
  `OASIS_PUB_WEB_HOST` + `@hub` con `/qr/*` y `@blob`). La v2 la **sustituye**.
- `pub/site/`: `index.html`, `admin/`, `assets/fanzine.css`, `hackeria/`, `parlament/`, `scriptorium/`,
  `teatro/.gitkeep`, `ico.png`. Sin `hub/`, sin `robots.txt`, sin referencias a `/c`.
