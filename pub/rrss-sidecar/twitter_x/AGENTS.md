# Mapa

Segundo cerebro de @{handle} · obra «{title}». Archivo oficial de X generado el {generation}
({n_generations} generación/es integradas; los posts que el autor borró entre generaciones solo
existen en la capa histórica privada y **no** están aquí).

> Este fichero es una plantilla de `pub/rrss-sidecar/twitter_x/AGENTS.md`: el build sustituye
> los marcadores entre llaves por los datos de cada obra.

## Corpus

- Exactamente **{n_posts}** posts propios en `corpus/posts/{id}.md`.
- Voces ajenas (originales de RT, padres de réplicas, tuits citados; nivel 1 y 2): `corpus/external/{id}.md`.
- Páginas enlazadas desde los posts, traídas a Markdown íntegro: `corpus/links/{hash}.md`.
- Media local en `data/tweets_media/`. No copiar; las rutas relativas están en el frontmatter.
- Si hay discrepancia entre una página HTML y el corpus, gana el corpus.

## Protocolo

- Citar por `id` (posts y voces) o por `hash` (enlaces). El texto vive en el fichero citado.
- Nunca resumir como sustituto del post.
- Nunca inventar el texto de tuits ajenos. El original de un RT, el padre de una réplica y el tuit
  citado, si se recuperaron, están en el mismo post (bloques `### Original` / `### Padre` /
  `### Cita`, con su nivel 2 en `#### En respuesta a` / `#### Citaba a`) y en `corpus/external/`.
- Si no hay bloque, o el estado es `unavailable` / ausente, no completar el texto.
- El contenido de `corpus/links/` es de terceros (o de conversaciones del autor con agentes):
  citarlo como fuente enlazada, con su `url` y su `fetched_at`; no atribuirlo al autor de la obra
  salvo los turnos `## Usuario` de una conversación.
- No usar likes, following, ni nada que no esté en este árbol.

## Dónde buscar

- Hilos propios: `indexes/hilos.md`
- Cronología: `indexes/cronologia.md`
- Hashtags: solo los de `indexes/hashtags.md` (no inferir otros)
- Media local: `indexes/media.md`
- Tipos (`original` / `self_reply` / `reply_to_other` / `retweet`): `indexes/tipos.md`
- Voces ajenas: `indexes/externos.md`
- Enlaces y conversaciones con agentes: `indexes/enlaces.md`
- Interlocutores (a quién responde, menciona o retuitea): `indexes/interlocutores.md`

## Ideas, tono, temas

Leer los posts. Todos los índices anteriores son **mecánicos**: salen de campos del archivo.

Si existen `indexes/sistema.md` y `indexes/cantar.md`, son la **capa curada**: una lectura de la obra
firmada y fechada por su custodio (constructos, genealogía, posts elegidos, letras). Reglas:

- Es una interpretación, no un dato. Úsala como mapa para llegar a los posts; la fuente sigue siendo
  `corpus/posts/{id}.md` y se cita por id.
- Sus citas entre «…» seguidas de un id son literales y están verificadas contra ese post.
- La lista «Mención mecánica» de cada constructo es una búsqueda por términos, sin selección.
- No amplíes ni corrijas la capa por tu cuenta: propón cambios al custodio (ids concretos y motivo).

## Regenerar

El generador completo viaja en `tools/` (es `pub/rrss-sidecar/twitter_x/` del repo O_SDK):

```bash
python tools/sidecar.py build --obra <obra>
```
