# 03 — Mundo N: m-sdk (runtime Novelist, «el editor») y n-sdk (portal)

Leyenda: [V] leído · [E] reportado por exploración, sin cotejo · [NV] · `<pendiente>`. Ver `00-indice.md`.

## Identidad (lo primero que hay que fijar)

- `m-sdk/package.json:2` → `"name": "@alephscript/n-sdk"`; `:5` →
  `"Novelist MCP + UI over Zeus corpus"`. Env `N_SDK_*` (`.env.sample:6-63`),
  paquetes `@n-sdk/view-kit`, `@n-sdk/scene-client`; `llms.md:1` titula
  «n-sdk — instrucciones para LLM». [E]
- `n-sdk/README.md:11-14`: «El runtime Novelist (servidor MCP
  `novelist` + launcher) **vive hoy fuera de este repo**. El plan:
  reconstruirlo aquí poco a poco.» Ese runtime es m-sdk. `n-sdk\.mcp.json`
  apunta a `localhost:3066/mcp` (novelist) y `localhost:3065/mcp` (launcher),
  los puertos de m-sdk (`.env.sample:9,12`). [E]
- En `n-sdk\PLAN.md` «M» es el interlocutor que escribe el runtime («Wishlist
  M ejecutada», `:38`; «Checkpoints git del corpus vía M», `:103`). [E]
- **Conclusión**: m-sdk = implementación (MCP + launcher + view-kit + UI
  Angular); n-sdk = portal + plan de obra + backup de corpus. **Ninguno es
  «layer 2» ni «la UI» en el sentido de o-sdk.** Los dosieres F4 los llaman
  «editor Novelist (m-sdk)» (`../dosier-res-publica/preview.html:165` [V]).
- **Cero SSB**: grep `oasis|sbot|muxrpc|scuttlebutt|secret-stack|ssb-*` en
  fuente = 0 en ambos (los hits son bundles minificados o `presets-sdk`). Lo
  único: `isSsbId()` de `@zeus/protocol` como **validador de formato** en
  `src\novelist\domain\assignActor.ts:5,20-25` («reparto/1 exige que
  actorSsbId sea el ssbId de la peer-card `@….ed25519`»); fixtures con ids
  base64 fabricados (`reparto.json:71`). [E]
- Referencias cruzadas en m-sdk (`.ts/.json/.md`): `n-sdk` 69 (identidad
  propia), `m-sdk` 27, `z-sdk` 23, `g-sdk` 15, `h-sdk` 1, **`o-sdk` 0,
  `s-sdk` 0** (los 17 «s-sdk» son `@zeus/presets-sdk` y `zeus-sdk`). [E]

## m-sdk — arquitectura (`llms.md:3-20` [E])

