# WP-O100 · Teatro: puerta semántica («El sistema» y «El cantar»)

**Fecha**: 2026-09-18 · **Rama**: `wp/O100-teatro-puerta-semantica` · **Asiento**: D-O17 · **Dep**: WP-O99
**Estado**: desplegado y verificado en producción. Propuesta editorial **v1 pendiente de revisión del custodio**.

## Qué se pidió

Cerrar el punto final de WP-O99: la reorganización **semántica** de «Aleph Cero», leyendo el feed hacia
atrás. Criterio del custodio: la obra es **una visión del mundo**, no la historia de un personaje; sus
protagonistas son sus constructos (el modelador de redes, el Scriptorium, la games library, los
pubs…) y los nombres propios son arquetipos de un paradigma. Las puertas mecánicas se conservan y
amplían («son puertas al contenido que pueden variar»). La curaduría de esta vuelta la propone el
editor; el protocolo para revisarla y seguir curando queda asentado.

## Qué se hizo

### Sidecar (git, genérico)

- `lib/editorial.py`: capa editorial **declarativa y opcional**, leída de
  `ARCHIVO/LORE/<fuente>/<obra>/editorial/obra-semantica.json`. Resuelve ids contra lo publicado,
  separa **curado** (`post_ids`, `thread_roots`, `link_hashes`) de **mecánico** (`terms`), verifica
  citas `«…» [[id]]` literales, valida la portada SVG y calcula cobertura y delta.
- `tools/build_site.py`: `sistema/` (índice + página por constructo), `cantar/` (tracklist + corte),
  `conversaciones.html`, `interlocutores/`; portada con SVG inline, concepto y puertas en dos grupos
  («Leer la obra» / «Recorrer el archivo»); chips «curado en» en cada permalink.
- `tools/build_corpus.py`: `indexes/sistema.md`, `indexes/cantar.md` (con aviso de capa curada) e
  `indexes/interlocutores.md`. `lib/normalize.py`: campo `mentions[]`.
- `lib/guards.py`: barrido de SVG sueltos e inline. `AGENTS.md`: mecánico vs. curado.
- `sidecar.py`: `editorial-init | editorial-check | editorial-delta`; `build` se detiene si la capa
  tiene errores. `editorial.example/` y scripts `teatro:editorial:*`.
- `devops/scripts/backup-teatro.sh`: respalda `editorial/` (no es regenerable).
  `deploy-teatro.sh`: verifica `/interlocutores/` y, si existen, `/sistema/` y `/cantar/`.
- Tests: 9 verdes (`test_editorial_layer`: sin capa la salida no cambia; con capa, páginas, chips,
  índices y portada; hostiles: cita inventada, SVG activo, ruta que se escapa, SVG suelto con script).

### Aleph Cero · propuesta v1 (lore privado, fuera de git)

| Territorio | Constructos |
|---|---|
| Teoría | Refundación · 5º poder · Doxa pública e hiperasamblea · Homeomorfía y holón · Críticas · Arquetipos del paradigma |
| Máquina | Hacklab y Oráculo · Scriptorium |
| Red | Pubs Oasis/SSB · Modelador de redes · ClearNet Hub |
| Juguetes | Animus Iocandi · ARG Games Marketplace · F.A.R.O. y medidores · Bots |
| Libro | Nivola · El juego como taxón · «Para un futuro (no revisado)» · Poemas · Aceites Aleph · La obra explicada por su autor |

- 21 constructos, cada uno con el post en que nace, 5-13 posts curados y un texto de citas literales:
  **143 citas verificadas**, 148 posts curados, 244 más por búsqueda mecánica (23,5 % de los 1667
  posts propios no-RT).
- «El cantar de Aleph»: 13 cortes enlazados a YouTube; letra de **B02 · Arkana la rage** (aportada por
  el custodio), mapeada a doxa pública, homeomorfía y holón, bots, pubs y —solo su estrofa final—
  arquetipos. Los otros 12 cortes declaran «letra pendiente».
- Portada: sigilo original en SVG (ℵ, red de siete nodos con dos encendidos —«son 2 de 7»—, ⚫⚪ de
  «Solve et Coagula», marcas de encuadre): un guiño a «para las cámaras del sistema», sin copiar nada.
- Dosier privado `editorial/2026-09-18-dosier-editorial.md`: brief del custodio, cadena del último
  post, playlist, noticia del día y lectura rectificada.

### Producción

`TEATRO_OBRA=aleph-cero npm run devops:teatro:deploy` → 14441 ficheros, zip
`699fbfdd8acca024a3fe32c66cd2a9e3f1b2e77067beb5c90fdfb8ce0dbd57e9`, verificación automática verde.
Comprobado además: `/sistema/`, `/sistema/scriptorium.html`, `/cantar/`, `/cantar/08.html`,
`/conversaciones.html`, `/interlocutores/`, `/indexes/sistema.md` → 200; ruta inexistente → 404;
portada con `<svg>` y sin `<script>`; catálogo con «Leer el sistema». Vecinos como la línea base
(npm y rooms 200, admin y scriptorium 404, mcp 502 preexistente). Caddy sin tocar.
Backup: `devops/backups/teatro/aleph-cero/20260918T110213Z/` (incluye `lore-editorial.tgz`).

## Pendiente para la sesión de revisión del custodio

Seguir `docs/PUB/TEATRO-CURADURIA-PROTOCOL.md` §3:

1. Revisar territorios, constructos, selección y textos; mover, fusionar o renombrar; **firmar**
   (`curated_by`, `curated_at`). Hoy la firma dice «propuesta del editor (Claude), pendiente de
   revisión del custodio» y así se muestra en producción.
2. Aportar las **12 letras** que faltan de «El cantar» y su mapeo a constructos.
3. Decidir sobre la portada (sigilo v1) y el título de la puerta («El sistema»).
4. No afirmado en la obra, por no verificable o por matiz: El Silo T3 y su final; «drones» frente a
   la cámara de helicóptero de *Collateral Murder* (queda como licencia de la canción).
5. Flecos de WP-O99: enlace de Perplexity (permiso de la extensión), enlace `t.co` del tuit de
   WikiLeaks, el retuit llano posterior al export (entrará con la próxima generación) y **copiar los
   backups fuera de la máquina**.
