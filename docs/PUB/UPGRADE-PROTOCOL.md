# Protocolo de upgrade de Oasis (fork dockerizado)

> **Este repo es el sitio del upgrade** (`C:\S_LAB\o-sdk`,
> `https://github.com/alephscriptorium-eng/O_SDK.git`). No uses
> `BlockchainComPort` ni `alephscript-network-sdk` (archivado).

Checklist operativo reutilizable para subir el fork dockerizado de Oasis a una nueva versión
upstream (KrakensLab/oasis) sin perder identidad SSB ni los "fork guards". Deriva del plan de
upgrade y de lo aprendido en los ciclos 0.8.3→0.8.8, 0.8.8→0.9.6, 0.9.6→1.0.8 y 1.0.8→1.1.2
(el primero con el HUB clearnet activo: `HUB-PROTOCOL.md` §5.5).

> **Modelo mental del "ciclo".** El *ciclo de red* NO lo calcula ningún código local
> (`blockchain-cycle.json` no lo lee nadie; `computeCycle()` de LARP es otra cosa). Es una
> generación de red del proyecto identificada por el **`caps.shs`**. El directorio
> `https://oasis-project.pub/api/pubs` mapea `caps.shs → ciclo` (hoy `H5EC+V5B…` = ciclo 6).
> Un pub aparece "verde" solo si el directorio consigue **handshake** con él en el cap actual, y
> para eso debe **descubrirlo** por gossip de su `type:pub` announce → hace falta que **alguien de la
> red le siga de vuelta**. Estar en rojo por `shs:null` suele ser **descubribilidad** (falta
> follow-back), NO cap/deploy.

## 0. Antes de nada — ¿qué hay desplegado?

```bash
bash devops/scripts/deploy-status.sh        # journal + pub vivo (SSH) + presencia en el directorio
```

No asumas el estado. Este comando lo dice: versión/cap/feed del pub vivo y verde/rojo(motivo).
Si `docker ps` en el VPS muestra `oasis-pub-hub`, el **HUB clearnet está activo**: la imagen es
compartida y el upgrade tiene pasos extra → `HUB-PROTOCOL.md` §5 antes de seguir.

> **Layout del VPS.** Mientras el host siga en el layout pre-refactor (`OASIS_PUB/`, sin `.git`),
> exporta `REMOTE_REPO_DIR=/opt/oasis-scriptorium/OASIS_PUB` antes de cualquier script de `devops/`
> (`host.env` apunta a `pub/`). Sin eso `pub-federation.sh status` falla con "Remote repo not found"
> y arrastra a `deploy-status`, `backup-oasis-pub` y `pub-maint-ui`.
> En Windows, `python3` puede ser el stub de la Microsoft Store: el chequeo del directorio sale vacío
> ("no aparece") aunque el pub esté verde; verifica con `python` o con node.

## 1. Preflight (check-warning)

```bash
UPSTREAM_BRANCH=main bash devops/scripts/upgrade-preflight.sh    # drift de versión + drift de ciclo + estado del árbol
```

- Compara `src/server/package.json` local vs `oasis-upstream/main`.
- Deriva el ciclo/cap actual de la red desde `oasis-project.pub/api/pubs` y lo compara con el local.
- Avisa si nuestro pub está rojo (y distingue descubribilidad de cap/deploy).
- Sale `0` = GO, `1` = hay WARN. (El aviso in-app de Oasis es un no-op en Docker: `.dockerignore`
  excluye `.git` y el updater está gateado por `existsSync('../../.git')` — por eso este script.)

## 2. Merge (overlay + re-aplicar guards)

Las historias fork↔upstream no comparten merge-base (upstream se importa como snapshot). Sobre una
rama `upgrade/oasis-X.Y.Z`:

```bash
git switch -c upgrade/oasis-X.Y.Z
git rm -r -q src && git checkout oasis-upstream/main -- src/     # overlay LIMPIO: borra lo que upstream borró
git checkout HEAD -- src/configs/blockchain-cycle.json           # único fichero fork-only bajo src/
git checkout oasis-upstream/main -- docs/PUB/deploy.md          # docs upstream (opcional). clearnet.md lleva
                                                                 # una nota del fork en cabecera: si lo traes, repónla
# Re-aplicar A MANO los guards sobre los ficheros NUEVOS (tabla de abajo). Nunca `git checkout HEAD --`
# de los ficheros viejos: desde 1.0.x settings_view.js y ssb_config.js cambian mucho en upstream
# (telegram, verificación, statePath) y recuperar la versión vieja rompe el árbol nuevo.
```

Por qué `git rm` antes del checkout: `git checkout <tree> -- src/` sobreescribe pero **no borra**, y así
quedaron restos de ciclos anteriores (`media-favorites.*`, retirados por upstream en 0.9.2) hasta 1.0.8.

**Desde 1.1.3 el `git rm` es crítico, no higiene**: upstream borró 7 JSON de estado de `src/configs` y
estrenó `src/configs/state-manager.js`, que al arrancar **migra** a `~/.ssb/oasis/**` cualquier fichero
de estado que encuentre en `src/configs/` o en `~/.ssb/`. Un resto viejo en `src/configs` acabaría
encima del estado real. Y el estado ya no vive donde vivía: ver `ECOIN-PROTOCOL.md` §5.4 antes de
arrancar ninguna pieza con cartera. Si el entorno define `OASIS_TEST`, el backend arranca sin sbot
embebido: comprobar que ningún compose la define.

Los guards, en concreto (ciclo 1.0.8; idénticos en 1.1.2 y en 1.1.4, más el quinto). Si upstream **no tocó** un fichero
entre las dos versiones (`git diff <tag-viejo> oasis-upstream/main --stat -- <fichero>` vacío), sí vale
`git checkout HEAD -- <fichero>` para ese guard (en 1.1.2: `ssb_config.js` y `updater.js`); los que
cambiaron (`backend.js`, `settings_view.js`) se editan a mano sobre el fichero nuevo. En Windows el
overlay sale **CRLF** en el árbol de trabajo (`autocrlf`): detecta el EOL antes de un reemplazo literal.

| Fichero | Qué reponer sobre el fichero nuevo |
|---|---|
| `backend.js` | En `.post("/update")`: conservar `isLoopbackRequest` y `safeRefererRedirect`; sustituir las dos `exec` (`git reset --hard && git pull`, `sh install.sh`) por el `console.warn` del fork. |
| `ssb_config.js` | Reponer `mergeDeep` y usarlo en vez del spread (`config = mergeDeep(config, configData)`); reponer el bloque `OASIS_SERVER_CONFIG_OVERRIDE` antes de `const megabyte`. Conservar `config.statePath` de upstream. |
| `updater.js` | Sustituir los dos `console.log("...new code updates are available!...")` por el mensaje del fork. Conservar el fix de ruta con `__dirname`. |
| `settings_view.js` | Sustituir el `form({ action: "/update" })` por el `p(...)` informativo. |
| `configs/snh-invite-code.json` | **Solo `url`** = dominio del pub de la instancia (D-O22): es la base de los enlaces de «compartir en clearnet» (`main_views.js`, `clearnetBase`). El invite de upstream se conserva. Efecto lateral: la caja de La Plaza en `/invites` muestra esa url. |

**Fork-guard surface** (lo único que debe divergir de upstream dentro de `src/`):

| Archivo | Guard |
|---|---|
| `src/backend/backend.js` | `/update` deshabilitado (auto-update destructivo en Docker) |
| `src/server/ssb_config.js` | `mergeDeep` + `OASIS_SERVER_CONFIG_OVERRIDE` + `blobs.max=50MB` |
| `src/backend/updater.js` | auto-update = solo aviso |
| `src/views/settings_view.js` | guard del botón de update |
| `src/configs/snh-invite-code.json` | `url` = dominio del pub (desde 1.1.4, D-O22) |
| `src/configs/blockchain-cycle.json` | fork-only (marcador de ciclo; preservar) |

