# Protocolo de curaduría — la puerta semántica de una obra del Teatro

Una obra del Teatro tiene dos clases de puertas:

| | Puertas **mecánicas** | Puertas **curadas** |
|---|---|---|
| Qué son | Cronología, Hilos, Hashtags, Tipos, Externos, Enlaces, Conversaciones, Interlocutores, Navegador | **El sistema** (territorios → constructos) y **El cantar** (una obra derivada que recapitula) |
| De dónde salen | De campos del archivo, sin juicio | De una lectura del custodio, firmada y fechada |
| Dónde viven | Las genera el sidecar siempre | `ARCHIVO/LORE/<fuente>/<obra>/editorial/` (privado, fuera de git) |
| Si faltan | — | La obra se construye igual, sin ellas |

Las puertas son vistas sobre el mismo contenido y pueden cambiar; los posts, no. Este protocolo dice
cómo crear, revisar, actualizar y seguir curando la capa curada. Comandos equivalentes:
`npm run teatro:editorial:<init|check|delta> -- --obra <obra>` o
`python pub/rrss-sidecar/twitter_x/sidecar.py editorial-<…> --obra <obra>`.

## 1. Anatomía

```
ARCHIVO/LORE/<fuente>/<obra>/editorial/
  obra-semantica.json        el índice declarativo (lo único obligatorio)
  concepto.md                una página: qué es la obra
  portada.svg                opcional: sigilo de portada, vector puro
  constructos/<slug>.md      un texto breve por constructo
  <carpeta>/…md              textos del álbum y letras
  (lo demás: dosieres, notas, fichas — privado, no se publica)
```

Solo se publica lo que `obra-semantica.json` referencia. Todo lo demás en `editorial/` es cuaderno
de trabajo del custodio y no sale del lore.

`obra-semantica.json` (`version: 1`; contrato completo en `pub/rrss-sidecar/CORPUS-SCHEMA.md` §4):

| Clave | Para qué |
|---|---|
| `curated_by`, `curated_at` | Firma y fecha. Se muestran en cada página curada. `curated_at` es además el punto de partida de `editorial-delta` |
| `title`, `copy` | Nombre y entradilla de la puerta principal |
| `concept`, `cover`, `cover_caption` | Texto de concepto (portada e índice del sistema) y SVG de portada |
| `territories[].constructs[]` | `slug`, `title`, `copy`, `text` (ruta al `.md`), `first_id` (post en que nace), **`post_ids`**, **`thread_roots`**, **`link_hashes`** (selección curada), `terms` (regex de la búsqueda mecánica) |
| `album` | `title`, `copy`, `url`, `text`, `tracks[]` con `n`, `side`, `title`, `duration`, `video` (https), `lyrics` (ruta o `null`), `note`, `constructs[]`, `post_ids[]` |

### Convenciones de los `.md` editoriales

- `[[<id>]]` enlaza un post (permalink en el sitio, `corpus/posts/<id>.md` en el segundo cerebro).
- `«texto» [[<id>]]` es una **cita verificable**: el texto entre «…» debe estar literalmente en ese
  post (se ignoran saltos y espacios repetidos). `(…)` o `…` dentro de la cita salta un tramo.
- Los comentarios `<!-- … -->` no se publican. El HTML se escapa: solo vale Markdown.
- Un constructo: 120-200 palabras, abre con cuándo nace, citas literales y la glosa mínima.

### Reglas que el sidecar hace cumplir

1. **Curado ≠ mecánico.** Lo que eliges (`post_ids`, `thread_roots`, `link_hashes`) se muestra como
   «Posts que lo explican»; lo que devuelven los `terms` se lista aparte como «También lo mencionan
   (búsqueda mecánica)» y nunca incluye lo ya curado ni RT.
2. **Nada inventado.** Un id que no existe o está borrado se avisa y se omite. Una cita no literal,
   un `.md` que falta, una ruta que se sale de `editorial/` o un `version` desconocido **detienen el build**.
3. **Portada inerte.** El SVG va inline y solo puede ser vector: sin `<script>`, atributos `on*`,
   `<image>`, `<foreignObject>`, `url()`, `@import` ni `href` externos. Las guardas de publicación
   repiten la comprobación sobre todo SVG del árbol.
4. **Vídeo solo enlazado.** `video` y `album.url` deben ser `https://`; nunca se embebe nada.

## 2. Crear la capa (una vez)

