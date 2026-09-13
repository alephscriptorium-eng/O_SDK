# Dosier · HUB clearnet como nodo de soporte (plan v2)

Carpeta de apoyo de `../v2.md`. Recoge, con `ruta:línea`, todo lo verificado en la sesión de
replanificación del 2026-09-13 (tres exploraciones paralelas del repo + una revisión adversarial
del diseño). Sirve para que el worker del WP-O46 y su revisor no tengan que rehacer la
investigación, y para que el asiento D-O13 cite hechos y no recuerdos.

Convención: **[V]** verificado en el repo (con `ruta:línea`) · **[NV]** no verificable aquí (falta
`src/server/node_modules`, depende del VPS o de doc externa) · **[VPS]** dato tomado de evidencia
operativa versionada (`pub/BACKLOG.md`, backups, journal), no medido en esta sesión.

| Doc | Contenido |
|---|---|
| `01-hallazgos-codigo.md` | Oasis 1.0.8 en `src/`: sbot embebido en `backend.js`, opciones por env, `--public`, middleware, rutas del HUB, qué habitantes ve `/c`, merge de config, almacenamiento, escrituras automáticas, cachés |
| `02-vps-y-volumenes.md` | Inventario del VPS: dos volúmenes, layout vivo, dónde está Docker, presión de disco, `.env*`, divergencia repo↔VPS, backups, lo que NO está documentado |
| `03-deploy-actual.md` | Compose, entrypoint (modos), Caddyfile (6 vhosts), scripts `pub/` y `devops/`, precedente `blobstore-sidecar`, precedentes de invite |
| `04-gobierno.md` | BACKLOG (lanes, WPs afectados, conteo), DECISIONES D-O1..D-O12, campos del BRIEF, revisión adversarial, vocabulario («fan» no existe) |
| `05-revision-adversarial.md` | Los 20 hallazgos (F1-F20) de la crítica al diseño v2 y la corrección aplicada a cada uno |
| `06-fragmentos.md` | Fragmentos finales listos para el worker: compose, `ssb-config`, `oasis-config.json`, `nginx.conf.template`, Caddy, bootstrap, `hub-disk.sh`, cambios en `common.sh` y `.env*` |
| `07-gates-y-verificacion.md` | Gates locales G1-G7, método de medición de memoria, matriz e2e, comprobaciones en el VPS, rollback |
| `08-v1-vs-v2.md` | Qué se descarta de la v1 y por qué; el análisis del sidecar de la v1 que sigue siendo válido |

## Cómo leerlo

- Si vas a **ejecutar** el WP: `06` + `07`, con `05` al lado.
- Si vas a **revisar** el WP: `05` (contraevidencia) + `07` (gates) + `01` (para comprobar cada `ruta:línea`).
- Si vas a **asentar** D-O13: `08` + §b de `../v2.md`.
- Si vas a **operar** el VPS después: `02` + `06` §7 (`hub-disk.sh`).

## Decisiones del custodio recogidas

| Fecha | Decisión |
|---|---|
| 2026-09-13 (v1) | Sala 04 · HUB en `/hub/`; paridad de los 12 tipos |
| 2026-09-13 (v2) | El sbot del pub no se toca · el HUB es otra cuenta SSB (nodo de soporte) en contenedor propio · estado y caché en el volumen de datos con utilidad de control |
| 2026-09-13 (v2) | Caché HTTP en disco (nginx, `max_size`) desde el día 1 |
| 2026-09-13 (v2) | Replicación del nodo de soporte a hops 2 |
