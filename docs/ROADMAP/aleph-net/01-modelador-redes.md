# 01 — El modelador de redes (`F4/modelador-redes`)

Leyenda: [V] leído · [E] reportado por exploración, sin cotejo · [NV] · `<pendiente>`. Ver `00-indice.md`.

## Qué es (hechos)

- Repo git propio (único repo git de F4), v0.2.0, Python ≥ 3.9, paquete
  `modelador_redes`. Web: `alephscriptorium-eng.github.io/modelador-redes`.
  Licencia `GPL-3.0-or-later AND LicenseRef-Animus-Iocandi`. `README.md:1-14` [V].
- «**No se implementa ningún producto.** El repo es documentación de backlog
  y el generador que la publica.» `README.md:14` [V]. «Cualquier tarea `TK-*`
  de un backlog es una especificación, no código.» `llms.md:14` [V].
- Todas las modelizaciones auditan el mismo código: `epsylon/oasis` @
  `9a657b776fcafc7c24bf3ad61825316385ecf513` (1.0.7, AGPL-3.0), en
  `vendor/oasis`, gitignorado. `llms.md:15` [V].
- GitHub *deprecated* como remoto canónico → Radicle; migración **pendiente**
  (ni repo inicializado ni nodo `rad.escrivivir.co`). `README.md:9-12`,
  `docs/radicle.md:1` [V].

## El grafo del catálogo (nodo / arista)

- **Nodo** = doctrina pura auditada contra Oasis. «No cita a otro nodo como
  autoridad, solo hechos verificados del código.» `llms.md:24` [V].
- **Arista** = híbrido o contraste entre **dos** nodos (`tipo: "arista"`,
  `nodos: ["a","b"]`, `relacion` libre). Id `a+b`, carpeta `modelos/a+b/`,
  rama `dev/a+b`. Nunca reescribe a sus nodos. `llms.md:25` [V].
- Esquema real de `modelo.json` (no hay JSON-Schema; `jsonschema` está en
  `pyproject.toml:26` pero no se importa) [E]:

| Elemento | Dónde | Valor |
| :-- | :-- | :-- |
| Campos obligatorios | `modelador_redes/modelos/catalogo.py:25` | `id · nombre · rama · estado · descripcion` (str no vacío) |
| Tipos | `catalogo.py:26` | `("nodo", "arista")`, por defecto `nodo` (`:100`) |
| Separador | `catalogo.py:27` | `+` |
| Opcionales | `catalogo.py:103,126` | `nodos: list[str]`, `relacion: str` |
| **Cardinalidad de arista** | `catalogo.py:104-108` | `if len(nodos) != 2: raise` — «una arista necesita exactamente dos nodos» |
| Nodo no lleva `+` ni `nodos` | `catalogo.py:109-113` | |
| Validación de grafo | `catalogo.py:141-151` | aristas a nodos inexistentes; `nodos[0]==nodos[1]` prohibido; solo nodos pueden ser extremos (`ids_nodos = {…if not m.es_arista}`, `:142`) |
| Serialización | `catalogo.py:154-173` | `{"nodos": [...], "aristas": [...]}` |
| Render SVG | `modelador_redes/site/grafo.py:28` | `if len(ids) != 2: continue` (la arista se omite); nodos en círculo, aristas `<line>`, sin layout de fuerzas (`:10-13`) |

Cardinalidad 2 cableada en tres sitios independientes: `catalogo.py:105`,
`grafo.py:28`, `llms.md:25` [E/V].

## Lo que el grafo NO tiene (grep negativo sobre `*.py`: `hipergrafo|hiperarista|n-ari|proyecci|versionad|meta-grafo|borrado` = 0) [E]

| Pregunta | Respuesta | Dónde |
| :-- | :-- | :-- |
| Relaciones n-arias | no | `catalogo.py:105`, `grafo.py:28` |
| Categorías como entidad | no; lo más cercano: `relacion` (str) y `carril` derivado por regex del id de tarea | `catalogo.py:126`, `backlog.py:67-80` |
| Proyecciones / filtros por atributo | no; solo `aristas_de(nodo_id)` y partición nodo/arista en portada | `catalogo.py:137-138`, `build.py:194-195` |
| Versionado | solo de **documentos** (sufijo de draft); el grafo es el estado del disco en `main` | `catalogo.py:22,58-64,77-80` |
| Meta-grafo (arista sobre arista) | no; grafo plano | `catalogo.py:142-148` |
| Borrado como proyección | no; `_podar_obsoletos()` hace `shutil.rmtree` | `cli/build.py:165-177` (`:173`) |

## Convención de carpetas y drafts

