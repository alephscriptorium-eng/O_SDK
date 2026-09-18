# 04 — Vista global: s-sdk, scriptorium, capas, LORE-HM, holones, gobierno

Leyenda: [V] leído · [E] reportado por exploración, sin cotejo · [NV] · `<pendiente>`. Ver `00-indice.md`.

## Dónde está la vista global (no en s-sdk)

- **Canónica**: `scriptorium` (`MUNDO_RAIZ`). s-sdk es *un mundo más*
  (holón 07) dentro de ella. [E]
- Trilogía de mapas en `scriptorium/plan/` [E]:

| Fichero | Territorio | Regla |
| :-- | :-- | :-- |
| `MAPA-RAIZ.md` | `S` (atlas) | «Canónico: este fichero» (`:4`); REGLA DE LA RAÍZ (`:31-45`): nada nuevo sin declaración, canónico en git + README como copia-release, cero borrados sin veredicto |
| `MAPA-REPO.md` | repo `scriptorium` | 7 gitlinks `codebase/{z,g,s,e,o,a}-sdk` + `skills-library` (`:39-46`); «Fichero trackeado sin fila = FAIL de ronda» (`:73-76`) |
| `MAPA-TALLER.md` | `S_LAB` | tabla de mundos con remoto y pin (`:21-30`); «**El atlas apunta; el LAB construye**» (`:12-16`); **Regla del LAB: «Nada nuevo en esta raíz sin declararlo en este mapa»** (`:32-39`) |

- Dónde «baja» hacia los x-sdk: `MUNDOS.md:12-20` (tabla mundo · tip gitlink ·
  plan/ · skill pin · espejo; bumps = GO del custodio DA-S11; «desfase de
  gitlinks declarado» `:22-29`) → `MAPA-TALLER.md:21-30` (letra → path →
  remoto) → `PLAN-SCRIPTORIUM-V1.md:22-32` (ownership funcional). [E]
- Regla de oro: «**ningún plan escribe obra ajena** — todo cruce es dependencia
  externa con owner, estado y contrato de retorno» (`PLAN-SCRIPTORIUM-V1.md:34-36`). [E]
- Dirección de lectura: «Ceguera ascendente 07→01 es ley: el árbol de zeus
  jamás menciona este marco… Los submodules son anclas read-only
  descendentes» (`s-sdk/plan/README.md:37-41`). [E]
- `s-sdk/LLM.md` [V]: memoria = arena, codebase = piedra; «si tu
  memoria interna y la codebase discrepan, la codebase es la verdad» (`:27`);
  castellano incluso en nombres de fichero (`:29-35`); dos pecados:
  alucinación soberbia y prepotencia arquitectónica (`:40-50`).

## Ownership por mundo (`scriptorium/plan/PLAN-SCRIPTORIUM-V1.md:22-32` [E])

