# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es/1.0.0/).
Web &amp; docs: <https://o-sdk.escrivivir.co> · Código: <https://github.com/alephscriptorium-eng/O_SDK>

## [Unreleased]

### Added — HUB clearnet como nodo de soporte, implementación (WP-O46, 2026-09-13)

- Rama `wp/O46-hub-nodo-soporte`. `pub/docker-compose.pub.yml`: servicios
  `oasis-hub` (misma imagen, `command: ["backend"]`, identidad propia, sin
  puertos) y `hub-cache` (nginx, caché en disco acotada); `oasis-pub` intacto.
  `pub/config/hub/{ssb-config,oasis-config.json,nginx.conf.template}`;
  bloque `@hub` en `pub/caddy/Caddyfile`; variables `OASIS_HUB_*` en
  `pub/.env*.example` y `pub/scripts/common.sh`; `pub/tools/hub-conn-fix.js`
  (normaliza `conn.json` tras el invite: ssb-invite deja la dirección con
  seed y sin `key`); `devops/scripts/hub-disk.sh` (`status`/`check`/
  `prune-blobs`/`prune-cache`/`--json`, npm `devops:hub-disk`) y línea de
  `check` en `deploy-status.sh`; layout `/srv/oasis/oasis-hub/*` en
  `verify-debian13-base.sh`; Sala 04 `pub/site/hub/` + puerta en el
  vestíbulo y en Accesos. Gates locales G1-G7 pasados (hallazgos en
  `ARCHIVO/DISCO/oasis-clearweb/v2.md`).
- **Desplegado en `pub.escrivivir.co` el 2026-09-13 (19:55 UTC)**: `/c` servido por
  la cuenta de soporte `azofaifo-scriptorium-skin-bot-1`
  (`@KM+ZBipR18VSyjNTFjAOnsmz6EiobGYHb3ZCZ4ZxQYI=.ed25519`), Sala 04 en `/hub/`,
  el pub sin reiniciar. Tres paradas durante el deploy, corregidas en la
  rama: ruta de `ssb-admin.js` en la imagen viva, `seeds` retirado del
  `ssb-config` (bloqueaba el invite con `alreadyFederated`) y filtro de
  `hub-conn-fix.js` por host. Reporte: `plan/REPORTES/WP-O46-hub-nodo-soporte.md`.

### Docs — HUB clearnet como nodo de soporte (2026-09-13)

- Nuevo `docs/PUB/HUB-PROTOCOL.md`: activar, operar, mantener en disco y llevar
  a través de los upgrades el HUB web `/c`. Diseño v2: **segundo nodo SSB con
  identidad propia** (`oasis-hub`, misma imagen, `command: ["backend"]`, sbot
  embebido, hops 2), caché nginx en disco (`hub-cache`, `max_size`) y todo el
  estado en el volumen de datos (`/srv/oasis/oasis-hub/*`). El pub no cambia.
  Estado: **planificado, no desplegado** (WP-O46; plan y dosier en
  `ARCHIVO/DISCO/oasis-clearweb/`).
- `UPGRADE-PROTOCOL.md`: §4 pasa a «tres modos» (`server`/`backend`/`full`);
  pasos del HUB en §0, §2 (invariantes upstream que verifica), §4, §5, §6;
  §8 retira la receta v0 (entrypoint `server-hub`, proxy al backend del pub,
  `/qr/*`) y apunta al protocolo del HUB.
- `clearnet.md` (upstream) lleva nota del fork; `devops/README.md` §9 (disco
  del HUB, `hub-disk.sh`); `pub/README.md` (servicios planificados); portal
  VitePress (nav/sidebar); `plan/DECISIONES.md` D-O13 y D-O14 (serie de
  bots de soporte `<nombre>-<tipo>-bot-<cardinal>`; el HUB es
  `azofaifo-scriptorium-skin-bot-1`); `plan/BACKLOG.md` WP-O46 y WP-O47
  (tope duro de disco + `mem_limit` del pub).

### Changed — refactor de estructura (2026-07-25)

- **Una carpeta por responsabilidad**: `OASIS_PUB/`→`pub/`,
  `GANDI_DEVOPS_FOLDER/`→`devops/`, `OASIS_CLIENT_dEV/`+`docker-scripts/`→
  `client/`, `ECOIN_DOCKERIZE/`→`ecoin/`; histórico y transcripts →
  `archive/`. Migración del VPS: `devops/MIGRATION-2026-07.md`.
- **Generalización cliente+pub**: datos de instancia fuera de los scripts —
  `devops/hosts/<instancia>/host.env` (IP, clave, cap, dominio; instancia por
  defecto `scriptorium`) y `client/identity/identity.env` (identidad GPG del
  usuario). Los scripts de `devops/` cargan la instancia vía `lib-host.sh`.
- Servicio del compose raíz renombrado `oasis-dev`→`oasis-client`; el wallet
  ECOin pasa a profile opcional (`npm run ecoin:up`). Scripts npm
  reorganizados en espacios `client:` / `pub:` / `devops:`.
- CI de docs: el gate materializa las skills (`npm run skills:sync`) en vez de
  depender de un espejo commiteado.

### Security

- `.dockerignore` reescrito: `devops/` (claves SSH), `client/` (GPG),
  `archive/` y demás superficies ya **no entran en la imagen Docker** (antes
  la clave privada del VPS se horneaba en `oasis-pub-scriptorium:latest`).
  Requiere rebuild + rotación de la clave SSH si la imagen se compartió.
- Retirado un `ROOMS_SECRET` en claro de `pub/site/scriptorium/index.html`
  (página servida públicamente): rotar el secret en el servidor de rooms.
- `pub/.env.example` regenerado (estaba corrupto por el incidente NVMe — 1153
  bytes NUL) — el flujo genérico de `deploy.sh` vuelve a funcionar.

### Added

- Portal de documentación FOSS (VitePress) publicado en
  <https://o-sdk.escrivivir.co> vía GitHub Pages (skill `site-web`): portada,
  Proyecto/DevOps y los protocolos de operación.
- `docs/PUB/RECOVERY-PROTOCOL.md` — protocolo de recuperación (repo, imagen e
  identidad SSB), gemelo del de upgrade.
- Tooling de skills de agente: `@alephscript/skills-scriptorium` +
  `.claude/skills/` (espejo materializado con `npm run skills:sync`).
- Enlaces FOSS de fuente única (repo, registry, CI, issues) en el pie del portal.

### Changed

- Migración del fork a **Oasis 0.8.8** (cliente + pub dockerizados).
- Repositorio movido a `alephscriptorium-eng/O_SDK` (rama por defecto `main`);
  referencias a `escrivivir-co` retiradas de README y portal.

### Fixed

- Recuperación tras corrupción de disco: contenido restaurado por procedencia
  (commits locales legibles + rama del equipo), purgado de daño NUL; working
  tree, imagen Docker e identidad SSB (feed continuo) restaurados y verificados.
