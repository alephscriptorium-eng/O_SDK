# scriptorium-exported · vía caliente: bot retro, kit visual y guía de reparto (plantilla «Campamento»)

Carpeta de **plan + evidencia** (WP-O131, rama `dev/scriptorium-exported`, continúa
[`retro-exporter/`](../retro-exporter/README.md)) de la pregunta «¿puede un bot de soporte del pub activar
una plantilla de organización en caliente, con todo lo creado bonito y con el libro del operador para
repartir los accesos?». Se ejercita con la plantilla genérica **Campamento** (la estructura de Acampada26S
con los nombres propios neutralizados: showcase para cualquier acampada) y el **bot nº 3 de la casa**,
`retro.escrivivir.co`. Lo que se mantiene en el tiempo es la doc viva (`docs/PUB/TEMPLATE-PROTOCOL.md`);
esto queda como rastro.

Tres fases, por decisión del custodio (2026-10-08): **(1) materiales reproducibles** (esta carpeta; nada se
ejecutó al vuelo), **(2) drill local** con identidad desechable, **(3) VPS** con GO por paso.

| Qué | Dónde | Estado |
|---|---|---|
| **Doc viva** (leer primero): método, vías, kit visual, secretaría, guía de reparto | `docs/PUB/TEMPLATE-PROTOCOL.md` §4.3-§4.6 | al día 2026-10-08 |
| Entrada: organigrama genérico y el script que lo deriva (y a la plantilla) del de Acampada | `entrada/campamento_organigrama.json` · `entrada/derivar-campamento.py` | reproducible |
| **Plantilla** y su contrato (`image`, `clearnetPublic`, `responsable`, `meta.reparto`) | `pub/templates/campamento.json` · `pub/templates/SCHEMA.md` | 16 tribus + 9 sub-tribus, 7 salas, 7 calendarios, 1 evento (×7 semanal), 4 listas, 5 wikis, 2 mapas; 11 pendientes del colectivo |
| **Kit visual**: 40 PNG 512×512 + `manifest.json` (sha256, blob id previsto) + wikis copiadas | `pub/templates/assets/campamento/` (generador `pub/tools/template-kit.py`) | determinista (dos ejecuciones, mismos bytes) |
| Avatar del bot 3 (512 px del logo «Scriptorium Skins» del perfil del custodio) | `assets/avatar-retro-512.png` (origen `assets/avatar-retro-src.png`, blob `&5atFcKj/…` del cliente local) | blob previsto `&q4Mkl/fcUGNELIrsmVyMBBdZsCXxyh5LmGN/XovlHDg=.sha256` |
| Fuente del kit | `assets/fonts/DejaVuSans-Bold.ttf` (+ LICENSE) · sha256 `e6476c1b80502924294eed40894c5b18e06c181444ca953e5334262df9c27724` | vendorizada (ni el repo ni PIL traían TTF) |
| **Guion** de activación humana | `guion-campamento.md` (`npm run pub:template:guion`) | regenerable |
| **Guía de reparto** (libro del operador) · misma fuente que la wiki `wiki_reparto` y que la Sala 02 | `guia-reparto-campamento.md` (`npm run pub:template:reparto`) · `pub/site/parlament/campamento/index.html` (`npm run pub:template:reparto:html`) | sin enlaces `/c` hasta tener ledger (fase 2) |
| **Herramienta**: `--hot` (planificador puro + ejecutor por socket), `--reparto` | `pub/tools/template-seed.js` · `pub/tools/lib/{seed-plan,seed-hot,reparto}.js` · `pub/scripts/retro-seed.sh` | ensayada en el drill (146 mensajes; 4 correcciones medidas) |
| **Bot retro**: servicio, config, variables, `about` con imagen | `pub/docker-compose.pub.yml` (`oasis-retro-bot`, perfil `retro`) · `pub/config/retro-bot/ssb-config` · `pub/.env.*.example` · `pub/tools/ssb-admin.js publish-about --image` | arrancado, bootstrapeado y con `about` en local |
| Fase 2 · drill local, gates G0-G11 con comando y salida | `runbook-drill.md` · reporte `plan/REPORTES/WP-O131-retro-bot-via-caliente.md` | **ejecutado 2026-10-08**: G0-G10 ✅, cliente local no medido, G11 no ejecutado (estado vivo) |
| Fase 3 · VPS, pasos con PERMISO | `runbook-vps.md` · evidencia `vps/` (dry-run, un jsonl por bloque, ledger sin códigos) | **ejecutado 2026-10-08**: bot nº 3 en el VPS, Campamento sembrada, 36 enlaces públicos en 200 |
| Dry-run y evidencia del seeder (fase 2) | `dry-run/hot-*.jsonl` · `ledger-drill.json` · `guia-reparto-drill.md` | del drill (identidad desechable; el ledger no lleva códigos) |
| **Mapa de entrada**: un solo mensaje de Blog del bot 3 que enlaza lo que ya existe (código, protocolo, portada con el invite abierto, manual, Sala 02, tribus, calendario, evento, wikis, mapa); sin wiki nueva (DRY) | `mensaje-entrada.mjs` → `mensaje-entrada.md` / `.json` | **publicado 2026-10-08**: `%PbJ+F75RZoHpKWBIrmLtWVT+VV5mlRu+gY50J7tj1zk=.sha256` + `clearnetItem` (seq 149-150) |
| Decisión · Backlog | `plan/DECISIONES.md` D-O29 · `plan/BACKLOG.md` WP-O131 (adelantado a O130) | asentados |
| **Mudanza del bot nº 3** (VPS → máquina operadora, identidad íntegra, `oasisVersion` 1.2.5 aceptado por el pub, infra retirada del host) | `runbook-mudanza.md` · copia `devops/backups/oasis-retro-bot/20261010T031959Z/` (fuera de git) · método HUB §11 | **ejecutado 2026-10-10** (WP-O135, D-O33) |
| **Deshacer de Campamento** (115 retiradas en 11 bloques desde el bot autor; dos listas CLOSED privadas quedan) | `runbook-tombstone.md` · `vps/tombstone-o135.jsonl` · `vps/ledger-tombstones.json` · herramienta `pub/tools/seed-tombstone.js` + `pub/scripts/retro-tombstone.sh` · método `docs/PUB/TEMPLATE-PROTOCOL.md` §9 | **ejecutado 2026-10-10**; revoca «sin tombstone» (dosier WP-O134, 2026-10-09) por decisión del custodio |

