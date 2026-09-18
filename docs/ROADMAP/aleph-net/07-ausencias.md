# 07 — Ausencias: lo que NO existe en la casa (y dónde se buscó)

Leyenda: [V] leído · [E] reportado por exploración, sin cotejo · [NV] · `<pendiente>`. Ver `00-indice.md`.

Una ausencia es un dato. Cada fila dice qué se buscó, dónde y con qué
resultado. «0» = cero coincidencias en ficheros de texto, excluyendo
`node_modules`, `public/`, `dist/`, `.angular/`.

## Estructura de grafo

| Ausencia | Dónde se buscó | Resultado | Ref. |
| :-- | :-- | :-- | :-- |
| Relaciones **n-arias** / hiperaristas tipadas | modelador (`catalogo.py`, `grafo.py`); m-sdk `LayoutEnlace`; s-sdk grafo capa 5; o-sdk | modelador: `len(nodos)!=2` → raise; m-sdk: `from: string, to: string`; capa 5: emisor→destino; SSB: `recps`/`root`/`branch` son listas pero no hiperarista tipada | `01`, `03`, `04`, `02` |
| **Proyecciones** desde un sustrato único (G_X, G_Y coexistiendo) | modelador (`proyecci` = 0 en `*.py`); m-sdk (tres «proyección» inconexas: resumen, export, import sellado); LORE-HM (`Grafo` es clase de Artifact) | ninguna proyección re-derivable; `mapa.json` es `import-once-projection`, «no fuente de verdad» | `01`, `03`, `04` |
| **Meta-grafo** (nodos sobre nodos, relaciones sobre relaciones; registro del uso) | modelador (`validar_grafo` solo acepta nodos como extremos); m-sdk; o-sdk | 0. En SSB sería un tipo de mensaje nuevo bajo opt-in; no existe | `01`, `02` |
| **Versionado del grafo** | modelador | solo de documentos (sufijo de draft); el grafo es el disco en `main` | `01` |
| **Borrado como proyección** | modelador (`shutil.rmtree`); m-sdk (`layout_patch` sin cascada; `layout_upsert` reemplaza todo) | destructivo en ambos. **Excepción**: SSB (tombstone de cliente, log inmutable) | `01`, `03`, `02` |
| **Texto como hipergrafo** (§9.4): co-ocurrencias, etimología, intertextualidad, embeddings | toda la casa (términos: `embedding`, `etimolog`, `intertextual`, `co-ocurren`, `semántica distribucional`) | **0 en todo**. En m-sdk el texto es `prompt/script/tesis` opaco y `prompt` no viaja a la escena | `03` |
| Analogía computacional (graph kernels, isomorfismo) | toda la casa | 0 | — |
| `hipergrafo` / `hypergraph` como concepto propio | toda la casa | solo nombres de terceros: barrio `wiring-app-hypergraph-editor` (`mapa.json`), `HyperGraph Editor PLG-LOG-05` (`catalog.json` huérfano), `14-WiringAppHypergraphEditor.md:18` (`wiki-racer`). En o-sdk solo en binarios del volumen del cliente (el PDF replicado) | `02`, `03`, `04` |
| `relacional` / `modelador` / `modelización` | s-sdk, `scriptorium`, o-sdk, m-sdk, n-sdk | 0 en todos | `04`, `02`, `03` |
| `ontolog*` | m-sdk, n-sdk, o-sdk | 0 (n-sdk: solo «Ontológica» en el acrónimo F.A.R.O. de la licencia). Sí en s-sdk/scriptorium (LORE-HM, WP-HUB-101) | `03`, `04` |

## Integración entre mundos

| Ausencia | Dónde se buscó | Resultado | Ref. |
| :-- | :-- | :-- | :-- |
| **Integración SSB/Oasis en m-sdk o n-sdk** | términos `oasis`, `sbot`, `muxrpc`, `scuttle`, `secret-stack`, `ssb-*`, `peercard`, `feed`, `blob` en fuente | 0 de runtime. Solo `isSsbId()` como validador de formato; fixtures con ids fabricados; «peercard» solo en bundles de `@zeus/protocol` | `03` |
| Mención de `m-sdk` / `n-sdk` en o-sdk | grep recursivo | 0 / 0 | `02` |
| Mención de `o-sdk` / `s-sdk` en m-sdk, n-sdk | grep | 0 / 0 (los 17 «s-sdk» de m-sdk son `presets-sdk`/`zeus-sdk`) | `03` |
| Contrato, puerto o dependencia declarada entre o-sdk y el mundo N | `plan/`, `docs/`, `package.json` | ninguno. Único contacto: registry `npm.scriptorium.escrivivir.co` (`.npmrc`) y la ficha de catálogo `PLG-AUT-01` que apunta al monorepo viejo | `02`, `03` |
| Integración de m-sdk con el HUB del pub o con rooms del VPS | `src/novelist/bridge/` | `room-hub.ts` es pub/sub in-memory de un proceso; bridge attach-only contra `localhost:3017`; `ZEUS_SCRIPTORIUM_URL` nunca resuelve a dominio del pub | `03` |
| Peercard / ACL / salud cableados en m-sdk o n-sdk | `DomainCtx.mode 'card'`, `evaluarPermiso`, skill `operador-rooms` | declarado y marcado deuda (`DEUDA.md:4`); `operador-rooms` presente como método en n-sdk, no aplicado; sala en stubs; «invite» = rótulo | `03` |
| Conexión entre `modelador-redes` y `s-sdk` / `scriptorium` / mundo N | submodules, deps, menciones, rutas | ninguna. Dos universos separados en disco y en git | `01`, `04` |

## API y contratos del pub

