# Reporte · WP-O97 · Upgrade Oasis 1.0.8 → 1.1.2 con el HUB activo

- **Fecha**: 2026-09-17 · **Rama**: `upgrade/oasis-1.1.2` sobre `588950c` · **Método**: `UPGRADE-PROTOCOL.md` + `HUB-PROTOCOL.md` §5, un solo operador.
- **Resultado**: **desplegado**. `pub.escrivivir.co` en 1.1.2 (imagen `b6181cb7`) con pub y HUB healthy; journal `--mode server+hub` 2026-09-17 11:47 UTC.
- **Upstream**: `oasis-upstream/main` = `3c9bf9a` «Oasis release 1.1.2» (releases 1.0.9, 1.1.0, 1.1.1, 1.1.2; 88 ficheros en `src/`, +2408/−1384).
- **Ciclo de red**: sin cambios. `caps.shs` local = cap actual del directorio (`H5EC+V5B…`, ciclo 6). Caso «mantener» (§5 del protocolo).

## Estado de partida (§0/§1)

| Comprobación | Resultado |
|---|---|
| `deploy-status.sh` | journal 2026-09-13 20:02 UTC `1.0.8 --mode server+hub` · pub `Up 4 days (healthy)` · feed `@/snvahva…` · directorio **VERDE** ciclo 6 · `hub-disk check` OK (`/srv/oasis` 15 %, `/` 49 %) |
| `upgrade-preflight.sh` | WARN ×2: árbol no limpio (solo `.claude/settings.json` sin trackear) · upstream 1.0.8 → 1.1.2. Cap coincide. |
| VPS `docker ps` | `oasis-pub-scriptorium` y `oasis-pub-hub` healthy, **misma imagen** `d1bb7d47` (`:latest`); `:0.9.6` conservada como rollback anterior |
| Disco VPS | `/` 13 G libres; `docker system df` 2,96 GB reclamables (`:0.9.6` + caché de build) |
| Layout VPS | código en `/opt/oasis-scriptorium/src` (1.0.8), compose y configs en `OASIS_PUB/` (pre-refactor); `/srv/oasis/src-0.9.6.tgz` existe, `src.old` no |

## Qué se entregó

| Pieza | Commit |
|---|---|
| Overlay limpio de `src/` desde `3c9bf9a`; `blockchain-cycle.json` preservado; 4 guards repuestos (`backend.js` y `settings_view.js` a mano; `ssb_config.js` y `updater.js` desde HEAD porque upstream no los tocó); `clearnet.md` upstream + nota del fork | `e545d21` |
| HUB: `location ~ ^/c/assets/` cacheada en `nginx.conf.template`; comentario en `Caddyfile`; Sala 04 12 → 16 tipos; `HUB-PROTOCOL.md` §2/§5.1/§5.5; `UPGRADE-PROTOCOL.md`; CHANGELOG; BACKLOG WP-O97 | `f6f4fbb` |

## Criterios de aceptación (BRIEF) · evidencia