Fuera de `src/` se mantiene **wholesale** (nunca overlay): `Dockerfile`, `docker-compose*.yml`,
`docker-entrypoint.sh`, `scripts/patch-node-modules.js`, `pub/**`, `devops/**`,
`caddy/**`. `install.sh`/`oasis.sh` son bare-metal → sync con upstream opcional.

**Invariantes del HUB (no son guards, pero se verifican).** El HUB clearnet no añade nada a
`src/`, pero depende de comportamientos upstream sin API estable (getter de `SSB_server`,
prefijo `OASIS_` de yargs, rutas `/c/*`, flag `oasis-first-contact`, cabeceras del backend).
Con el HUB activo, correr el bloque de greps de `HUB-PROTOCOL.md` §5.1 sobre el árbol nuevo y
regenerar `pub/config/hub/oasis-config.json` desde el `src/configs/oasis-config.json` nuevo (§5.2).

### Verificación de invariantes (crítica)

```bash
git diff oasis-upstream/main --stat -- src/       # SOLO los 5 guards + blockchain-cycle.json = 6 ficheros
node --check src/backend/backend.js               # el edit a mano parsea
grep -m1 '"version"' src/server/package.json      # = X.Y.Z
ls src/configs/blockchain-cycle.json              # preservado
```

## 3. Runtime guards (entrypoint) contra el árbol nuevo

- `apply_node_patches` (docker-entrypoint.sh) parchea 3 módulos SSB (ssb-ref, ssb-blobs, multiserver
  unix-socket). Si las deps `ssb-*` en `package.json` no cambiaron, aplican; **confirmar en logs de
  arranque** que no quedan no-op.
- Contrato AI: `ai_service.mjs` espera modelo `oasis-42-1-chat.Q4_K_M.gguf` en `:4001`. Revisar si
  upstream lo cambió.
- Cliente con ECOin (WP-O103): `persist_client_state`, `wire_wallet_config` y `setup_oasis_config` (ahora en node, sin `sed`) viven en `docker-entrypoint.sh` (zona *wholesale*) y solo actúan con `OASIS_CLIENT_STATE_DIR` definido y modo distinto de `server`; **`src/` sigue con exactamente 4 guards** — tras el overlay, confirmar que `src/configs/oasis-config.json` conserva `wallet.{url,user,pass,fee}` y `walletPub.pubId` (`CLIENT-PROTOCOL.md` §8).

## 4. Deploy por rol (misma imagen, tres modos)

Una sola imagen `oasis-pub-scriptorium:latest`, tres `command` del entrypoint: `server` (pub: solo
sbot) · `backend` (HUB clearnet: `backend.js --public` con sbot embebido e identidad propia,
`HUB-PROTOCOL.md`) · `full` (cliente: sbot + GUI + IA).

**Preservar siempre** (bind mounts): el dir `.ssb` (`secret`=identidad, `flume`, `blobs`, `gossip.json`)
y `ai-models`. Con el HUB activo, también `/srv/oasis/oasis-hub/ssb-data` (su `secret` y `conn.json`).

- **Cliente** (`docker-compose.yml`, modo `full`): `docker tag o-sdk-oasis-client o-sdk-oasis-client:<ver-vieja>`
  (rollback) → `npm run build && docker compose up -d oasis-client`. Binds `volumes-dev/{ssb-data,ai-models}`
  intactos. Detalle, importación de identidad y sbot puro: `../CLIENT-PROTOCOL.md` §4.