| Ausencia | Dónde se buscó | Resultado | Ref. |
| :-- | :-- | :-- | :-- |
| **API REST/JSON del grafo social** (`friends.graph`, follows, hops, `about`/`visibilityPrefs`) | `pub\panel-api`, `docs\PUB`, Caddyfile, `routes_index.js` | no existe. Consumible desde fuera: HTML del HUB `/c`, `/public/status`, `/public/network`, blobstore (no desplegado). `/graphos` y `/json/x` **no expuestos** por el vhost | `02` |
| Endpoint HTTP de invites | `MAPA.md:222-224` | «existe `getInvite()`, falta la ruta» | `02` |
| Spec de muxrpc en `docs/PUB/` | `docs\PUB` | no; solo implícito en `pub\tools\ssb-admin.js`, `ssb-probe.js` | `02` |
| Esquema formal de mensajes SSB (JSON-Schema o tabla de tipos) | `docs/` | no; disperso en `src\models\*.js`; inventario de features **pendiente** (`BASE-3-MECANISMO.md:43`) | `02` |
| Catálogo de servicios del pub a nivel de casa | `scriptorium` | no; el más completo vive en o-sdk (`pub\site\scriptorium\index.html:453-483`, `pub\site\index.html:229-234`) | `02` |
| Rooms server en la suite local | `S_LAB` | vive en `escrivivir-co/scriptorium-vps` (cuenta vieja); inventario `<pendiente>` (`PLAN.md:55,230-232`) | `02` |
| `blobstore-sidecar` desplegado | composes vivos | huérfano a propósito (4 condiciones antes del GO, WP-O50) | `02` |
| `plan\BRIEFS\` en o-sdk | disco | no existe pese a WP-O01 (`BACKLOG.md:56-58`); solo `plan\REPORTES\` (3) | `02` |
| `MAPA-RAIZ/REPO/TALLER` en o-sdk | disco | no (WP-O02 pendiente, `BACKLOG.md:80-86`) | `02` |
| Remote `oasis-upstream` en o-sdk | `MAPA.md:250-258` | no existe; protocolo de upgrade «documentación sin cableado» (no reverificado con `git remote -v`) | `02` |

## Gobierno y capas

| Ausencia | Dónde se buscó | Resultado | Ref. |
| :-- | :-- | :-- | :-- |
| Definición de **layer 0** | s-sdk, scriptorium | no existe; los `L0` de s-sdk son un envelope de evidencia en un plan DRAFT | `04` |
| Documento que asigne un SDK por capa 0/1/2/UI | s-sdk, scriptorium `plan/` | no; solo doctrina L1/L2 (nombra a o-sdk) y tabla de ownership (seis mundos, sin capas) | `04` |
| «layer 2» o «UI» asignadas a m-sdk / n-sdk | ambos repos y la casa | no. «layer» en m-sdk = capa visual de escena; UI/IDE es de **V** | `03`, `04` |
| `m-sdk`, `n-sdk`, `h-sdk` en `MAPA-TALLER.md`, `MUNDOS.md`, `MAPA-REPO.md`, `.gitmodules`, `S_LAB/README.md` | los cinco ficheros | 0 en todos; existen en disco | `04` |
| El modelador de redes en algún asiento de la casa | s-sdk, `scriptorium` | 0 | `04` |
| `plan/`, `MAPA-*`, `BACKLOG` en `F4` | disco | no; solo `modelador-redes` es git | `04` |
| `@logos/lore-hm` como package | s-sdk | no extraído; decisión pendiente del custodio | `04` |
| Consumidor runtime de `NETWORK-ENGINE` | s-sdk | ninguno (gate `verificar-sellado-l05.mjs`) | `04` |
| Holones 02, 03, 05, 06 con submodule | `HOLONES/`, `.gitmodules` | solo 01 (zeus-sdk, games-library); resto rutas reservadas | `04` |

## Modelador

| Ausencia | Resultado | Ref. |
| :-- | :-- | :-- |
| JSON-Schema de `modelo.json` / `backlog.json` / `catalogo.json` | no; `jsonschema` en `pyproject.toml:26` sin importar | `01` |
| Categorías como entidad | no | `01` |
| `BACKLOG.md` / `ROADMAP.md` / `TODO.md` | no; «no hay `backlog.md` canónico» | `01` |
| Modelo `oasis-faircoin` | no; es un dosier hermano | `01` |
| Script del conteo «260 citas» | no está en el repo; conteo no reproducido | `01` |
| Gate de pureza de nodo | no; `check` no la valida; `01-costuras.md:7` sigue nombrando `res_publica` | `01` |
| CI de tests | no; `pages.yml` solo despliega | `01` |
| `vendor/` en el árbol | gitignorado (80 MB, AGPL); las auditorías dependen de un clon local | `01` |
| Nodo `relacional` | no existe (vía 1 del dictamen `<pendiente>` de scrum root y permiso de autoría) | `../dosier-relacional/00-dictamen.md` |

## Mundo N

| Ausencia | Resultado | Ref. |
| :-- | :-- | :-- |
| Código de aplicación en n-sdk | ninguno (VitePress + PLAN + backup) | `03` |
| Modelo de grafo/relaciones en n-sdk | ninguno; «grafo» = grafo de escena Three.js | `03` |
| `BACKLOG.md` / `plan/` en m-sdk | no; 10 planes Cursor | `03` |
| `src/scene-api/` | vacío; candidato a borrado (`DEUDA.md:5`) | `03` |
| Remoto git de m-sdk | ninguno | `03` |
| Aristas reales entre barrios en `mapa.json` | `handoffEdges` = 0 en todos | `03` |
| Mención del ensayo, del dosier relacional o de `S_META` | 0 en m-sdk y n-sdk | `03` |
| Sustrato común de las dos versiones de una proposición (prosa / geometría) | no; «la coherencia es del autor» | `03` |
