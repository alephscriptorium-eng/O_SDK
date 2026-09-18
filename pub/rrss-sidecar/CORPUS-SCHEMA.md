# Corpus normalizado — el contrato entre una fuente y el visor

Un adaptador de fuente (`<fuente>/lib/normalize.py::records(obra)`) entrega una lista de
**registros**, uno por post propio visible, ordenada por `(created_at, id)`. Los generadores del
visor no leen nada más de la fuente. Junto a los registros hay dos stores opcionales: voces ajenas
y enlaces.

## 1. Registro de post

| Campo | Tipo | Significado |
|---|---|---|
| `id` | str | identificador estable y citable del post |
| `created_at` | str ISO 8601 con zona | momento de publicación |
| `actor` | str | quién habla (handle o clave pública) |
| `lang` | str | código de idioma o `und` |
| `kind` | `original` \| `self_reply` \| `reply_to_other` \| `retweet` | partición **mecánica**, por campos, nunca por juicio |
| `text` | str | cuerpo **verbatim** |
| `parent_id` | str \| null | post al que responde |
| `parent_user_id`, `parent_user` | str \| null | autor del padre |
| `parent_in_archive` | bool | el padre es un post propio visible |
| `thread_root` | str | raíz de la cadena de auto-respuestas (una *escena*) |
| `urls` | [str] | todas las URLs expandidas, en orden |
| `quotes` | [str] | ids de posts **de terceros** citados |
| `self_links` | [str] | ids de posts propios enlazados |
| `links` | [str] | URLs externas (ni de la propia red ni citas) |
| `hashtags` | [str] | solo las etiquetas literales de la fuente |
| `media` | [str] | rutas relativas a la obra (`data/tweets_media/…`) |
| `media_src` | [str] | ruta absoluta de origen de cada `media` (no se publica) |
| `generations` | [str] | generaciones del lore en que se vio el post |
| `deleted` | bool | ya no está en la generación primaria |

Mapeo previsto desde una entrada B.O.E.: `entrada.timestamp → created_at`, `entrada.actor → actor`,
`entrada.contenido → text`, `entrada.tipo → kind`, `evidenceHash → evidence` (campo nuevo, opcional).

## 2. Voces ajenas — `store/external_tweets.v2.json`

`{ "schema": 2, "tweets": { "<id pedido>": nodo } }`

| Campo | Significado |
|---|---|
| `id`, `requested_id` | id final y el que se pidió (en un RT difieren) |
| `status` | `ok` · `unavailable` (borrado/protegido) · `error` (reintentable) · `legacy` (texto heredado de un store v1) |
| `level` | `1` = original de RT, padre de réplica o tuit citado · `2` = padre o citado de una voz de nivel 1 |
| `via` | `[{rel: retweet\|parent\|quote\|level2, from: <id>}]`: por qué está aquí |
| `user`, `name`, `user_id`, `created_at`, `lang`, `url`, `text` | lo recuperado; `text` jamás se inventa |
| `parent_id`, `quoted_id` | enlaces al nivel siguiente |
| `media` | `[{type, remote_url, alt, local}]`; solo se publica lo que tenga `local` |
| `source`, `fetched_at`, `attempts` | procedencia |

## 3. Enlaces — `store/links_store.json`

`{ "<hash>": entrada }` con `hash = sha256(url normalizada)[:16]`.

| Campo | Significado |
|---|---|
| `url`, `final_url`, `family` | `agent:*` · `github:*` · `video:*` · `own` · `generic` |
| `status` | `pending` · `ok` · `pending_browser` · `blocked` (REGLA PARAR) · `gone` · `error` |
| `title`, `method` | `direct` · `api` · `jina` · `browser` · `meta` |
| `cited_by` | ids de los posts que lo enlazan |
| `fetched_at`, `sha256_md`, `bytes_md` | el markdown íntegro está en `cache/links/<hash>.md` |

## 4. Lo que el visor produce

`corpus/posts/{id}.md`, `corpus/external/{id}.md`, `corpus/links/{hash}.md`, `indexes/*.md` y el HTML
estático. Invariantes de publicación: `<fuente>/lib/guards.py`.