| Mundo | Posee | WPs / P0 |
| :-- | :-- | :-- |
| **Z** `z-sdk` | runtime · contratos · adaptador/resolvers/drivers · catálogo 51 | 67 / 22 |
| **O** `o-sdk` | nodo · storage/compose · **pub L1** · soberanía (forja/imágenes) | 75 / 16 |
| **V** `v-sdk` | Zigurat/**IDE** · editor de config · observación de dominio | 71 / 13 |
| **G** `g-sdk` | juegos · loader/notario de packs · **dominio Ciudad** · player MCP | 54 / 16 |
| **L** `skills-library` | método publicado (mesa · auditor · cerco) | 73 / 19 |
| **HUB** `scriptorium` | playground · **grafo** · gobierno multi-mundo · integración/E2E | 52 / 18 |

Fases: `F0 GOBIERNO+FOSS → F1 CONTRATOS BASE → F2 RUNTIME MÍNIMO → F3 HOLÓN-7
· CIUDAD → F4 PRODUCTIZACIÓN → F5 ACEPTACIÓN v1` (`:40-43`). **Trampa de
nombre**: ese «F4» es una fase / frente aparcado (`BACKLOG.md:41-42`,
`VISION.md:49`, `docs\cola.md:30` «La ciudad en Docker (arco F4)»), no la
carpeta `F4`. [E]

Mundos por letra en `MAPA-TALLER.md:21-30` y `MUNDOS.md:12-20`: z, g, s, e, o,
a, v + skills-library. Modelo «cerrado a 7 letras»
(`s-sdk\WPS_QUEUE\investigacion-sdks-ecosystem.md:5-6`); «no se crea holón 08
ni `L_SDK`» (`WPS_QUEUE\ENCOLADO.md:39-41`). [E]

## Los tres sistemas de capas (no reconciliados) [E]

1. **L1/L2** (canon operativo, en scriptorium/o-sdk; ver `02`). **No hay L0**:
   los `L0` de s-sdk son un envelope de evidencia L0–L3 en un plan DRAFT
   (`WPS_QUEUE\DRAFT\plans\pd2_verbos_json-ld_9d69d81d.plan.md:46-55`).
2. **«layer2» narrativo** (`s-sdk\docs\autoridades\02-scriptorium.md:10,14,19`:
   salas layer2 del PUB, Parlament, LARP).
3. **Hipótesis OSI** (`s-sdk\DEVOPS\VISION.md:8-25`, «Hipótesis de trabajo, no
   doctrina», `:3`): SCRIPT_SDK «ocupa todos los tramos para emerger una capa
   nueva»; «La capa no cierra el stack: lo abre» (`:24`).
4. Además, «capa» como columna narrativa de la tabla de holones (abajo).

**Ningún documento asigna un SDK por capa 0/1/2/UI.** La única asignación es
la tabla de ownership (seis mundos, sin capas) y la doctrina L1/L2 (solo
nombra a o-sdk). El dueño de UI/IDE es **V** (`PLAN-SCRIPTORIUM-V1.md:28`);
`BACKLOG-F2.md:319-321` «UI no inventa dominio». [E]

## LORE-HM (`s-sdk/NETWORK-ENGINE/LANGUAGES/lore-hm/`) [V salvo indicado]

- `NETWORK-ENGINE\README.md:1-6` [V]: «sellado histórico en s-sdk
  (WP-SDK-L05)… **Fuente histórica / incubación declarada — no runtime
  consumer**… no es el monorepo AOS del holón 04». Consumidor runtime:
  ninguno (`:15`); package publicable: ninguno (`@logos/lore-hm` no extraído,
  `:16`); promoción = «decisión pendiente del custodio» (`:44`). Anti-lectura
  (`:39-44`): no montar como dependencia `file:`, no borrar L02–L04.
- Mandato (`lore-hm\README.md:12-14` [V]): lengua común H/M (anfitrión /
  operador Future Machine), contrato de inception P1–P5, ontología nuclear de
  **exactamente cinco** primitivas, semántica no reducible a config plana.
- **Cinco primitivas** (`README.md:40-47` [V]; `src\primitives.ts:13-20,
  71-79` [E]: `assertNuclearCount` lanza si ≠ 5): `Peer` (sujeto que actúa;
  **H/M son roles/capacidades, no tipos de ser**; `roles: 'H'|'M'|'observer'`
  `primitives.ts:29`), `Unit` (agente o máquina operable), `Lease`
  (autorización temporal y revocable), `Activity` (hecho causal; `causedBy?:
  Iri` `:56`), `Artifact` (producido o consumido).
- **«Todo lo demás es proyección, no primitiva»** (`README.md:48-49` [V]):
  `src\projections.ts:9-17` [V] `Pod, Linea, Grafo, Universo, Corto, Barrio,
  DocumentMachine`. `Grafo` = `{projection: 'Grafo', artifact: Artifact}`
  (`:34-37`): **el grafo es una clase de Artifact, no una estructura de
  nodos/aristas**. Única función de proyección implementada:
  `projectUnitIntoPod` (`:74-80`); `asLinea` (`:83-85`). `Barrio` = escenario
  / contenido (`:49-54`); `DocumentMachine` = capacidad/provider del barrio
  (`:56-62`).
- Demo `demos\tipestate-vs-flat\`: «la regla **sí** se expresa en JSON Schema
  (tesis vieja refutada); lo que cambia es el estilo de esquema»
  (`README.md:37` [V]).
- Capa SOLID (`solid\`, WP-SDK-L03) [E]: `schemas\{shapes.shacl.ttl,
  context.jsonld, wire-activity.schema.json}`, `src\{pod, planes, identity,
  conformance, bridge-mcp, hash-dic4, auth-relay, representations}.ts`, docs
  `IDENTIDAD-TRIPLE.md`, `PLANOS-EVENTOS.md`, `DIC-4-HASH.md`,
  `CONFORMIDAD-ESCALONADA.md`, `POD-WAC-ACP.md`, `BRIDGE-MCP.md`.
- Vocabulario durable: `vocab\registro.json` (WP-SDK-L04), `w3c-conocidos.json`.
- Verificadores: `scripts\verificar-inception-l02.mjs`,
  `vocab\scripts\verificar-vocab-l04.mjs`, `scripts\verificar-sellado-l05.mjs`
  (falla si primitivas ≠ 5, si falta la demo, si el registro se mueve, si
  algún consumidor importa `NETWORK-ENGINE`). (`README.md:51-61` [V])
- Git s-sdk: `main` @ `699856c` («merge L05… la lengua compila, el sello liga
  el fichero y el sellado muerde»); ramas `wp/sdk-l01..l05` con worktrees en
  `S_LAB/wt/s-sdk-wp-sdk-lNN`; últimos 15 commits = lane LENGUA, incl. un
  `ROJO-PLANTADO` deliberado (`8d65633`) y su retirada (`225d21f`). [E]

**Relación con el modelador de F4**: LORE-HM modela *ceremonias y agencia*
(quién actúa, con qué autorización, produciendo qué artefacto) con RDF/SHACL/
JSON-LD; el modelador modela *un catálogo de documentos de auditoría* con grafo
binario y render estático. **No comparten ni un fichero ni una dependencia.**
La palabra «proyección» es homónima en ambos y en m-sdk (`03`). [E]

## Ontología H/M en scriptorium (`WP-HUB-101 · hm-ontologia-y-verbos` ✅) [E]

`scriptorium/plan/BACKLOG-F2.md:512-531`: `ontology/hm-v1.context.jsonld`,
`hm-v1.ttl`, `reference/VERBOS.md`; **reuso obligatorio de AS2, PROV-O y
DCTERMS antes de acuñar `hm:` o `lore:`**, con gate que falla si se acuña
existiendo término W3C/DCMI equivalente. `BACKLOG-F2.md:55`: «ontología de un
caso real ejercida por H y M». Lane LENGUA: `s-sdk\plan\BACKLOG-F2.md:35`.
Colas promovidas (`WPS_QUEUE\ENCOLADO.md:1-8,44-51`): cola A → `WP-HUB-100`–
`111` + `WP-SDK-L01`–`L05`; cola B → `U245`–`U249` (z-sdk).

## Cadena de holones (`s-sdk/DEVOPS/METODOLOGIA/HOLONES.md` [V])

Dos leyes (`:5-8`): **ceguera ascendente** (un holón no puede concebir a su
sucesor; desde dentro se vive como «el fin del mundo») y **acceso
descendente** (el sucesor relee y reinterpreta). La cadena crece por
**junturas** (`:10-13`).

| # | Holón | Capa | Origen | Ancla técnica |
| :-- | :-- | :-- | :-- | :-- |
| 01 | Mythos (Zeus/Homero) | cosmológica — destino cerrado, un solo cosmos | fuente directa | `SCRIPTORIUM_V0\zeus-sdk` (anclaje unidireccional) |
| 02 | Logos (Sócrates/Platón) | racional — la razón busca el Bien tras las apariencias | juntura 01↔03 | pendiente |
| 03 | Revelación (Cristo) | personal — el Bien se hace persona, la gracia rompe el destino | fuente directa | `SCRIPTORIUM_V0\emmanuel-sdk` |
| 04 | Razón inmanente (Ilustración) | embudo — seculariza la promesa, un solo método legítimo | fuente directa | **Aleph NETWORK-ENGINE** (`transmedia-system\SCRIPTORIUM-CORE\NETWORK-ENGINE`, el AOS, DB-3) |
| 05 | Sospecha (Nietzsche/Marx/Freud) | desenmascara el embudo — la razón como máscara | a generar | `aleph-scriptorium/plan/` (digestión S0/S3/S4) |
| 06 | Posmodernidad (Lyotard/Foucault) | fin de los metarrelatos — todo fragmenta | a generar | constelación spinoff (registry + r/s/h) |
| 07 | SCRIPT_SDK (la holarquía como método) | holárquica — el método que sostiene fragmentos sin metarrelato | **emergente** — juntura 06↔07 | activo: «esta codebase, que relee y ancla a todos los anteriores sin contenerlos» |

Costura ejecutable (`:34-44`): **LORE-HM** une 01–04, notariada por 07;
junturas 01↔02·02↔03·03↔04 con cuerpo LORE-HM ⏳ pendientes; gate
`verificar-sellado-l05.mjs`.

`HOLONES/` en s-sdk [V ls]: `.gitmodules` declara solo `01-mythos/zeus-sdk` y
`01-mythos/games-library`; `03-emmanuel`, `05-`/`06-aleph-scriptorium` son
READMEs de ruta reservada («sin `git submodule add`; se infla cuando el
custodio dé el tick»). La cadena es una tabla markdown mantenida a mano, no
un grafo. [E]

Esta misma tabla de capas está copiada como `registro.capa` de cada holón en
`m-sdk\packages\view-kit\assets\mapa\mapa.json` (`03`).

## Otro grafo real: capa 5 de CIUDAD [E]

`s-sdk/plan/SPRINTS/sprint-game-city/cantera/CIUDAD/`: `00-CAPAS.md:5-16`
define 8 capas (0 metáfora, 1 barrios = gitmodules, 2 locales = plugins, 3
edificios = agentes, 4 packs, **5 grafo de handoffs/bridges**, 6 fichas, 7
validación DRY). `GRAFO\_INDICE.md:1-26`: **513 edges, 64 emisores, 94
destinos únicos**, generados por `_gen_capa5.py` / `_gen_capa5_1.py` desde
YAML de handoffs. Grafo dirigido binario emisor→destino. Única mención de
«hipergrafo» en s-sdk: `01-BARRIOS\14-WiringAppHypergraphEditor.md:18` («Motor
wiki-racer: flows, state-machine ARG y hipergrafos») — nombre de submodule de
terceros (`wiki-racer` / `hypergraph-editor`).

## Gobierno: lo que existe en disco y no en el mapa [E]

- `ls S_LAB/` [V]: `a-sdk, DELETE, e-sdk, g-sdk, h-sdk, m-sdk, n-sdk, o-sdk,
  skills-library, s-sdk, vigilancia, v-sdk, wt, z-sdk`.
- **`m-sdk`, `n-sdk`, `h-sdk`, `wt`, `DELETE` no están en `MAPA-TALLER.md`, ni
  en `MUNDOS.md`, ni en `MAPA-REPO.md`, ni en `.gitmodules` del atlas, ni en
  `S_LAB/README.md:24-32`.** Por la Regla del LAB son obra sin declarar o
  mapa desactualizado. `m-sdk` mtime 2026-08-11, `n-sdk` 2026-08-09.
- Menciones de `m-sdk` en scriptorium: solo `playground\ciudad\*\handoff.md`
  («Novelist (m-sdk profile `sala`)») y `playground\ciudad\autoridad\package.json:15-16`
  (deps `file:../../../../../S_LAB/m-sdk/.tgz-pulse/zeus-authority-kit-0.4.3-pulse.0.tgz`,
  `zeus-ciudad-0.1.1-pulse.0.tgz`). `n-sdk`: 0.
- `h-sdk`: repo git, remoto `alephscriptorium-eng/H_SDK.git`, «mundo H; vendor
  externo del scriptorium: consume skills-scriptorium y @zeus/* por registry».
- **El modelador de redes no aparece en ningún asiento de la casa** (0 en
  s-sdk, 0 en `scriptorium`). `F4` no es git; solo
  `modelador-redes` lo es; no hay `plan/`, `MAPA-*` ni `BACKLOG` en F4.
  `S_META` no sobrevive a un cambio de máquina
  (`S_META/F3/HANDOFF-ANFITRION-FC3.md:5`, citado en
  `../dosier-relacional/00-dictamen.md:73-74` [V]).
- `S_META/` [V ls]: `F3/` (handoffs FC3, aportes H), `F4/`, `HSDK/`,
  `LORE/`, `OLD/` (memorias de sesión), un txt de 243 KB de 2026-08-03.
- «relacional», «modelador», «modelización», «hiperarista»: 0 en s-sdk y en
  `scriptorium\plan`. «ontología»: `lore-hm\README.md:40`,
  `BACKLOG-F2.md:35,55,384,512-531`.