```
modelos/<modelo>/
├── modelo.json
├── drafts/        draft.md → draftv0.md → draftv1.md …  (sufijo mayor = vigente; nunca se reescribe uno anterior)
└── revision/
    ├── 00-indice.md   línea exacta «**Draft vigente:** [draftvN.md](../drafts/draftvN.md)» bajo el H1
    └── NN-*.md        fichas de revisión (enlazan ../drafts/draftvN.md#L…)
```
`README.md:29-36`, `llms.md:56-66` [V]. Regex canónica de la línea:
`indice.py:16-19` (backreference nombre = destino) [E]; la escribe
`escribir_latest` (`:31-48`), la valida `validar` (`:51-64`); `modelador check`
falla si discrepa.

Ramas: `dev/<modelo>` toca **solo** `modelos/<modelo>/`; `main` integra con
`merge --no-ff` y es la única con `public/` y `data/`. `llms.md:43-52` [V].

## CLI y salidas (`modelador_redes/cli/main.py:14-24` [E])

```
modelador build [--target all|catalogo|foss]   # public/ + data/ (solo en main)
modelador check                                 # exit 1 si algo está roto
modelador zip [--modelo X]
modelador indice --modelo X [--check]
```

- `build` → `public/index.html` (portada con SVG del grafo), `public/catalogo.json`,
  `data/catalogo.json`; por modelo `public/modelos/<id>/{index,backlog}.html`,
  `drafts/*.html`, `revision/*.html`, `downloads/*.zip`, `data/<id>/backlog.json`;
  `public/foss/*`; poda de modelos desaparecidos. `build.py:105-212` [E].
- `check` → línea «Draft vigente», grafo, restos de ruta local
  `base/teoria/vendor`, enlaces relativos rotos en `public/**/*.html`,
  ficheros > 300 KB (`paths.py:31`). `check.py:15-87` [E].
- Pages: `.github/workflows/pages.yml` sube `public/` **tal cual** en push a
  `main`; **no construye, no hay CI de pytest**. `llms.md:90-96` [V].
- Backlog: sin `backlog.md` canónico; `backlog.py` recoge toda tabla cuya
  primera celda sea `TK-|OP-|RP-|CL-|EU-|R\d+` (`ID_RE`, `:42`), acumulando del
  draft más reciente al más antiguo, un id cuenta una vez (`:183-228`).
  `llms.md:144` [V], `backlog.py` [E].
- Otros módulos: `enlaces.py` (Oasis → blob GitHub al SHA; `.md`→`.html`;
  `#L` → blob `main`), `markdown.py` (markdown-it-py, anclas h2/h3),
  `packs.py` (zips deterministas, fecha fija 1980), `paths.py` (`OASIS_SHA :28`).
  1.306 líneas de Python; 31 tests en `tests/`. [E]

## Los modelos (fuente de verdad: `modelos/*/modelo.json` + disco)

| id | tipo | rama | drafts | fichas | vigente | TK | OP | estado |
| :-- | :-- | :-- | --: | --: | :-- | --: | --: | :-- |
| `res_publica` | nodo | `dev/res_publica` | 4 | 8 | `draftv2` | 83 | 6 | en revisión; carril D pendiente contra el libro |
| `colectivizaciones` | nodo | `dev/colectivizaciones` | 3 | 11 | `draftv1` | 36 | 6 | D′01-04 verificados; D′05-08 deuda |
| `clase` | nodo | `dev/clase` | 2 | 1 | `draftv0` | 25 | 3 | auditoría escrita sin revisar |
| `res_publica+colectivizaciones` | arista (`contraste`) | `dev/res_publica+colectivizaciones` | 1 | 0 | `draft` | 0 | 0 | **pausa** |

`llms.md:32-37` [V]; conteos de `public/catalogo.json` [E]. **No existe** un
modelo `oasis-faircoin`; es un dosier hermano (`../dosier-oasis-faircoin/`).

Precedentes útiles:
- `clase/drafts/draft.md` [E]: draft semilla nacido de texto ajeno con nota de
  procedencia (precedente para un nodo `relacional`).
- `clase/revision/00-indice.md:5` [E]: «260 citas fichero:línea comprobadas en
  rango por script; sin verificación adversarial». **El script no está en el
  repo y el conteo no se reprodujo** (126 enlaces md / 104 con `#L` / 127
  rutas `vendor/oasis` en `draftv0.md`; +53 `#L` en `01-costuras.md`) [E].
- Metodología declarada `clase/drafts/draftv0.md:21` [E]: «cada afirmación
  lleva `fichero:línea` y la línea contiene el símbolo nombrado».
- Pureza de nodo: commit `6de31f6` (2026-09-10) reescribe la `descripcion` de
  `clase` para no citar a Trevijano ni a las colectivizaciones; commit
  hermano `2448e65` «neutralizar mención a otro nodo». **Es convención sin
  gate**: `modelador check` no la valida; `clase/revision/01-costuras.md:7`
  sigue nombrando `res_publica`. [E]