**Decisiones del custodio (2026-10-10, WP-O135, D-O33):** el bot retro no sube a 1.2.5 en el VPS: se **muda** a
la máquina operadora como nodo real (el gobierno de las tribus es su identidad; Oasis no traspasa autoría) y se
retira su infraestructura del host; la siembra **se deshace** (tombstones de todo lo generado); nada del repo se
borra, lo que deja de usarse se documenta. Este dosier es el **sistema de deshacer** de la siembra: el ledger de
`vps/` es la entrada y la evidencia de la retirada se deposita al lado. Nada previo se reescribe.

## Comandos que regeneran todo (en este orden)

```sh
python -X utf8 ARCHIVO/DISCO/scriptorium-exported/entrada/derivar-campamento.py   # plantilla + organigrama
npm run pub:template:guion                                                       # guion-campamento.md
npm run pub:template:reparto                                                     # guia-reparto-campamento.md
npm run pub:template:kit                                                         # 40 PNG + manifest + wiki/*.md
npm run pub:template:reparto:html                                                # pub/site/parlament/campamento/index.html
python -X utf8 pub/tools/template-kit.py --avatar ARCHIVO/DISCO/scriptorium-exported/assets/avatar-retro-src.png \
    --out ARCHIVO/DISCO/scriptorium-exported/assets/avatar-retro-512.png
```

## Hallazgos que cambiaron el diseño (medidos en el código el 2026-10-08)

1. `src/client/gui.js:113-145` **no cae al socket** cuando ya hay un sbot en el mismo `.ssb`: muere por LOCK.
   El seeder lleva su propio `cooler` sobre `ssb-client` (patrón `ssb-probe.js`).
2. `src/models/crypto.js:549` carga el keyring de tribus **una vez por proceso**: un backend paralelo lo
   pisaría. El bot va en modo **`server`** (solo sbot). Y así nada publica solo (ni avisos, ni `clearnetSince`).
3. Salas, calendarios, mapas, wikis y eventos **no salen en `/c` por existir**: hace falta un `clearnetItem`
   por objeto (`backend.js:655-751`); con tribu, nunca. Bloque nuevo **`clearnet`**, con su permiso.
4. `/c/blob/:id` **no sirve SVG** (`blobHandler.js:305-313`): el kit es PNG.
5. `.dockerignore` excluye `*.png`: el kit y el avatar entran por bind o `docker cp`, nunca por la imagen.
6. `devops/scripts/lib-node.sh:84-88` mapea el contenedor a su `.ssb` **por nombre**: sin el caso
   `*retro-bot*` el bot se mediría contra el `.ssb` del pub.
7. El guion dice *quién crea* y el manual *cómo se entra*; nadie decía **a quién le toca repartir** cada
   acceso. `responsable` es un hecho del organigrama (el órgano); quién dentro del órgano, DECISIÓN del colectivo.

## Para el siguiente agente

1. Lee `docs/PUB/TEMPLATE-PROTOCOL.md` entero; su cabecera dice qué vía existe y qué falta.
2. Si vas a **ejecutar la fase 2**: Docker Desktop encendido, `npm run pub:local:up`, y `runbook-drill.md`
   gate a gate, con comando + salida pegados en él. La identidad del bot local es desechable
   (`volumes-dev/oasis-retro-bot`). Si un gate no da lo esperado: paras, lo anotas, corriges el **protocolo**.
3. Si vas a **ejecutar la fase 3**: `runbook-vps.md`; cada PERMISO se pide al custodio en el momento. Antes,
   `devops/scripts/deploy-status.sh` y el reporte de la fase 2 cerrado.
4. Si vas a **cambiar la plantilla**: edita `entrada/derivar-campamento.py` (no el JSON a mano, que se
   regenera) y vuelve a correr los comandos de arriba; comprueba exit 0 y los 24 `origen` resueltos.
5. Reporte del WP: `plan/REPORTES/WP-O131-retro-bot-via-caliente.md` (al cerrar la fase 2).
