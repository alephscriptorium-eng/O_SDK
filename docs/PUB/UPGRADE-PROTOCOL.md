# Protocolo de upgrade de Oasis (fork dockerizado)

Checklist operativo reutilizable para subir el fork dockerizado de Oasis a una nueva versión
upstream (KrakensLab/oasis) sin perder identidad SSB ni los "fork guards". Deriva del plan de
upgrade y de lo aprendido en el ciclo 0.8.3→0.8.8.

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

## 1. Preflight (check-warning)

```bash
bash devops/scripts/upgrade-preflight.sh    # drift de versión + drift de ciclo + estado del árbol
```

- Compara `src/server/package.json` local vs `oasis-upstream/master`.
- Deriva el ciclo/cap actual de la red desde `oasis-project.pub/api/pubs` y lo compara con el local.
- Avisa si nuestro pub está rojo (y distingue descubribilidad de cap/deploy).
- Sale `0` = GO, `1` = hay WARN. (El aviso in-app de Oasis es un no-op en Docker: `.dockerignore`
  excluye `.git` y el updater está gateado por `existsSync('../../.git')` — por eso este script.)

## 2. Merge (overlay + re-aplicar guards)

Las historias fork↔upstream no comparten merge-base (upstream se importa como snapshot). Sobre una
rama `upgrade/oasis-X.Y.Z`:

```bash
git switch -c upgrade/oasis-X.Y.Z
git checkout oasis-upstream/master -- src/                                   # overlay app sources
git checkout HEAD -- src/server/ssb_config.js src/backend/updater.js src/views/settings_view.js
# Re-aplicar A MANO el guard de /update en el nuevo src/backend/backend.js:
#   conservar isLoopbackRequest de upstream; sustituir el bloque
#   "git reset --hard && git pull" + "sh install.sh" por el console.warn del fork.
```

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
git diff oasis-upstream/master --stat -- src/     # SOLO los 4 guards + blockchain-cycle.json
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
- **Pub** (VPS): `bash pub/scripts/env-run.sh .env.prod deploy.sh`.
  - **Backup previo obligatorio**: `bash devops/scripts/backup-oasis-pub.sh`.
  - ⚠️ **Caddy compartido**: `oasis-pub-web` frontea también los hosts de ScriptoriumVps. Para un
    upgrade de solo Oasis, reconstruir **solo el servicio de la app**
    (`docker compose -f docker-compose.pub.yml up -d --build oasis-pub`) para no recrear `pub-web`.
    Si tocas el `Caddyfile`: `caddy validate` + `caddy reload --config /dev/stdin`, **nunca**
    `restart pub-web` a ciegas.
- El `deploy.sh` del pub **apenda al journal** (A0b) al terminar (`devops/scripts/deploy-log.sh`).

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
- **Rollback**: `git switch` a la rama previa + rebuild; `.ssb` intacto ⇒ sin pérdida de identidad.
  Backup de `ssb-data` disponible.

## 7. Cierre — registrar

`deploy-status.sh` debe mostrar la versión nueva y el pub healthy en su cap. El journal
(`devops/logs/deploy-history.jsonl`) tiene la línea del deploy. Si se rotó ciclo o se
consiguió follow-back, re-`announce` y verificar la fila de `pub.escrivivir.co` en el directorio.