## El método (la tecnología real) — `docs/informe-tutoria-plasticidad.md` [V]

Seis pasos: corpus → unidades auditables · auditoría `fichero:línea` ·
confrontación · parches · backlog por carriles con defaults · revisión
retroalimentada (`:21-34`). Tres flexiones: **reparar** (Trevijano: RP-n,
carriles D→G→C→B→F→E→L) · **conectar** (colectividades: CL-n, D′→G′→B′→E′→F′)
· **triturar** (Bueno: solo EU-n de eutaxia, D→T→EU). El generador se dobló con
el método (regex de ids, commit `505868b`).

Veredicto del informe (`:10`): «Lo que se demuestra no es la plasticidad del
software sino la plasticidad del **método de auditoría**». Plasticidad de
Oasis: **22/40 hoy, 34/40 con parches S/M** (`:77-87`). Los cinco seams
rígidos (P5, `:83`): karma escalar único (`banking_model.js:840` →
`parliament:422`, `courts:805`, `banking:932`); autor = propietario
(`tribes:721`, `industry:164`, `school:1222`); precio > 0 (`market:182`,
`shops:415`); un feed = una persona (`inhabitants:86-88`); operador del nodo
como poder exterior (config, hops, `backend.js:4651`). P6 «¿una ley cambia
algo?»: `enactApprovedChanges` (`:1102`) publica texto; nada lo ejecuta
(`:84`). «El software no es neutral»: doctrina implícita karmatocrática; el
arquetipo nativo es la meritocracia (`:91`).

Hallazgo transversal de `clase` (`:65`): **la red tiene poderes sin ramas** —
toda la capa cortical (caps del handshake, hops, invitaciones del PUB, puentes
Multiverse, `POST /update`, modo pánico) está en manos del operador del nodo.
«Ninguna constitución que se escriba en el log manda sobre el fichero de
configuración.»

Diez arquetipos (`:93-238`): 1 res_publica · 2 colectivizaciones · 3 clase ·
4 sorteo · 5 confederalismo · 6 liquida · 7 mixta · 8 comunes · 9 cooperativa ·
10 meritocracia (+ suplentes: orden espontáneo, decisionismo, sociocracia).
Aristas naturales propuestas: `res_publica+sorteo`,
`colectivizaciones+confederalismo`, `res_publica+liquida`, `res_publica+mixta`,
`colectivizaciones+comunes`, `cooperativa+faircoin`, `meritocracia+res_publica`,
`meritocracia+clase`.

Seis vías del juguete a ciencia aplicada / DevOps (`:259-289`): A constitución
ejecutable (tests rojo→verde) · B simulación multiagente en contenedores · C
estudio observacional en el pub (`modelador observar`) · D elección social
computacional (Alloy/TLA+) · E externalizar la constitución a `oasis-config.json`
y PR upstream · F CI del catálogo + `modelador citas` · G pipeline
especificación → parche → prueba → despliegue · H eutaxia como SRE.

## Git [E]

`main` @ `083562d` («Inflate vendor»), árbol limpio. Ramas remotas:
`dev/clase` (`2448e65`), `dev/colectivizaciones` (`6ea9015`),
`dev/res_publica` (`51d8d1a`), `dev/res_publica+colectivizaciones` (`8f1dca8`).
Autor `euler <secretaria@escrivivir.co>`. Últimos: `e89d785 build`,
`792d2d2 Merge dev/clase (nodo puro)`, `6de31f6 fix(clase) descripción de nodo
puro`, `2e2d88f fix(backlog) acumular todos los drafts`, `3336705 feat(clase)
draftv0 (260 citas)`, `6ea9015 feat(colectivizaciones) draftv1 D′ verificado`,
`162cc60 docs: plan de vendorización FairCoop, sin ejecutar`.

Deuda documental: `vendor/plan.md` sin ejecutar; `vendor/NEXT_VENDOR_REFACTOR.md`
(acta de fallo: tesis falsa «Faircoin está muerto» → «sin commits desde
2022-02-05, código completo, MIT, citable»); `docs/plan-web.md` superado;
`CHANGELOG.md:29` logo placeholder; `CITATION.cff` sin autor. [E/V]

## Ausencias (resumen; lista completa en `07-ausencias.md`)

Sin JSON-Schema · sin n-arias · sin categorías · sin proyecciones · sin
versionado del grafo · sin meta-grafo · borrado destructivo · sin
`BACKLOG.md`/`ROADMAP.md` · sin modelo `oasis-faircoin` · conteo 260 no
reproducible · sin gate de pureza de nodo · sin CI · sin `vendor/` en el
árbol · **cero conexión** con `s-sdk`, `scriptorium`, `m-sdk`, `n-sdk`
(ni submodule, ni dependencia, ni mención cruzada).