```bash
npm run teatro:editorial:init -- --obra mi-obra     # copia editorial.example/ al lore; no pisa nada
# editar obra-semantica.json y los .md
npm run teatro:editorial:check -- --obra mi-obra -v
npm run teatro:build -- --obra mi-obra
```

Para elegir posts ayuda leer hacia atrás `indexes/cronologia.md` e `indexes/hilos.md`, y buscar por
términos en `corpus/posts/`. El primer post de un constructo (`first_id`) es el dato más valioso:
convierte el mapa en genealogía.

## 3. Revisar una propuesta

Cuando la capa la ha propuesto otro (un editor, un agente), `curated_by` lo dice. Para hacerla tuya:

1. `npm run teatro:editorial:check -- --obra <obra> -v` — ids, citas, ficheros y una tabla
   constructo → curados / mecánicos. `coverage_pct` es el % de posts propios (no RT) que algún
   constructo recoge, curado o mecánico: orienta, no es un objetivo.
2. `npm run teatro:build -- --obra <obra>` y `npm run pub:local:up` →
   `http://localhost:8088/teatro/<obra>/sistema/`. Recorre cada constructo con «siguiente →».
3. Corrige en el lore:
   - **mover un post**: cambia su id de `post_ids` de un constructo a otro (puede estar en varios);
   - **renombrar**: `title`/`copy` libremente; cambiar `slug` cambia la URL pública;
   - **fusionar o partir constructos**: mueve ids y textos; borra el `.md` huérfano;
   - **reordenar**: el orden del JSON es el orden de lectura («← anterior / siguiente →»);
   - **afinar lo mecánico**: edita `terms` (regex, sin distinguir mayúsculas);
   - **texto**: edita el `.md`; toda cita con `[[id]]` se vuelve a verificar;
   - **portada**: sustituye `portada.svg` o quita `cover` para no llevar portada;
   - **letras**: añade el `.md` y apunta `lyrics` en el corte; mapea `constructs`.
4. Firma: pon tu nombre en `curated_by` y la fecha en `curated_at`.
5. `build` → `check` → deploy (`TEATRO-PROTOCOL.md` §4).

## 4. Seguir curando tras un export nuevo

```bash
npm run teatro:lore:import -- --obra <obra> --from <export>
npm run teatro:ingest -- --obra <obra>
npm run teatro:fetch:voices -- --obra <obra> --run
npm run teatro:fetch:links  -- --obra <obra> --run
npm run teatro:editorial:delta -- --obra <obra>            # desde curated_at; o --since AAAA-MM-DD
```

`editorial-delta` lista los posts propios posteriores a la última curaduría que ningún constructo ha
recogido, agrupados en **candidatos** (los reclaman los `terms` de un constructo) y **sin constructo
que los reclame** (ahí suelen nacer los constructos nuevos). Cura, actualiza `curated_at`,
`editorial-check`, `build`, deploy. Los posts que borraste entre exports desaparecen de la capa con un
aviso; no hay que tocarlos a mano.

## 5. Subir de versión el esquema

`version` es un entero. Un sidecar que no entiende la versión del fichero se niega a construir en vez
de interpretar. Al cambiar el contrato: subir `SCHEMA_VERSION` en `lib/editorial.py`, documentar la
migración aquí y en `CORPUS-SCHEMA.md`, y actualizar `editorial.example/` y los tests.

## 6. Agentes

Un agente puede **proponer**, nunca firmar:

- trabaja sobre el lore del custodio con `editorial-check` y `editorial-delta`;
- propone cambios como diff de `obra-semantica.json` y de los `.md`, con ids concretos y el motivo;
- cita literal o no cita; la glosa es mínima y nunca atribuye al autor lo que no está en un post;
- si firma una propuesta, lo dice en `curated_by` («propuesta de …, pendiente de revisión del
  custodio») hasta que el custodio la haga suya;
- los lectores agente de la obra publicada tienen sus reglas en `AGENTS.md` («Ideas, tono, temas»):
  la capa curada es mapa, la fuente es `corpus/posts/<id>.md`.

## 7. Qué se publica de la capa

`sistema/` y `cantar/` (HTML), `indexes/sistema.md` e `indexes/cantar.md` (segundo cerebro, con el
aviso de capa curada), el SVG inline en la portada y los chips «curado en» de cada permalink. El
JSON, los dosieres y cualquier otro fichero de `editorial/` **no** se publican.
