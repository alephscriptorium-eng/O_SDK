# Mapa

Segundo cerebro de @_dev_aleph_1 (αlephillΩ). Archivo oficial X generado el 2026-08-21
(generación anterior, 2026-07-08, conservada en `../../web/`; 2 posts borrados entre
ambas solo existen en esa capa histórica).

## Corpus

- Exactamente **1454** posts en `corpus/posts/{id}.md`.
- Media local en `data/tweets_media/` (1290 archivos). No copiar; las rutas relativas están en el frontmatter.
- Fuente canónica: `data/tweets.js`. Si hay discrepancia, gana el archivo.

## Protocolo

- Citar por `id`. El texto vive en `corpus/posts/{id}.md`.
- Nunca resumir como sustituto del post.
- Nunca inventar el texto de tweets ajenos. El padre de un `reply_to_other` y el original de un RT, si se recuperaron, están en el mismo post (bloques `### Padre` / `### Original`) y en `corpus/external/{id}.md`.
- Si no hay bloque o `external_status` es `unavailable` / ausente, no completar el texto.
- No usar likes, following.

## Dónde buscar

- Hilos propios: `indexes/hilos.md`
- Cronología: `indexes/cronologia.md`
- Hashtags: solo los de `indexes/hashtags.md` (no inferir otros)
- Media local: `indexes/media.md`
- Tipos (`original` / `self_reply` / `reply_to_other` / `retweet`): `indexes/tipos.md`
- Tweets ajenos recuperados: `indexes/externos.md`

## Ideas, tono, temas

Leer los posts. No hay ficheros de temas inventados.

## Regenerar

```bash
python3 tools/build_corpus.py
```