- **Pub** (VPS `/opt/oasis-scriptorium`): **no es un checkout git**. `deploy.sh` solo hace
  `compose up --build` sobre lo que ya hay en disco. Orden: backup → liberar disco → etiquetar imagen
  de rollback → actualizar **`src/`** (tar/rsync; no el repo o-sdk entero) → `build` → `up --no-deps`
  **solo** `oasis-pub`.
  - **Disco**: la raíz del VPS es pequeña y cada rebuild deja una imagen `<none>` de ~3 GB. Antes del
    build: `docker image prune -f && docker builder prune -f` (en 09/2026 había 9,5 GB reclamables).
    Comprueba `df -h /` y `docker system df`.
  - **Rollback preparado**: `docker tag oasis-pub-scriptorium:latest oasis-pub-scriptorium:<ver-vieja>`
    y `tar -C /opt/oasis-scriptorium -czf /srv/oasis/src-<ver-vieja>.tgz src` antes de tocar nada.
  - **Subir `src/`** desde la rama (solo trackeados, sin node_modules, EOL limpios):
    `git archive upgrade/oasis-X.Y.Z src | ssh scriptorium-vps 'cd /opt/oasis-scriptorium && rm -rf src.new && mkdir src.new && tar -x -C src.new && mv src src.old && mv src.new/src src'`
  - **Build antes, recreate después** (el pub sigue sirviendo durante el build):
    `docker compose --env-file .env.prod -f docker-compose.pub.yml build oasis-pub` y luego
    `... up -d --no-deps oasis-pub`. No uses el `deploy.sh` del VPS: es una copia vieja, hace
    `up --build` de todos los servicios y no escribe el journal.
  - El layout del host sigue siendo `OASIS_PUB/` (pre-refactor). No rsync de `pub/` encima.
  - **Backup previo obligatorio**: `bash devops/scripts/backup-oasis-pub.sh`.
  - ⚠️ **Caddy compartido**: `oasis-pub-web` frontea también los hosts de ScriptoriumVps. Para un
    upgrade de solo Oasis, reconstruir **solo el servicio de la app**
    (`docker compose -f docker-compose.pub.yml up -d --build --no-deps oasis-pub`) para no recrear `pub-web`.
    Si tocas el `Caddyfile`: `caddy validate` + `caddy reload --config /dev/stdin`, **nunca**
    `restart pub-web` a ciegas.
  - **Landing**: no tocar. `pub/site/index.html` lee versión/ciclo/cap en vivo
    (`/public/status`, `/public/network`).
  - **HUB activo**: el retag de la imagen **no** recrea `oasis-pub-hub`. Tras el healthcheck del pub,
    `... up -d --no-deps oasis-hub` (pub primero, HUB después; `hub-cache` no cambia). Mientras
    tanto `/c` sirve `STALE` desde nginx. Secuencia y comprobaciones: `HUB-PROTOCOL.md` §5.3.
- El `deploy.sh` del pub (versión del repo) **apenda al journal** (A0b) al terminar (`devops/scripts/deploy-log.sh`).
  Si desplegaste a mano (build + up), apúntalo desde la máquina operadora:
  `bash devops/scripts/deploy-log.sh --target pub --host pub.escrivivir.co --version X.Y.Z --caps-shs <shs> --cycle 6 --feed <feed> --mode server`
  (`--mode server+hub` si el HUB está activo).

## 5. Ciclo de red — dos casos

- **Mantener** (bump de versión normal): no tocar `caps.shs`/seed. Feeds/invites/identidad intactos.
- **Rotar** (solo si el proyecto rota a un cap nuevo): editar en lockstep `caps.shs` + `autofollow.feeds`
  en `pub/config/ssb/config(.local)`, `src/configs/server-config.json`, `docs/PUB/*.example` +
  `deploy.md`, `devops/scripts/pub-federation.sh` (`EXPECTED_SHS`/`SNH_FEED`),
  `pub/site/index.html` y, con el HUB activo, `pub/config/hub/ssb-config` (`caps.shs`; HUB y pub
  rotan juntos, el follow entre ambos sobrevive); luego `pub-federation.sh announce` + `follow-solarnethub` + re-emitir
  invites. Cambiar `caps.shs` = red SSB distinta (los del cap viejo dejan de hacer handshake).

## 6. Healthcheck post-upgrade + rollback

