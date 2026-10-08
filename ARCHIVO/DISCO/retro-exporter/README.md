# retro-exporter · del organigrama de Acampada26S a la infraestructura de su pub

Carpeta de **plan + evidencia** (WP-O129, rama `dev/retro-exporter`) de la pregunta «¿se puede
parsear el modelo organizativo de un colectivo a infraestructura Oasis y entregárselo como kit?».
Acampada26S corre un pub Oasis 1.2.3 upstream (`https://acampada26s.net/c`) y publicó su organigrama
como imagen; aquí está transcrito, mapeado, convertido en plantilla y en guion de activación. Lo que
se mantiene en el tiempo es la doc viva del repo; esto queda como rastro.

| Qué | Dónde | Estado |
|---|---|---|
| **Doc viva** (leer primero): método genérico, tres vías de activación, contrato de la herramienta | `docs/PUB/TEMPLATE-PROTOCOL.md` | en obras (guion disponible; fría y caliente con contrato) |
| Entrada: el organigrama transcrito y su imagen | `entrada/acampada26s_organigrama.json` · `entrada/esquema.jpg` | transcripción del 2026-10-07 (notas en `metadatos`) |
| Manual de bienvenida del nodo (renombrado desde `ARCHIVO/DISCO/onboarding-sol-es.md`) | `onboarding-nodo.md` | el que la wiki de la plantilla referencia |
| **Mapeo** organigrama → Oasis, trazable por `id`, con lo que SSB no modela y la addenda | `MAPEO.md` | cerrado 2026-10-07 |
| **Plantilla** y su contrato (campo → firma de modelo) | `pub/templates/acampada26s.json` · `pub/templates/SCHEMA.md` | 16 tribus + 9 sub-tribus, 7 salas, 7 calendarios, 1 evento, 4 listas, 4 wikis, 2 mapas; 8 pendientes del colectivo |
| **Guion** generado (evidencia: comando + salida) | `guion-acampada26s.md` | regenerable con el comando de abajo |
| **Herramienta** (modo guion; `--cold`/`--hot` devuelven exit 2 hasta WP-O130/O131) | `pub/tools/template-seed.js` | funciona en cualquier Node |
| **Presentación** doble carril (Acampada / Oasis) | `presentacion/index.html` + Artifact publicado (enlace en el reporte del WP) | — |
| Decisión | `plan/DECISIONES.md` D-O28 | asentada |
| Backlog | `plan/BACKLOG.md` WP-O129 (este) · WP-O130 (vía fría) · WP-O131 (vía caliente, bot secretaría) | 🔶 / ⬜ / 🔶 |
| **Continúa en** | `ARCHIVO/DISCO/scriptorium-exported/` (WP-O131): vía caliente con el bot retro, kit visual, guía de reparto y la plantilla genérica Campamento derivada de esta | 2026-10-08 |

## Comando que genera el guion

```sh
node pub/tools/template-seed.js \
  --template pub/templates/acampada26s.json \
  --organigrama ARCHIVO/DISCO/retro-exporter/entrada/acampada26s_organigrama.json \
  --out ARCHIVO/DISCO/retro-exporter/guion-acampada26s.md --guion
# plantilla acampada26s: {"tribes":16,"subtribes":9,"rooms":7,"calendars":7,"events":1,"mailing":4,"wiki":4,"maps":2,"federation":2,"addenda":6}
# origen comprobado contra organigrama: sí (24 ids)
# guion escrito en ARCHIVO/DISCO/retro-exporter/guion-acampada26s.md (8 pendientes)
```

## Hallazgos que cambiaron el diseño (medidos el 2026-10-07)

1. Los modelos publican **siempre como la identidad del sbot** (`src/models/tribes_model.js:318`,
   `rooms_model.js:418`) y el token de sala se firma con sus claves (`src/server/phone_module.js:1262`):
   no hay «identidad proxy» por el socket del pub. La vía caliente es un sbot propio (bot secretaría).
2. El workflow `activists` es **local al cliente** (`src/models/workflows_model.js:111-118`): ningún
   mensaje SSB lo transporta; solo el guion lo lleva.
3. Calendarios y eventos no tienen intervalo **diario** (`calendars_model.js:352-362`): «cada día a las
   20:00» son siete fechas semanales.
4. La votación interna de Parliament es sí/no/abstención (`parliament_model.js:911`) y exige
   legislatura (`:896`): el semáforo vive en `votes`, que admite opciones libres (`votes_model.js:181`).
5. `add` no está en el manifest top-level de ssb-db2 (`compat/db.js:11-15`) y `db.create({keys})`
   pasaría la clave privada por el socket: descartado por la ley 4.

## Para el siguiente agente

1. Lee `docs/PUB/TEMPLATE-PROTOCOL.md` entero; su cabecera dice qué vía existe.
2. Si vas a **cambiar la plantilla**: edita `pub/templates/acampada26s.json`, regenera el guion con el
   comando de arriba y comprueba que sigue en exit 0 con todos los `origen` resueltos.
3. Si vas a **ejecutar WP-O130** (vía fría): el contrato está en TEMPLATE-PROTOCOL §4.3; la verificación
   local es en contenedor (`src/server/node_modules` solo existe en la imagen); precedente
   `test/seed.js` de upstream (`git show oasis-upstream/main:test/seed.js`).
4. Si vas a **ejecutar WP-O131** (vía caliente): primero la DECISIÓN del colectivo sobre la secretaría
   (quién custodia su keyring) y los PERMISOS de `about` e invite; patrón `HUB-PROTOCOL.md` §3 y §11.
5. Si algo diverge al ejecutar: corrige el **protocolo** y anótalo en el reporte del WP; el plan no
   se reescribe.
