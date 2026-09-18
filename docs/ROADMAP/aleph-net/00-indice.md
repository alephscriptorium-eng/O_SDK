# Dosier ALEPH-NET — la red de la casa, volcada como datos

**2026-09-17 · Dosier F4 · volcado de exploración · sin decisión**

Qué es: los **datos** recogidos al mirar la red de la casa (modelador de redes,
pub scriptorium/o-sdk, mundo N = m-sdk + n-sdk, vista global s-sdk/scriptorium)
desde el ensayo relacional (`../dosier-relacional/01-relacional.md`). Sirve
para seguir trabajando sin rehacer la exploración. No decide nada.

Nombre: «Aleph NETWORK-ENGINE» es el holón 04 de la cadena
(`s-sdk/DEVOPS/METODOLOGIA/HOLONES.md:20` [V]): el AOS histórico
(`transmedia-system\SCRIPTORIUM-CORE\NETWORK-ENGINE`). «Aleph net» aquí = esa
red y lo que ha crecido sobre ella.

## Leyenda (vale para todos los ficheros del dosier)

- **[V]** leído directamente en esta sesión (fichero abierto).
- **[E]** reportado por una exploración de agente con `fichero:línea`; no
  cotejado directamente. Tratar como cita de segunda mano hasta abrirlo.
- **[NV]** no verificado.
- `<pendiente>` decisión o dato que falta.

Regla: hechos sin adjetivo. Si un dato de aquí contradice el disco, manda el
disco (`s-sdk/LLM.md:27` [V]).

## Foco: contraejemplos

El trabajo al que sirve este dosier vive en
`../dosier-relacional/contraejemplos/`:

- `dualidad.md` [V] — 14 dualidades de sapiens en 2026, cinco categorías
  (ontológica, epistemológica, psicoarquetípica, civilizatoria, histórica),
  con datos 2026 y hermenéutica.
- `tabla.md` [V] — cuánto **bloquea** el ensayo cada dualidad: columnas
  `Concepto previo · Categoría · ¿Bloquea? · % Bloqueo · Fundamento · Límite`.

Este dosier aporta la tercera pata: **qué dualidades encarna la propia red**
(`05-dualidades-de-la-red.md`), con la misma disciplina de tabla, para que el
ensayo se contraste no solo con la filosofía de 2026 sino con el código que
tenemos.

## Tres correcciones de marco (lo que la exploración cambió)

1. **El modelador de redes no es un motor de grafos.** Es un catálogo de
   modelizaciones: nodo = doctrina auditada contra Oasis 1.0.7 `9a657b7`,
   arista = híbrido entre **exactamente dos** nodos. Sin n-arias, sin
   proyecciones, sin meta-grafo, sin versionado del grafo. Lo que tiene es un
   **método** de seis pasos que se ha doblado tres veces. → `01`.
2. **«El editor» es Novelist y vive en m-sdk.** `m-sdk/package.json` se llama
   `@alephscript/n-sdk` («Novelist MCP + UI over Zeus corpus»). n-sdk es el
   portal VitePress + plan de obra + backup de corpus, sin runtime. Ninguno
   de los dos toca SSB. → `03`.
3. **Layer 2 en la casa = rooms + Ciudad + peercard/ACL** (doctrina L1/L2 de
   scriptorium y o-sdk). m-sdk es cliente attach-only de esa capa en
   localhost, con la máquina de sala en stubs. «Layer» en m-sdk significa capa
   visual de escena 3D. → `02`, `03`, `04`.

Consecuencia para la pregunta original («qué cobertura da el modelador al
diseño del ensayo»): hay **tres lecturas** de cobertura, que no deben
mezclarse: (a) el ensayo como **nodo** del catálogo (doctrina auditable);
(b) el ensayo como **especificación de la herramienta** (hipergrafo); (c) el
ensayo como **subida** modelador → editor → L2 → UI. La tesis de trabajo del
usuario: nada sube a L2 sin modelarse antes.

## Mapa de ficheros

| Fichero | Contenido | Fuente principal |
| :-- | :-- | :-- |
| `01-modelador-redes.md` | esquema, límites, método, plasticidad, modelos, git, ausencias | `F4/modelador-redes` |
| `02-pub-scriptorium.md` | servicios del pub, modelo de datos SSB/Oasis, doctrina L1/L2, API consumible, ausencias | `o-sdk`, `scriptorium/plan` |
| `03-mundo-n-novelist.md` | m-sdk (runtime, grafo espacial, sala, deuda) y n-sdk (portal, obra); dosieres hermanos | `m-sdk`, `n-sdk`, `F4/dosier-*` |
| `04-vista-global.md` | capas, ownership por mundo, mapas canónicos, LORE-HM, holones, gobierno | `s-sdk`, `scriptorium/plan` |
| `05-dualidades-de-la-red.md` | **foco**: dualidades que la red encarna, con coordenada y tesis del ensayo que las toca | todos |
| `06-elementos-diseno-ensayo.md` | D1–D16: elementos de diseño extraídos del ensayo, sin juicio | `../dosier-relacional/01-relacional.md` |
| `07-ausencias.md` | lo que **no** existe en la casa, con dónde se buscó | todos |
| `08-addenda-testbed.md` | el testbed de `contraejemplos/addenda.md` puesto en correspondencia con lo que la casa ya tiene; camino modelar → rotular → sesionar → cristalizar → observar | `contraejemplos/{addenda,roadmap-hard-problem}.md` + 01–07 |

## Precedentes en F4 que este dosier reutiliza

- `../dosier-relacional/00-dictamen.md` y `02-croquis.md` [V]: tres vías de
  encaje; tabla tesis → coordenada Oasis toda [NV].
- `../dosier-res-publica/` y `../dosier-colectivizaciones/` [V]: patrón
  **dictamen → croquis → storyboard → preview** para llevar un modelo del
  modelador al editor Novelist («¿sale del tirón, o editor equivocado?»).
- `../dosier-oasis-faircoin/00-informe.md` [V]: informe aguas arriba; regla
  «hechos sin adjetivo».
- `modelador-redes/docs/informe-tutoria-plasticidad.md (https://github.com/alephscriptorium-eng/modelador-redes)` [V]: puntuación de
  plasticidad y catálogo de diez arquetipos.

## Lo que este dosier no hace

No escribe la matriz de cobertura ni los trabajos de integración (paso
siguiente, ya esbozado). No toca `dosier-relacional/` ni ningún repo git. No
re-verifica una a una las coordenadas [E].