- **Cliente**: `docker ps` healthy; `/settings` muestra la versión nueva; AI `:4001` responde
  (`npm run client:test-ai`); enviar+descargar un fileShare por `/pm/file`; `whoami` = mismo feed id;
  `POST /settings/verify` sin forks propios. Matriz completa: `../CLIENT-PROTOCOL.md` §5.
- **Pub**: `bash devops/scripts/deploy-status.sh` → contenedor healthy, `caps.shs` OK, feed id sin cambios;
  `pub:invite` funciona (canario del override `OASIS_SERVER_CONFIG_OVERRIDE`).
- **HUB** (si activo): `oasis-pub-hub` healthy con la imagen nueva, feed id del HUB sin cambios, `/c`
  200 y `X-Cache-Status` MISS→HIT, sin `EROFS` en sus logs, `hub-disk.sh check` → 0
  (`HUB-PROTOCOL.md` §4 y §5.3). Desde 1.1.2: `/c/assets/images/snh-oasis.jpg` 200 y MISS→HIT;
  una ruta de detalle nueva (p. ej. `/c/wiki/x`) responde 200 con «not accessible»/not found, no 404 de nginx.
- **Discoverability** (aparte): para pasar a verde en el directorio hace falta **follow-back** de un
  pub raíz (redimir invite de La Plaza / pedir follow). Progreso: `followersBack` sube de 0.
- **Rollback** (pub, < 2 min): `docker tag oasis-pub-scriptorium:<ver-vieja> oasis-pub-scriptorium:latest`
  + `docker compose --env-file .env.prod -f docker-compose.pub.yml up -d --no-deps --no-build oasis-pub`
  (añade `oasis-hub` al `up` si el HUB está activo);
  restaurar `src/` desde `src.old` o el tgz. `.ssb` intacto ⇒ sin pérdida de identidad. Backup de
  `ssb-data` disponible. Cliente: retag de la imagen anterior + `up -d --no-build` (`../CLIENT-PROTOCOL.md` §6);
  el `git switch` solo sirve para reconstruir, no para volver atrás.

## 7. Cierre — registrar

`deploy-status.sh` debe mostrar la versión nueva y el pub healthy en su cap. El journal
(`devops/logs/deploy-history.jsonl`) tiene la línea del deploy. Si se rotó ciclo o se
consiguió follow-back, re-`announce` y verificar la fila de `pub.escrivivir.co` en el directorio.

## 8. HUB clearnet — ver `HUB-PROTOCOL.md`

Desde 1.0.x el pub puede servir un **HUB web de solo lectura** en `/c` con el contenido público de los
habitantes que hayan activado *Clearnet* en su perfil (`docs/PUB/clearnet.md`). **En Docker no basta con
Caddy**: nuestro modo `server` arranca solo `SSB_server.js`, mientras que `oasis.sh server` de upstream
arranca sbot + `backend.js --public`. Cómo lo resolvemos, cómo se activa, cómo se mantiene en disco y
qué cambia en cada upgrade está en **`HUB-PROTOCOL.md`** (estado en su cabecera).

Historia, para no repetirla: la receta que vivió aquí (ciclo 1.0.8) proxyaba **al backend del pub** con un
modo `server-hub` del entrypoint (sbot + backend en el mismo contenedor, rebuild de imagen) y enrutaba
`/qr/*`. Se **retiró** el 2026-09-13 (D-O13) por la v2: el HUB es un **nodo de soporte** con identidad
propia en su propio contenedor (`command: ["backend"]`, misma imagen, sin rebuild), el sbot del pub no
se toca y `/qr/*` queda fuera porque la vista clearnet no lo usa y codifica `localhost:3000`. Siguen
valiendo, y están recogidos allí, los hechos del proxy: `/assets/*` entero colisiona con la landing,
`--allow-host` es obligatorio para `/clearnet`, las URLs de nuestro feed llevan `%40%2F` sin decodificar
y `/c/blob/*` es inmutable.
