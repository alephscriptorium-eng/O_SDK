# Protocolo de upgrade de Oasis (fork dockerizado)

> **Este repo es el sitio del upgrade** (`C:\S_LAB\o-sdk`,
> `https://github.com/alephscriptorium-eng/O_SDK.git`). No uses
> `BlockchainComPort` ni `alephscript-network-sdk` (archivado).

Checklist operativo reutilizable para subir el fork dockerizado de Oasis a una nueva versión
upstream (KrakensLab/oasis) sin perder identidad SSB ni los "fork guards". Deriva del plan de
upgrade y de lo aprendido en los ciclos 0.8.3→0.8.8, 0.8.8→0.9.6 y 0.9.6→1.0.8.

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
git checkout oasis-upstream/main -- docs/PUB/clearnet.md docs/PUB/deploy.md   # docs upstream (opcional)
# Re-aplicar A MANO los 4 guards sobre los ficheros NUEVOS (tabla de abajo). Nunca `git checkout HEAD --`
# de los ficheros viejos: desde 1.0.x settings_view.js y ssb_config.js cambian mucho en upstream
# (telegram, verificación, statePath) y recuperar la versión vieja rompe el árbol nuevo.
```

Por qué `git rm` antes del checkout: `git checkout <tree> -- src/` sobreescribe pero **no borra**, y así
quedaron restos de ciclos anteriores (`media-favorites.*`, retirados por upstream en 0.9.2) hasta 1.0.8.

Los cuatro guards, en concreto (ciclo 1.0.8):

| Fichero | Qué reponer sobre el fichero nuevo |
|---|---|
| `backend.js` | En `.post("/update")`: conservar `isLoopbackRequest` y `safeRefererRedirect`; sustituir las dos `exec` (`git reset --hard && git pull`, `sh install.sh`) por el `console.warn` del fork. |
| `ssb_config.js` | Reponer `mergeDeep` y usarlo en vez del spread (`config = mergeDeep(config, configData)`); reponer el bloque `OASIS_SERVER_CONFIG_OVERRIDE` antes de `const megabyte`. Conservar `config.statePath` de upstream. |
| `updater.js` | Sustituir los dos `console.log("...new code updates are available!...")` por el mensaje del fork. Conservar el fix de ruta con `__dirname`. |
| `settings_view.js` | Sustituir el `form({ action: "/update" })` por el `p(...)` informativo. |

**Fork-guard surface** (lo único que debe divergir de upstream dentro de `src/`):

| Archivo | Guard |
|---|---|
| `src/backend/backend.js` | `/update` deshabilitado (auto-update destructivo en Docker) |
| `src/server/ssb_config.js` | `mergeDeep` + `OASIS_SERVER_CONFIG_OVERRIDE` + `blobs.max=50MB` |
| `src/backend/updater.js` | auto-update = solo aviso |
| `src/views/settings_view.js` | guard del botón de update |
| `src/configs/blockchain-cycle.json` | fork-only (marcador de ciclo; preservar) |

Fuera de `src/` se mantiene **wholesale** (nunca overlay): `Dockerfile`, `docker-compose*.yml`,
`docker-entrypoint.sh`, `scripts/patch-node-modules.js`, `pub/**`, `devops/**`,
`caddy/**`. `install.sh`/`oasis.sh` son bare-metal → sync con upstream opcional.

### Verificación de invariantes (crítica)

```bash
git diff oasis-upstream/main --stat -- src/       # SOLO los 4 guards + blockchain-cycle.json
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

## 4. Deploy por rol (misma imagen, dos modos)

**Preservar siempre** (bind mounts): el dir `.ssb` (`secret`=identidad, `flume`, `blobs`, `gossip.json`)
y `ai-models`.

- **Cliente** (`docker-compose.yml`, modo `full`): `docker compose build && docker compose up -d`.
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
- El `deploy.sh` del pub (versión del repo) **apenda al journal** (A0b) al terminar (`devops/scripts/deploy-log.sh`).
  Si desplegaste a mano (build + up), apúntalo desde la máquina operadora:
  `bash devops/scripts/deploy-log.sh --target pub --host pub.escrivivir.co --version X.Y.Z --caps-shs <shs> --cycle 6 --feed <feed> --mode server`.

## 5. Ciclo de red — dos casos

- **Mantener** (bump de versión normal): no tocar `caps.shs`/seed. Feeds/invites/identidad intactos.
- **Rotar** (solo si el proyecto rota a un cap nuevo): editar en lockstep `caps.shs` + `autofollow.feeds`
  en `pub/config/ssb/config(.local)`, `src/configs/server-config.json`, `docs/PUB/*.example` +
  `deploy.md`, `devops/scripts/pub-federation.sh` (`EXPECTED_SHS`/`SNH_FEED`),
  `pub/site/index.html`; luego `pub-federation.sh announce` + `follow-solarnethub` + re-emitir
  invites. Cambiar `caps.shs` = red SSB distinta (los del cap viejo dejan de hacer handshake).

## 6. Healthcheck post-upgrade + rollback

- **Cliente**: `docker ps` healthy; `/settings` muestra la versión nueva; AI `:4001` responde;
  enviar+descargar un fileShare por `/pm/file`; `whoami` = mismo feed id.
- **Pub**: `bash devops/scripts/deploy-status.sh` → contenedor healthy, `caps.shs` OK, feed id sin cambios;
  `pub:invite` funciona (canario del override `OASIS_SERVER_CONFIG_OVERRIDE`).
- **Discoverability** (aparte): para pasar a verde en el directorio hace falta **follow-back** de un
  pub raíz (redimir invite de La Plaza / pedir follow). Progreso: `followersBack` sube de 0.
- **Rollback** (pub, < 2 min): `docker tag oasis-pub-scriptorium:<ver-vieja> oasis-pub-scriptorium:latest`
  + `docker compose --env-file .env.prod -f docker-compose.pub.yml up -d --no-deps --no-build oasis-pub`;
  restaurar `src/` desde `src.old` o el tgz. `.ssb` intacto ⇒ sin pérdida de identidad. Backup de
  `ssb-data` disponible. Cliente: `git switch` a la rama previa + rebuild.

## 7. Cierre — registrar

`deploy-status.sh` debe mostrar la versión nueva y el pub healthy en su cap. El journal
(`devops/logs/deploy-history.jsonl`) tiene la línea del deploy. Si se rotó ciclo o se
consiguió follow-back, re-`announce` y verificar la fila de `pub.escrivivir.co` en el directorio.

## 8. HUB clearnet (opcional, desde 1.0.x) — no activado por defecto

Desde 1.0.x el pub puede servir un **HUB web de solo lectura** en `/c` con el contenido público de los
habitantes que hayan activado *Clearnet* en su perfil (`docs/PUB/clearnet.md`). **En Docker no basta con
Caddy**: nuestro modo `server` arranca solo `SSB_server.js`, mientras que `oasis.sh server` de upstream
arranca sbot + `backend.js --public --no-open --host=0.0.0.0`. Activarlo son tres cambios, independientes
del upgrade de `src/`:

1. `docker-entrypoint.sh`, modo `server`: forzar `aiMod`/`aiNavMod` a `off`, arrancar `SSB_server.js start`
   en background, esperar el socket y `exec node backend.js --public --no-open --host=0.0.0.0
   --allow-host="$OASIS_PUB_WEB_HOST"`. El puerto 3000 no se publica al host (solo red Docker).
2. `docker-compose.pub.yml`: pasar `OASIS_PUB_WEB_HOST` al servicio `oasis-pub`.
3. `Caddyfile`, vhost del pub, **antes** del `handle` de la landing:

   ```caddyfile
   @hub path /c /c/* /clearnet /qr/* /assets/styles/* /assets/themes/* /assets/images/*
   handle @hub {
     @blob path /c/blob/*
     header @blob Cache-Control "public, max-age=31536000, immutable"
     reverse_proxy oasis-pub:3000
   }
   ```

Por qué así (verificado en 1.0.8; coincide con la doc web de Oasis para "HUB que comparte dominio", que
trae Apache/nginx con `/c`, `/assets`, `/qr` y `--allow-host`, más completa que el `clearnet.md` del tarball):

- `/assets` **colisiona** con la landing (`pub/site/assets/fanzine.css`): proxyear subrutas, no `/assets/*`.
- `--allow-host` es obligatorio: `/c*` salta la validación de Host de `middleware.js`, pero `/clearnet`
  (redirect a `/c`) y `/qr/:feedId` (QR del habitante) no → 400 sin él. `/assets` se sirve antes de la validación.
- **Barras codificadas**: nuestro feed empieza por `@/…`, así que las URLs son `/c/inhabitant/%40%2F…`
  (el caso `AllowEncodedSlashes NoDecode` / `nocanon` de Apache). Caddy pasa el URI crudo, pero es el
  primer `curl` a hacer tras activar.
- `/c/blob/*` es content-addressed → cache inmutable. `/qr` ya manda `no-store`.
- El modo `--public` bloquea todo POST y redacta a quien no haya optado; Caddy además solo enruta `/c*`.
