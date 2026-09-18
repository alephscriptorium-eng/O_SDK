# Dictamen — ¿Cómo entra `RELACIONAL.pdf` en la casa?

> **Nota de publicación (2026-09-18).** El ensayo es público: está registrado en la red Oasis como
> documento (2026-09-16) y se sirve desde el hub del pub:
> <https://pub.escrivivir.co/c/documents/%25mJW4WynqLsOwoYwBvSTuV7SUlzBerZ0lOgviqm7MrBU%3D.sha256>.
> Ese registro es la **identificación del modelo** que la casa quiere clonar o forkear; cuál de las dos
> se decide en el dosier [aleph-net](../aleph-net/00-indice.md). Las menciones de este dosier a «permiso
> pendiente» o «palimpsesto privado» son anteriores a esa publicación y quedan superadas por ella.

**2026-09-17 · Dosier F4 · extracción hecha · encaje pendiente del scrum root (planificar / descartar)**

Pregunta doble: (1) extraer a markdown el ensayo «Ontología Relacional y
Epistemología Enactiva» (`RELACIONAL.pdf`, escritorio), y (2) mirar el
ecosistema `S` / `S_LAB` desde F4 para ver con qué se implementa y
dónde vive lo que salga.

## Qué es el documento (hechos sin adjetivo)

- Ensayo filosófico en castellano, 29 págs., ~5.800 palabras. Subtítulo
  «Hipergrafo como Onto-lógica de la Individuación Transindividual». Autor
  declarado: «Síntesis conceptual de conversación Marc/Dídac», 2025-12-26.
- Estructura: 10 secciones (I–X), 29 subsecciones, 6 tesis, 4 citas
  reinterpretadas de la conversación de origen, 47 referencias. Argumento: las relaciones son
  primarias; las n-arias no se reducen a binarias; un mismo hipergrafo admite
  proyecciones múltiples; el versionado es temporalidad inmanente; conocer es
  enactivo; la ética es inmanente; la incompletitud es constitutiva.
- PDF: tabla xref dañada (pdftotext la reconstruye), sin imágenes, sin
  índice ni árbol de estructura, sin metadatos de productor, fuentes no
  expuestas. No hace falta OCR.
- Licencia: **ninguna declarada** en el documento.

## Extracción — hecha

`extraer.py` (stdlib + `pdftotext` 4.00, el de Git for Windows) →
`01-relacional.md`. Reproducible: `python extraer.py --check` sale 0 si el
markdown coincide con lo que generaría hoy. Copia de la fuente en
`fuente/RELACIONAL.pdf` (sha256 `8adb18bc738e…`).

Trampas que mordieron, por si vuelve otro PDF:

1. `pdftotext` sin `-enc UTF-8` emite Latin-1 en Windows → mojibake en todo
   acento y en las flechas «→».
2. El modo crudo pierde las sangrías (única señal tipográfica del PDF: citas
   a 2 espacios, numeradas a 3, viñetas a 6) y **se come los guiones de fin
   de línea** («ser-singular-plural» → «sersingular-plural»). `-layout` los
   conserva. No hay guiones blandos U+00AD, luego todos son reales y se dejan.
3. Los títulos h2 largos salen partidos en dos bloques por el interlineado
   mayor; los h3 no. Se cosen si el bloque siguiente es una línea corta sin
   cierre de frase.
4. 14 párrafos y 1 referencia cortan en salto de página; se cosen con la
   regla «sin cierre de frase y sin ser título → continúa».

Inferido y declarado en la nota del propio md: negritas de etiqueta
(«Whitehead (1929/1978):»), niveles h2/h3, listas. No verificado: cotejo
línea a línea contra el PDF `<pendiente>`.

## Inspección del ecosistema desde F4