| CA | Resultado |
|---|---|
| `git diff oasis-upstream/main --stat -- src/` = 4 guards + `blockchain-cycle.json` | ✅ `backend.js 7 / updater.js 4 / blockchain-cycle.json 4 / ssb_config.js 23 / settings_view.js 5` — 5 ficheros, nada más |
| `node --check` de los guards editados · versión | ✅ parse OK · `"version": "1.1.2"` |
| Greps §5.1 ≥ 1 sobre el árbol nuevo | ✅ todos 1–2 (`OASIS_SERVER_CONFIG_OVERRIDE` = 1 tras reponer el guard; 0 en upstream por diseño) |
| `ssb-*` en `src/server/package.json` | ✅ sin cambios → G3 (`hub-conn-fix.js`) no se repite |
| `oasis-config.json` / `server-config.json` upstream | ✅ sin cambios → copia del HUB no regenerada; diff = 4 diferencias efectivas (`aiMod`, `aiNavMod`, `ssbLogStream.limit`, `lanBroadcasting`) |
| Cabeceras del backend (`middleware.js`) | ✅ mismas 3 en `proxy_hide_header`; upstream solo cambió la regex de ofuscación del HTML |
| `nginx -t` con la plantilla nueva · `caddy validate` | ✅ «test is successful» · «Valid configuration» (en contenedores `nginx:alpine` / `caddy:2-alpine`) |
| Build de la imagen 1.1.2 | ✅ local `oasis-pub-scriptorium:1.1.2-local` (`docker build .`, EXIT=0, 123 s de export) |
| Smoke en modo `backend` (HUB) con `ssb-config` y `oasis-config.json` del HUB | ✅ healthcheck 200 a los 6 s · `apply_node_patches` 3/3 ✓ · `[Version: 1.1.2]` · `/c` 200 · `/c/inhabitant/%40%2F…` 200 · **`/c/assets/images/snh-oasis.jpg` 200 image/jpeg** (y `/assets/images/...` sigue 200) · `/c/wiki/x`, `/c/market/x`, `/c/feed/x`, `/c/bookmarks/x` 200 · `/c/qr/%40abc.ed25519` 200 image/png · `POST /c` 400 (sin Referer, como documenta el BRIEF de WP-O46) |
| `Cache-Control` de `/c/assets/*` desde koa-static | `max-age=0` → confirma que la `location` nueva con `proxy_ignore_headers` era necesaria |
| pub y HUB healthy con la imagen nueva, feed ids sin cambios | ✅ `oasis-pub-scriptorium` healthy a los 30 s y `oasis-pub-hub` a los 60 s, ambos `sha256:b6181cb7…`; feed pub `@/snvahva…` y feed HUB `@KM+ZBip…` iguales; parches 3/3 y `[Version: 1.1.2]` en los logs del pub; logs del HUB sin `EROFS`/`Another Oasis`/error |
| `pub:invite` funciona (canario del override) | ✅ `generate-invite.sh 1` devuelve invite `pub.escrivivir.co:8008:@/snvahva…~…` |
| Matriz §4 pública | ✅ `/` 200 · `/assets/fanzine.css` 200 · `/public/status` 200 (`"version":"1.1.2"`) · `/hub/` 200 · `/c` 200 · `/c/inhabitant/%40%2F…` 200 · `/clearnet` 302 · `POST /c` 405 · una `X-Frame-Options` y una CSP · `/settings`, `/profile`, `/publish`, `/update`, `/json/x`, `/qr/x` sin `X-Cache-Status` (0 ×6) |
| Nuevo en 1.1.2 | ✅ `/c/assets/images/snh-oasis.jpg` 200 image/jpeg y **HIT** · `/c/wiki/x`, `/c/market/x` 200 · `/c/qr/%40abc.ed25519` 200 image/png y **MISS** en dos peticiones (`no-store` respetado) · plantilla nginx renderizada con la `location` de `/c/assets/` |
| HUB sigue apuntando al pub por clave | ✅ `conn.json` del HUB: 1 entrada, con la clave del pub; el pub menciona al HUB en sus logs tras el arranque |
| Directorio | ✅ `pub.escrivivir.co → cycle=6 status=online [VERDE]` tras el recreate |
| Disco / journal | ✅ `/` 49 % → 59 % (imagen nueva + `:1.0.8` de rollback; `:0.9.6` puede retirarse) · `hub-disk check` OK (16 %) · journal `2026-09-17T11:47:21Z … 1.1.2 … server+hub` |

## Hallazgos del ciclo (recogidos en `HUB-PROTOCOL.md` §5.5)

