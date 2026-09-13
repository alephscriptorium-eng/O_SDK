# oasis-clearweb · HUB clearnet de `pub.escrivivir.co`

Carpeta de planificación del HUB web de solo lectura (`/c`) de Oasis 1.0.8 para el pub del
Scriptorium. Aquí vive el **plan** y su **evidencia**; lo que se mantiene en el tiempo es la doc
viva del repo.

| Qué | Dónde | Estado |
|---|---|---|
| **Doc viva** (leer primero): activar · verificar · disco · memoria · upgrades · rollback | `docs/PUB/HUB-PROTOCOL.md` | cabecera del doc |
| Plan v2 (diseño elegido, secuencia de deploy, gates, riesgos) | `./v2.md` | integrado en el repo 2026-09-13; ejecución ⏳ WP-O46 |
| Evidencia (hallazgos con `ruta:línea`, VPS, revisión adversarial F1-F20, fragmentos, gates) | `./dosier/` | cerrado 2026-09-13 |
| Plan v1 (descartado: backend dentro del contenedor del pub) | `./v1.md` | historia; comparativa en `dosier/08` |
| Decisión | `plan/DECISIONES.md` D-O13 | asentada |
| Backlog | `plan/BACKLOG.md` WP-O46 (P1) · WP-O47 (P2, tope duro de disco + `mem_limit` del pub) | ⏳ |
| Upgrades futuros con el HUB activo | `docs/PUB/UPGRADE-PROTOCOL.md` §0/§2/§4/§5/§6 + `HUB-PROTOCOL.md` §5 | integrado |
| Mantenimiento de disco | `HUB-PROTOCOL.md` §6 · `devops/README.md` §9 · `devops/scripts/hub-disk.sh` (⏳ WP-O46) | contrato escrito |

## Evolución en una línea

Receta v0 (`UPGRADE-PROTOCOL.md` §8, ciclo 1.0.8: proxy al backend del pub, entrypoint `server-hub`)
→ **v1** (2026-09-13: supervisor sbot+backend en el contenedor del pub, rebuild ~3 GB) → objeciones
del custodio (el sbot del pub no se toca · el HUB es otra cuenta · estado en el volumen de datos)
→ **v2** (nodo de soporte con identidad propia, misma imagen sin rebuild, caché nginx en disco,
`hub-disk.sh`) → integración en docs/gobierno → ⏳ ejecución.

## Para el siguiente agente

1. Lee `docs/PUB/HUB-PROTOCOL.md` entero. Su cabecera dice si el HUB está desplegado.
2. Si vas a **ejecutar** WP-O46: `v2.md` (secuencia y gates) + `dosier/06` (fragmentos) +
   `dosier/07` (gates) + las «Correcciones tras verificación» de `v2.md`.
3. Si vas a **hacer un upgrade** de Oasis con el HUB activo: `UPGRADE-PROTOCOL.md` y
   `HUB-PROTOCOL.md` §5 (greps de preflight, ficheros derivados, orden pub → HUB).
4. Si el disco avisa: `HUB-PROTOCOL.md` §6 (qué crece, qué se poda, árbol de decisión, qué nunca borrar).
5. Si algo diverge del plan al ejecutar: corrige el **protocolo** y anótalo en el reporte del WP;
   el plan no se reescribe.