| Pieza | Ruta | Qué es | Puerto |
| :-- | :-- | :-- | :-- |
| Launcher MCP | `src\launcher\{main,server,process-manager}.ts`, `fleet.manifest.json` | flota de procesos por *profiles* (`msdk`, `sala`) y *waves*; tools `list/launch/stop/launch_profile/logs` | 3065 |
| Novelist MCP | `src\novelist\{server.ts, domain\CorpusStore.ts, bridge\}` | corpus + `materialize` | 3066 |
| Capability packs | `src\capabilities\packs\` | 7 packs: `novelist-read/write/admin/docs/export/prompts/materialize` (`llms.md:39-48`) | — |
| Scene API + UI | `apps\novelist-ui\` (Angular 20 + three) + `src\server\main.ts` (`/scene`, `/api/catalog`, SSE) | el viewport | API 4210, HMR 4200 |

Profile `sala`: `ciudad-node → ciudad-authority → ciudad-lifecycle (:3051) →
api ∥ novelist → 4 MCP jugador (4141–4144) → miradores` (tablero `:3013`,
firehose `:3016`, player3d `:3018` de z-sdk). Malla UI `DEFAULT_ZEUS_UI_MESH`:
slot `novelist` en `:4210/scene` (`llms.md:10,16`). [E]

Paquetes: `packages\view-kit` → `@n-sdk/view-kit` 0.1.0 (xstate 5, `@zeus/ciudad`,
`@zeus/game-engine`, `@zeus/ui-3d-kit`, three 0.170; exporta `views/registry`,
`things`, `machine`; layout, locomoción, things, layers, puppets, director);
`packages\threejs-ui-lib` → `@alephscript/threejs-ui-lib` («vendored from
z-sdk»). Deps `@zeus/*` (`authority-kit` por tgz local, `ciudad`,
`game-engine`, `linea-kit`, `presets-sdk`, `protocol`, `reparto-kit`, `rooms`,
`story-board-schema`, `ui-3d-kit`) desde `https://npm.scriptorium.escrivivir.co`
(`.npmrc:1-2`). **Ese registry es el único punto de contacto con el pub.** [E]

## Tres acepciones de «layer» (ninguna es la L2 de o-sdk) [E]

1. Capa visual de escena: `thing.layer.{ciudad,barrio,flujo}`
   (`packages\view-kit\src\things\packs\layer-things.ts:15-17`; orden
   obligatorio `layer\index.ts:18-20,125`; `SceneDirector.ts:53-54,205`
   «operator layer»; envelope `nodo.meta.view.layers` `llms.md:87`).
2. Estratos del corpus: «tres documentos, capas distintas»
   (`n-sdk\docs\que-es.md:77-79`); «Línea → Story-board → Reparto»
   (`docs\la-obra.md:15`).
3. Layer 2 del pub (rooms + Ciudad + peercard): solo en o-sdk (`02`). m-sdk
   es **consumidor** de esa capa, no la capa.

## Tres acepciones de «proyección» (inconexas, sin sustrato común) [E]

| Sentido | Dónde | Naturaleza |
| :-- | :-- | :-- |
| Vista reducida de documento (`_summary: true` + `*Chars`) | `src\capabilities\packs\summaries.ts:9` «Proyecciones summary para lecturas de corpus: los blobs (script/prompt/tesis)» | ahorro de tokens, unidireccional; `corpus_set_*` **rechaza** payloads con `_summary` (`llms.md:55`) |
| Serialización acotada del árbol Three | `packages\threejs-ui-lib\src\lib\shared\three\safe-serialize.ts:3` «proyecciones de `scene_export`» | export |
| Import sellado del mapa holónico | `packages\view-kit\assets\mapa\SOURCE.md:1` «proyección sellada… copia de consumo, **no fuente de verdad**»; `mapa.json` `mode: "import-once-projection"` | congelada |

## Grafo espacial: `LayoutMap` (la tríada) [E]

`packages\view-kit\src\layout\types.ts:1`: «Canonical spatial graph — profiles
(stage, ciudad, …) specialize, they do not own the triad.»

| Tipo | Campos | Línea |
| :-- | :-- | :-- |
| `LayoutNodo` | `id, kind, displayName?, origin: LayoutPose, anclas: string[], enlaces: string[], data?` (payload por perfil `:26`) | `:18-28` |
| `LayoutEnlace` | **`id, from, to, bidirectional?, walkSpeed?, waypoints?, data?`** → arista binaria dirigida | `:30-39` |
| `LayoutAncla` | `id, parent, slot, position, facing?, ref?: LayoutUnitRef, data?` | `:41-52` |
| `LayoutMap` | `id, profileId ('stage' \| 'ciudad' \| …), nodos, enlaces, anclas: Record, data?` | `:54-64` |

Runtime: colocación por anclas, `layout-room-<id>` (`layout\runtime.ts:99,127-144,269,344-376`);
`locomotion\space.ts:29` solo `kind === 'room'`; `resolve.ts:168` regiones/portales.
Edición: `layout_upsert` **reemplaza el mapa entero**; `layout_patch` merge parcial,
`null` borra; «borrar nodo exige borrar antes sus anclas/enlaces — **sin
cascada**» (`llms.md:66-67`).

## `Gamemap`: proyección del mapa holónico a grafo espacial [E]

- Fuente: `packages\view-kit\assets\mapa\mapa.json` — `kind:
  "hm-mapa-holones-distritos"`, `wp: "WP-HUB-108"`, `counts: {holones: 7,
  distritos: 6, barrios: 24}` (`:1-9`). Procedencia:
  `scriptorium/playground/prueba-de-H-M/fixtures/mapa/mapa.json`
  (`SOURCE.md:1`); `sources.{censo,holones,grafo}Sha256`;
  `asignacion.fuente`: «Derivado de CENSO-ESTADOS + HOLONES.md + GRAFO; L01
  MAPA-HOLONICO (lore-voz→03)».
- Cada holón lleva `registro.capa` ontológico-histórica (`:23` cosmológica,
  `:44` racional, `:64` personal, `:91` embudo, `:105` desenmascara, `:119` fin
  de los metarrelatos, `:133` holárquica). Cada barrio `estado ∈ {vivo 14,
  latente 7, muerto 3}` y `grafo: {handoffEdges: N}` — **escalar, N = 0 en
  todos los inspeccionados**; sin aristas reales entre barrios.
- Distrito `editores` incluye el barrio `wiring-app-hypergraph-editor`
  (`:39,158,275-277`): la única aparición de «hypergraph» en m-sdk, un nombre.
- Código: `packages\view-kit\src\ciudad\trazado.ts` — `Gamemap = LayoutMap &
  CiudadLayoutProfile & {profileId: 'ciudad'}` (`:212-219`);
  `gamemapAsLayoutMap(gm)` «Project a Gamemap to the canonical LayoutMap view
  (shared triad)» (`:221-223`); `gamemapDesdeMapa(mapa, trazado, opciones)`
  (`:559-565`); `calcularTrazado` geometría polar determinista, semilla FNV
  (`:255,331`); tipos `MapaHolon/MapaDistrito/MapaBarrio` (`:47-79`);
  `CiudadLayoutProfile {sceneId, gobierno: {gobierna, opera, ejecutan},
  zones[], defaultAnchorByNode}` (`:199-210`).
- Faceteado en la UI: `catalog-nav.model.ts:1-8` (`obra|tramos|acts|personajes|things|layouts|operador`),
  `ReadinessFacet = any|view|script|bare` (`:10`), `applyFilters` (`:106-136`):
  pestañas + filtros por igualdad.

## Sala, rooms, peercard: la superficie «layer 2» de m-sdk [E]

| Hecho | Dónde |
| :-- | :-- |
| Bridge **attach-only**: «Does not spawn or stop processes; Novelist only joins an already-live node»; `createClient/connectAndJoin` de `@zeus/rooms`, `makeIntent/DEFAULT_CIUDAD_ROOM` de `@zeus/ciudad`, `PROTOCOL_EVENTS` de `@zeus/authority-kit` | `src\novelist\bridge\sala-authority-bridge.ts:1-12` |
| Room por defecto `CIUDAD_DEMO` contra `http://localhost:3017`; alias `ZEUS_SCRIPTORIUM_URL`; **nunca resuelve a un dominio del pub** | `src\config\pd2.ts:19,34,73`; `.env.sample:25,40-42` |
| `room-hub.ts`: «concentrador de suscripciones de zona… no es mesh de suelo»; zonas UX→barrios `plaza→state-machine`, `editores→prolog-editor`, `zigurat→aaia-gallery`; **pub/sub in-memory de un proceso** (`Set` de listeners, `:65`); sin persistencia, red ni firma | `src\novelist\bridge\room-hub.ts:1-3,35-39,65` |
| Cliente de `@zeus/ciudad-lifecycle` (`:3051`), cascada `city_cascade_*` | `ciudad-lifecycle-client.ts` |
| Máquina de sesión de sala arranca en **stubs**: `probeNode`/`probeAuth` lanzan `Error('… not provided')`, `publishInvite → {text: ''}`, `emitJoin → {peerId: 'peer'}` | `packages\view-kit\src\things\packs\sala-session-machine.ts:39-65` |
| Solo son reales con `bridge` vivo (`requireRuntime` → `'salaAuthority runtime missing'`); emiten `sendIntent` de `join/walk/announce` a MCP de jugador del playground (`residente/visitante/corriente`) | `sala-things.ts:542,574-600` |
| **«Invite» = cadena de display** `${url} · room ${room}` pintada en un `thing.prop.text`; sin criptografía, token ni pub. Los 70 hits de `invite` son la máquina XState (`INVITE_READY`, `publishingInvite`) o la obra | `sala-things.ts:560-573`; `sala-session-machine.ts:24,33,76-78,169-182` |
| Modo `card` (peercard) **declarado, sin cablear**: `DomainCtx = {store, mode: 'local' \| 'card', evaluarPermiso?}`; «ningún pack lo invoca; operar siempre como local» | `src\capabilities\types.ts:9-17`; `DEUDA.md:4`; `llms.md:187` |
| Vocabulario peercard existe aguas arriba en `@zeus/protocol` (bundle), no invocado | `dist\…\chunk-IWOP6ZZZ.js:1` |

## Restricciones operativas que condicionan cualquier «navegador» encima [E]

- «⚠ Los `script` de units solo corren con FRAMES»: rAF se suspende en pestaña
  oculta; `/scene` debe estar abierta **y visible**; errores `VIEWPORT_STALLED`
  / `VIEWPORT_DISCONNECTED` (`llms.md:90,117`; `n-sdk\PLAN.md:87`: Firefox
  marca `document.hidden` con la ventana tapada).
- Lecturas resumidas por defecto y presupuesto `N_SDK_MCP_MAX_RESULT_BYTES`
  (`llms.md:55`); «un `thing.prop.text` lleva su textura en base64: una sola
  llamada se come miles de tokens» (`n-sdk\PLAN.md:94`).
- `prompt` no viaja a la escena (`llms.md:88`); dominio no importa MCP
  (`llms.md:186`).
- `materialize` acepta exactamente uno de `layout|ids|tramo`; `facing`
  obligatorio y duplicado en `ancla.facing` y `ancla.position.facing`
  (`n-sdk\PLAN.md:47-66`).

## Deuda, roadmap, git de m-sdk [E]

- `DEUDA.md` (3 ítems): imports relativos crudos a `packages/*/src` (build
  real exigiría imports por paquete; tapado con `moduleResolution: bundler` +
  `typings\zeus-ui-3d-kit-augment.d.ts`) · modo `card` sin cablear ·
  `src/scene-api/` vacío y `scene-api-client.ts` sin importadores (candidatos
  a borrado).
- Sin `BACKLOG.md` ni `plan/`. Roadmap = 10 planes Cursor en `.cursor\plans\`:
  `sala_fleet_ciudad_mesh` (hub como concentrador Room/pub-sub; «editar solo
  `S_LAB/{m-sdk,z-sdk,g-sdk}`… no tocar `scriptorium/codebase`»,
  `:30`), `ciudad_lifecycle_obligatorio` (sin commitear),
  `sala_autoridad_xstate` («Novelist no spawnea ni mata procesos», `:27`),
  `sala_control_modular`, `cortar_pulso_authority`, `launcher_fleet_*`,
  `launcher_mcp_logs`, `api_sirve_ui_compilada`, `sala-authority-kit`. Bug
  abierto: `.cursor\bugs\launcher_launch_profile_sala_hang.md`.
- Git: ramas `main` (`8d2436a`, 2026-08-11), `master` (`1ed3eac`, rezagada),
  `test1` (`57834f3`; diff con main 64 ficheros, sin el corpus `Prueba-H-M`).
  **Sin remoto.** 23 commits desde `e47a8c5 initial`; 13 titulados `--`.
  **Working tree sucio: 18 modificados sin commitear** (`llms.md`,
  `fleet.manifest.json`, `room-hub.ts`, `sala-authority-bridge.test.ts`,
  `room-overlay.component.ts`…) + 2 sin seguir (`stop-ports.ts`, plan
  ciudad-lifecycle). El trabajo Room/hub está a medias y fuera de git.

## n-sdk (`n-sdk`) [E salvo indicado]

- `package.json`: `name: n-sdk`, `version: 0.0.0`, `private`; solo
  `devDependencies` (`@alephscript/skills-scriptorium@0.12.0`, `vitepress
  ^1.6.3`); scripts `skills:sync`, `docs:dev|build|verificar`. **Ni una línea
  de TypeScript de aplicación.**
- Portal `https://n-sdk.escrivivir.co` (repo `alephscriptorium-eng/N_SDK`,
  `.github/workflows/docs.yml`, patrón skill `site-web`). Páginas:
  `docs/index.md` (Escribir / Montar / Representar), `docs/que-es.md` (134 l.,
  panel de capacidades MCP), `docs/la-obra.md` (91 l.).