**Para extraer, nada que reutilizar.** Ni pandoc, ni PyMuPDF, ni poppler en
la máquina; solo `pdftotext` (xpdf) en `mingw64/bin`. Único precedente en
las dos raíces: un one-liner PyMuPDF dentro de
`a-sdk/.github_V1/prompts/extraer-archivar.prompt.md:84` (prompt V1
archivado, sin cablear). `o-sdk` tiene `src/backend/pdf.js` (escritor) y
pdf.js (visor): generan y muestran, no extraen. `skills-library` (9 skills):
ninguna de documentos.

**Para ingerir y publicar, sí hay método:**

- Protocolo de ingesta de `extraer-archivar.prompt.md`: crear vs. extender,
  no canibalizar, sección `## Origen`, trailer `Fuente:` en el commit.
- `z-sdk/scripts/import-legado`: rutas por variable de entorno, `--check`
  sin escribir, salida determinista. El `--check` de `extraer.py` copia ese
  gesto.
- `modelador-redes` (F4, único repo git del ciclo): render markdown-it,
  reescritura de enlaces, extracción de backlog desde drafts, `modelador
  indice`. Un draft semilla nacido de texto ajeno ya existe: `clase/drafts/draft.md`.
- `o-sdk/docs/PUB/TEATRO-PROTOCOL.md`: «texto verbatim, citado por id; nada
  se resume en lugar de la fuente». Invariante que el md respeta.

**Dónde vive lo durable.** `S_META` no está en git y no sobrevive a un cambio
de máquina (`F3/HANDOFF-ANFITRION-FC3.md:5`). El dosier es lugar de
nacimiento; la casa es un repo. Trampa de nombre: `F4` en
`scriptorium/plan/BACKLOG.md:41` es un frente aparcado del roadmap, no este ciclo.

## Tres vías de encaje (proyección, no decisión)

1. **Nodo `relacional` en `modelador-redes`** — vía por defecto. Es doctrina
   pura, luego nodo: rama `dev/relacional` desde `main`,
   `modelos/relacional/{modelo.json, drafts/draft.md, revision/00-indice.md}`,
   `modelador indice --modelo relacional`. `01-relacional.md` entra tal cual
   como draft semilla, con su nota de procedencia (precedente: `clase`).
   Resonancia: el catálogo ya es un grafo de nodos y aristas; el ensayo es la
   doctrina del grafo mismo (n-arias, proyecciones, versionado). Auditar Oasis
   con categorías relacionales (follow graph, hops, `about`, backlinks, blobs)
   sería el `draftv0`, como `clase` tritura con Bueno. Coste: la auditoría
   fichero:línea es trabajo nuevo (carril D → T).
2. **`S/_fuentes/`** — no encaja. Son checkouts git de cuadernos de
   lectura, no buzón de documentos (`MAPA-RAIZ`); nada entra ahí sin
   declaración en el mapa canónico. Solo si naciera un repo `cuadernos-relacional`.
3. **Skill `extraccion-fuentes` en `skills-library`** — generalizar
   `extraer.py` sobre `skills/_plantilla` (semver minor). Prematuro con un
   solo PDF: prepotencia arquitectónica. Se anota, no se hace.

## Lo que no viene gratis

- **Permiso de autoría.** El ensayo no declara licencia; `modelador-redes`
  publica en web bajo GPL-3.0-or-later AND Animus Iocandi. Antes de la vía 1
  hace falta el sí de Marc/Dídac o una nota de uso `<pendiente>`.
- Cotejo humano del md contra el PDF en los cinco puntos de riesgo: cosidos
  de página, negritas inferidas, listas de §7.1/§9.4/§9.5/§X, referencia de
  Gödel partida, título de §2.5.
- Si vía 1: `modelo.json` con descripción de nodo puro sin citar otros nodos
  (regla del commit `6de31f6`), y el `draftv0` de auditoría, que es el
  trabajo de verdad.

Croquis: `02-croquis.md` · Extracción: `01-relacional.md` · Script:
`extraer.py` · Fuente: `fuente/RELACIONAL.pdf`