1. El visor clearnet pasa de `/assets/images` a `/c/assets/images` (`mount("/c/assets", assets)` nuevo). Sin `location` propia en nginx los assets del HUB habrían sido MISS perpetuo (koa-static `max-age=0`).
2. Cuatro rutas de detalle nuevas (`bookmarks`, `feed`, `market`, `wiki`): 12 → 16 tipos. La guía upstream lista 15 (omite bookmarks); la ruta existe en `backend.js`.
3. `/c/qr/:feedId` nuevo: entra por `/c/*`, `Cache-Control: no-store` (nginx no lo cachea) y codifica `http://localhost:3000/…` (`QR_ACTION_BASE` constante). Inocuo; `/qr/*` sigue fuera.
4. Opt-in: tres claves nuevas en `visibilityPrefs`; desaparece `/profile/clearnet-toggle`.
5. Overlay en Windows: los ficheros nuevos salen CRLF (`autocrlf`); un reemplazo literal con `\n` no casa. Detectar EOL antes de editar (el protocolo lo recoge).
6. Guards: si upstream no tocó el fichero entre versiones, `git checkout HEAD -- <fichero>` es seguro (aquí `ssb_config.js`, `updater.js`); la regla «nunca checkout de los viejos» se matiza en el protocolo.

## Deploy (VPS) · secuencia preparada

Desde la máquina operadora, con `REMOTE_REPO_DIR=/opt/oasis-scriptorium/OASIS_PUB`:

1. `bash devops/scripts/backup-oasis-pub.sh` (obligatorio).
2. Rollback preparado: `docker tag oasis-pub-scriptorium:latest oasis-pub-scriptorium:1.0.8` · `tar -C /opt/oasis-scriptorium -czf /srv/oasis/src-1.0.8.tgz src`.
3. Disco: `docker image prune -f && docker builder prune -f`; `df -h /`.
4. Subir `src/` de la rama: `git archive upgrade/oasis-1.1.2 src | ssh … 'cd /opt/oasis-scriptorium && rm -rf src.new && mkdir src.new && tar -x -C src.new && mv src src.old && mv src.new/src src'`.
5. Subir in place (`cat >`) `OASIS_PUB/config/hub/nginx.conf.template` y `OASIS_PUB/caddy/Caddyfile` (solo comentario; opcional) y la Sala 04 (`deploy-site.sh` o copia a `/srv/site/hub/`).
6. `C="docker compose --env-file .env.prod -f docker-compose.pub.yml"` en `OASIS_PUB/`: `$C build oasis-pub` → `$C up -d --no-deps oasis-pub` → `deploy-status.sh` (healthy, feed igual, `pub:invite`) → `$C up -d --no-deps oasis-hub` → `$C up -d --no-deps --force-recreate hub-cache` (plantilla nginx nueva) → logs del HUB sin `EROFS`/`Another Oasis` → feed id del HUB igual → matriz §4 + `/c/assets/images/snh-oasis.jpg` MISS→HIT → `hub-disk.sh check`.
7. Journal: `deploy-log.sh --target pub --host pub.escrivivir.co --version 1.1.2 --caps-shs H5EC+V5BU9s0lWxCkt4z8a095Sj8a6TgiLKPYi1JD7s= --cycle 6 --feed @/snvahvaTP5obvdiYva9OX9NNnTSlUQbEUBSuDRzrZA=.ed25519 --mode server+hub`.
8. Rollback (< 2 min): `docker tag oasis-pub-scriptorium:1.0.8 oasis-pub-scriptorium:latest` + `$C up -d --no-deps --no-build oasis-pub oasis-hub`; `src` desde `src.old`/tgz; `hub-cache` con la plantilla anterior (`git show 588950c:pub/config/hub/nginx.conf.template`).

**Resultado del deploy (2026-09-17)**: secuencia 1–7 ejecutada tal cual; el clasificador de modo auto bloqueó el primer intento (comando compuesto) y se repitió por pasos. Sin rollback. Tiempos: build 97 s en el VPS, pub healthy a los 30 s, HUB a los 60 s. Rollback disponible: imagen `:1.0.8`, `src.old` y `/srv/oasis/src-1.0.8.tgz`. `oasis-pub-scriptorium:0.9.6` retirada el mismo día (`docker rmi`): solo liberó su capa superior porque el resto lo comparte con `:1.0.8`; `/` sigue al 59 % (9,8 G libres) y lo reclamable (2,97 GB) es ahora la imagen `:1.0.8` de rollback.
