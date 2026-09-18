# Croquis — el ecosistema visto desde F4, y por dónde entra un PDF

Leyenda: **[V]** verificado en disco esta sesión (ruta) · **[NV]** no
verificado · `<pendiente>` decisión o dato que falta.

## Las tres raíces

```
┌─ S · ATLAS (carril S · índice · copia-release de plan/) ─────────────────┐
│ scriptorium/plan/      MAPA-RAIZ · MAPA-REPO · MAPA-TALLER · BACKLOG · DECISIONES │
│ scriptorium/codebase/  a,e,g,h,o,s,v,z-sdk + skills-library  ← gitlinks SOLO LECTURA │
│ _fuentes/              cuadernos-* (checkouts git de lectura; NO buzón de docs)   │
│ LLM.md                 memoria → codebase · castellano · <pendiente> · voz breve   │
└───────────────────────────────────────────▲──────────────────────────────────┘
                                            │ bump de gitlink solo con GO
┌─ S_LAB · TALLER (obra de los x-sdk, un worktree por rol) ────────────────┐
│ o-sdk/    Oasis 1.0.8→1.1.2 (WP-O97, hoy) · HUB clearnet · pdf.js VISOR ·    │
│           src/backend/pdf.js ESCRITOR · docs/PUB/TEATRO-PROTOCOL (verbatim)  │
│ a-sdk/    .github_V1/prompts/extraer-archivar.prompt.md (PyMuPDF, archivado) │
│ z-sdk/    scripts/import-legado (rutas por env · --check · determinista)     │
│ skills-library/  9 skills · ninguna de documentos · _plantilla para una nueva │
└───────────────────────────────────────────▲──────────────────────────────────┘
                                            │ lo durable se asienta en git
┌─ F4 · CICLO ACTUAL (no git · no sobrevive a otra máquina) ─────────┐
│ modelador-redes/        ← ÚNICO repo git del ciclo (main + dev/<modelo>)     │
│ dosier-res-publica/     00-dictamen · 01-croquis · 02-storyboard · preview   │
│ dosier-colectivizaciones/  ídem                                              │
│ dosier-oasis-faircoin/  00-informe · preview · preview-tecnico               │
│ oasis-clearweb/v1.md    plan Sala 04 → ejecutado en o-sdk (WP-O46)           │
│ dosier-relacional/      00-dictamen · 01-relacional · 02-croquis · extraer.py │
│                         fuente/RELACIONAL.pdf                        ← ESTE  │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Piezas tocadas o descartadas

| Pieza | Dónde | Estado | Sirve para |
| :-- | :-- | :-- | :-- |
| `pdftotext` 4.00 (xpdf) | `C:\Program Files\Git\mingw64\bin\pdftotext.exe` | [V] | la extracción (`-enc UTF-8 -layout`) |
| PyMuPDF · pypdf · pdfplumber · pandoc · poppler | — | [V] ausentes | nada; instalar sería decisión nueva |
| `extraer-archivar.prompt.md` | `a-sdk/.github_V1/prompts/` (l. 84: one-liner `fitz`) | [V] archivado | protocolo de ingesta: crear/extender, no canibalizar, `## Origen`, trailer `Fuente:` |
| `import-legado` | `z-sdk/scripts/import-legado/{README,index}.mjs` | [V] | patrón: `IMPORT_SRC_*` por env, `--check`, salida determinista |
| `markdown.py` · `backlog.py` · `indice.py` | `F4/modelador-redes/modelador_redes/modelos/` | [V] | render, backlog desde tablas `TK-`/`OP-`, línea «Draft vigente» |
| `clase/drafts/draft.md` | `modelador-redes/modelos/clase/drafts/` | [V] | precedente de draft semilla nacido de texto ajeno, con nota de procedencia |
| `TEATRO-PROTOCOL.md` | `o-sdk/docs/PUB/` (l. 23-27) | [V] | invariantes: cero JS, cero recursos externos, texto verbatim citado |
| `oasis-clearweb/dosier/README.md` | `o-sdk/ARCHIVO/DISCO/` (l. 11-12) | [V] | leyenda [V]/[NV]/[VPS] y README que enruta lectores |
| `skills/_plantilla` | `S_LAB/skills-library/skills/` | [V] | molde si algún día hay skill de extracción |
| `pdf.js` (writer) · pdf.js (viewer) | `o-sdk/src/backend/pdf.js` · `src/client/public/js/pdf*.mjs` | [V] | nada aquí: generan y muestran, no extraen |

## Flujo de datos (vía 1, por defecto)

```
Desktop/RELACIONAL.pdf
   │ cp (copia; el escritorio es volátil)
   ▼
dosier-relacional/fuente/RELACIONAL.pdf ──sha256 8adb18bc738e…
   │ python extraer.py            (pdftotext -enc UTF-8 -layout → bloques → md)
   ▼
dosier-relacional/01-relacional.md ──── python extraer.py --check  (exit 0 = fiel)
   │ cotejo humano <pendiente> · permiso de autoría <pendiente>
   ▼
modelador-redes  (rama dev/relacional desde main)
   modelos/relacional/modelo.json          id · nombre · rama · estado · descripcion (nodo puro)
   modelos/relacional/drafts/draft.md      = 01-relacional.md + nota de procedencia (como clase)
   modelos/relacional/revision/00-indice.md  «Draft vigente» por `modelador indice`
   │ draftv0 = auditoría de Oasis 1.0.7 @ 9a657b7 con categorías relacionales  ← trabajo real
   ▼
main: merge --no-ff · modelador build · check · pytest · public/ + data/ · Pages
```

## Correspondencias doctrina → código (semilla para el `draftv0`, sin auditar)

| Tesis del ensayo | Coordenada en Oasis/SSB donde mirar | Estado |
| :-- | :-- | :-- |
| T1 Primacía de la relación (nodo sin aristas = potencial inerte) | grafo de follows/blocks, `hops`; un feed sin seguidores no replica | [NV] |
| T2 N-arias irreductibles | mensajes con varios destinatarios (`recps`), hilos (`root`/`branch`), tribes | [NV] |
| T3 Proyecciones múltiples sin relativismo | vistas/módulos (Parliament, Courts, Banking…) sobre el mismo log; `about` múltiple | [NV] |
| T4 Devenir versionado (commit = cristalización provisional) | log append-only, secuencia por feed, blobs inmutables, «borrar solo borra una proyección» | [NV] |
| T5 Enacción (interfaz que invita a co-producir) | HUB clearnet solo lectura vs. cliente que escribe; opt-in del habitante | [NV] |
| T6 Ética inmanente / responsabilidad situada | `CA-ANTI-AUTORIDAD` (D-O6): visibilidad opt-in que viaja con el feed | [NV] |
| §2.5 Descentralizado ≠ distribuido; «free hypergraph» (4 libertades) | pubs + gossip; AGPL-3.0 de Oasis; sin hub único | [NV] |
| §7.1 Incompletitud; «aquí hay dragones» | lo que Oasis no modela: economía real, identidad legal (ver `clase`, `res_publica` carriles E/L) | [NV] |

Todo [NV]: es la tabla que el `draftv0` tendría que convertir en
`fichero:línea`, como hizo `clase` con 260 citas. Aquí solo señala dónde mirar.

## Lo que este croquis no decide

- Vía 1, 2 o 3 (dictamen §Tres vías): scrum root.
- Si el nodo se llama `relacional`, `hipergrafo` u otro: el id fija carpeta y rama.
- Si `extraer.py` se queda en el dosier (hoy) o sube a `modelador-redes/scripts/`
  cuando haya segundo PDF.
