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

## Revisión del custodio (2026-09-18, misma sesión) — aplicada y desplegada

| Corrección | Qué se hizo |
|---|---|
| «No hay 12 letras: el texto aportado se reparte por las piezas de vídeo» | La letra pasa a ser del cantar entero (`album.lyrics`): se publica íntegra en `/cantar/#letra`; ningún corte dice ya «letra pendiente» y cada uno remite a ella. El álbum, no un corte, mapea a los constructos |
| Portada y título con cabecera, pie y licencia como los medidores | `obra.json → imprint`: cabecera «Animus Iocandi · Hipernivola transmedia · Scriptorium Skins» sobre el título y colofón «Escrivivir · Scriptorium Skins · Animus Iocandi · Aleph Cero · F.A.R.O. · Material transmedia para agentes del juego ARG · AIGPL · Repositorio» en **todas** las páginas (mismos enlaces que los medidores). Genérico y documentado |
| Perplexity: se cancela el rescate | `link-mark --status link_only --waived-by custodio`: nueva vía de dispensa expresa para shares de agente, anotada en el store. Enlaces: 331 ok · 27 link_only · 6 gone · **0 pendientes** |
| Alt del enlace que faltaba (foto del tuit de WikiLeaks) | `voice_notes` en la capa curada: va como `alt` de la foto y como «Descripción del custodio», en el sitio y en `corpus/external/…md`, rotulada para que no se confunda con texto de la voz |
| «Lo que no afirmaste lo afirmas… nada de que se queda en el dosier privado» | Constructo nuevo en Teoría, **«Sacar la cabeza»** (22 en total): el mensaje que la obra repite —«sacar la cabeza equivale a soportar años de represión, como Mujica que llegó a ser presidente tras 12 años de luz»—, la última estrofa del cantar, El Silo T3×10, WikiLeaks y los drones, la historia del bereber como homeomorfía, *Black Mirror*, y los posts del archivo que lo sostienen (perfil bajo, preso político, calabozo, «sufrí while Assange no freed… But...», 😥 → 🫰). Enlazado desde «Arquetipos», el concepto y el cantar |

151 citas literales verificadas; tests 9/9; guardas verdes.

## Pendiente para la sesión de revisión del custodio

Seguir `docs/PUB/TEATRO-CURADURIA-PROTOCOL.md` §3:

1. Revisar territorios, constructos, selección y textos; mover, fusionar o renombrar; **firmar**
   (`curated_by`, `curated_at`). Hoy la firma dice «propuesta del editor (Claude), pendiente de
   revisión del custodio» y así se muestra en producción.
2. Decidir sobre el sigilo de portada (v1) y, si se quiere, repartir la letra corte a corte
   (`tracks[].lyrics`) cuando el custodio indique qué tramo va en cada vídeo.
3. ~~Confirmar la licencia del colofón~~ → **AIGPL** (la de la casa), confirmada por el custodio y
   redesplegada el 2026-09-18: zip `39d726c8bdad2c5a9c9c789ae1b92cc25ca3403615b28c2bc947e85dff1b2c1d`.
4. El retuit llano posterior al export entrará con la próxima generación. **Copiar los backups fuera
   de la máquina.**
