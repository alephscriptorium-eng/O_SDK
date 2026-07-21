# blobstore-sidecar — fase núcleo (WP-S14)

Núcleo del sidecar de ficheros content-addressed sobre `ssb-blobs` (carril S: **sin tocar `src/`**
de Oasis). Spec: `aleph-scriptorium/plan/RECURSOS/SPEC-sidecar-ficheros-v0.md`. Gobernanza:
PARTE-004 (núcleo ya) · PARTE-001(b) (la fachada HTTP espera el refinement de U101).

## Qué hay (fase núcleo — puro, sin sbot ni Docker)

- `src/nucleo.mjs` — troceo chunk-as-blob (5 MB), manifiesto v1, validación, reensamblado con
  SHA-256 por chunk y total, cids deterministas (`&<base64>.sha256`). **Invariante estructural:**
  si el manifiesto superara `maxBlob` (50 MB), la publicación se **rechaza (409)** — nunca se viola
  el tope en silencio (con defaults eso solo ocurriría con objetos de ~1.7 TB; `maxTamano` 1 GB
  corta mucho antes).
- `src/adaptador-sbot.mjs` — publicar/obtener/estado sobre un almacén de blobs **inyectado**
  (`{add,get,has}` async). En producción se cablea al muxrpc real de `ssb-blobs` (envolviendo
  pull-streams, mismo patrón que `fileshare_model.js`); en tests, a un almacén fake con la misma
  regla de cid. Idempotencia por contenido: lo ya presente no se re-sube.
- `test/nucleo.test.mjs` — `npm test` (o `node --test test/nucleo.test.mjs`): 10 tests que
  demuestran los invariantes (ii) y (iii) del SPEC, idempotencia, corrupción→422 y bordes.

## Fase fachada (contrato U101, refinement 2026-07-18)

- `src/fachada-http.mjs` — servidor `/x/blobstore/v0/*` según el contrato: `POST objetos` (201,
  idempotente), `GET objetos/:cid` (200/206 con **Range**, 404/422), `GET estado/:cid` (el **poll**
  de la respuesta ①), `POST deseos` (202 → `blobs.want`), `GET salud`. **Token opcional** por env
  (②, sin mTLS); errores mapeados al SPEC (404/409/422/503). Cero deps → testeable con fake.
- `src/cableado-sbot.mjs` — cableado real vía **socket unix** `~noauth` (⑤): envuelve pull-streams
  de `ssb-blobs` en el contrato `{add,get,has,want}`. Import perezoso: solo corre en el contenedor.
- `src/servidor.mjs` — entrada del contenedor (env: `BLOBSTORE_PORT`, `OASIS_SOCKET`,
  `BLOBSTORE_TOKEN`, `BLOBSTORE_MAX_TAMANO`); reconecta al sbot perezosamente (caída → 503).
- `test/fachada.test.mjs` — 8 tests HTTP reales contra puerto efímero con almacén fake.

## Deploy (preparado, NO desplegado)

`Dockerfile` (bookworm-slim por los prebuilds de sodium) + `deploy/compose.blobstore.fragmento.yml`
— el fragmento está **fuera** de `docker-compose.pub.yml` a propósito: se integra en el tick de
deploy (instrucciones en el propio fragmento) para que ningún deploy del pub lo arrastre antes.
La entrega a zeus = llenar sus `ZEUS_BLOB_*` con el endpoint vivo. Nota ops: el contenedor monta el
`ssb-data` del pub para hablar por el socket (`~noauth` vía `ssb-unix-socket`); no toca claves.