- `docs/la-obra.md:45-60`: la misma proposición escrita dos veces en el mismo
  documento validado — prosa (tesis del tramo «Dos rooms alejadas… enlace vía
  exterior») y geometría (LayoutMap: RA en origen, RB a 28 unidades). «La
  coherencia… es del autor. Pero el sistema es el único sitio donde ambas
  versiones conviven, se validan juntas y se representan.»
- `docs/que-es.md:81-108`: corpus = 3 documentos; `personajes.refs[]` solo
  referencias a ids; «tramo ≠ acto»; normalización 1:N por id, no n-arias.
- `corpus/backups/2026-08-07-demo-novel/{linea,story-board,reparto}.json` +
  README: snapshot vía MCP antes del reset para «El trecho del continuo»;
  «la fuente de verdad es la rama git… del equipo de M; fidelidad verificada
  por parseo + conteos, **no criptográfica**» (`:3-11`).
- `PLAN.md` = plan de **obra** (Hipótesis del Continuo, 5 tramos = 5 layouts
  = 5 actos: ℕ, ℚ, ℝ, ZFC, CH; reparto CANTOR, HUÉSPED 𝔠, GÖDEL, COHEN; F1
  no cerrada; tipografía matemática con tabla de glifos `:68-81`).
- `CHANGELOG.md` una entrada `0.1.0 — 2026-08-06` (incoherente con
  `package.json` 0.0.0). Git: 4 commits (`b3087c9`, `219fec2`, `4caaeca`,
  `46609fd`), 2026-08-06 → 08-09; working tree `M PLAN.md`, `?? .cursor/
  .mcp.json assets/`. Parado desde 2026-08-09.
