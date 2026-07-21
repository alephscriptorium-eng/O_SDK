# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es/1.0.0/).
Web &amp; docs: <https://o-sdk.escrivivir.co> · Código: <https://github.com/alephscriptorium-eng/O_SDK>

## [Unreleased]

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
