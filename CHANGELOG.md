# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es/1.0.0/).
Web &amp; docs: <https://o-sdk.escrivivir.co> · Código: <https://github.com/alephscriptorium-eng/O_SDK>

## [Unreleased]

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