- Skills espejadas en `.claude/skills/` (11, incl. `operador-rooms`: el
  contrato peercard/ACL de L2 **presente como método, no aplicado**).
- `LICENSE.md:37`: «the pub/hub/bridge/router **F.A.R.O.** (Frente Aleph de
  Resistencia Ontológica) as easy onboarding for Network-Engine artefacts» —
  texto de licencia/ARG, única «ontológica» del repo.

## Dosieres hermanos F4: el patrón modelo → obra en el editor [V]

`../dosier-res-publica/` y `../dosier-colectivizaciones/`, ambos 2026-09-10:
`00-dictamen.md` («¿Sale del tirón el modelo X en Novelist? ¿Del tirón, o
editor equivocado?») · `01-croquis.md` (barrio con zonas ASCII +
correspondencias zona → doctrina → ficha → verificación → tareas) ·
`02-storyboard.md` (reparto, actos = layouts, «mecánicas que ya existen en el
editor», «lo que habría que escribir») · `preview.html`.

Hechos reutilizables:
- «El editor rotula, no simula» (`res-publica/00-dictamen.md:10`); «el editor
  sigue sin simular… sustrato citable, no runtime» (`colectivizaciones/00-dictamen.md:42-44`).
- «El editor no tiene reloj»: ciclos como beats, no timers (`res-publica:41`).
- Grado de certeza como material escénico: letreros con A/B/C en tiza; penumbra
  = estado declarado del conocimiento (`res-publica/01-croquis.md:56-58`).
- Mecánicas ya probadas: puerta que solo abre legalmente `actor_interact(OPEN)`
  (Gödel/Cohen); offers condicionadas por `machineState`; penumbra por zona con
  `scene_eval`; letreros `thing.prop.text` con `offsetY`; letreros-cita
  `vendor/<id>/ruta#Lx-Ly` (`*/02-storyboard.md` §Mecánicas).
- Escala: `res_publica` es 1 barrio de la obra de 10; «Leaf ids nuevos en
  ciudad-lifecycle si el barrio entra en la obra de 10»
  (`colectivizaciones/02-storyboard.md:45`).
- La envoltura fair (rev. 2): las orillas «sin sustrato asignado» reciben
  sustrato **citable** (vendor, SHA pineados), no vivo.
- `../dosier-oasis-faircoin/00-informe.md` [V]: informe aguas arriba; «hechos
  sin adjetivo»; «no PRs no solicitados».
