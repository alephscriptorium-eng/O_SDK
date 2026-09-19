# 01 · Lo que Oasis ya trae: el módulo Torrents

Todo [V] sobre `o-sdk/src/` = Oasis 1.1.4, salvo donde se indica. Rutas relativas a `o-sdk/`.

## Qué es

Un **catálogo social de ficheros `.torrent`** dentro de la red SSB. Se activa con `torrentsMod: "on"`
(`src/configs/oasis-config.json:61`); el índice de rutas lo describe como «torrents, magnet links,
file sharing, downloads» (`src/AI/routes_index.js:92`).

## El dato: un mensaje SSB de tipo `torrent`

`src/models/torrents_model.js:196-216` — `createTorrent(blobMarkdown, tags, title, description, size, tribeId)` publica:

```js
{ type: "torrent",
  url: "&<base64>.sha256",      // id del BLOB que contiene el fichero .torrent
  createdAt, updatedAt, author,
  tags: [...], title, description,
  size,                          // tamaño declarado del contenido
  opinions: {}, opinions_inhabitants: [],
  tribeId?                       // si se publica dentro de una tribu (cifrado)
}
```

- El fichero `.torrent` viaja como **blob SSB**; el mensaje solo lleva su id (`parseBlobId`, `:17`).
- Tipos asociados: `torrent`, `torrentOpinion`, `tombstone` (`:44`): hay opiniones, favoritos,
  comentarios y borrado lógico, como en el resto de módulos.
- Editar = mensaje nuevo que sustituye al anterior (`updateTorrentById`, `:224`); el log es append-only.

## La interfaz

- Formulario: `input type="file" accept=".torrent"`, título ≤ 100, descripción ≤ 5000
  (`src/views/torrents_view.js:152-163`).
- Listado: botón «DOWNLOAD IT!» → `/blob/<id>` (`:130`): **descarga el `.torrent`**, no el contenido.
- Rutas de la app: `GET /torrents`, `/torrents/:id`, `/torrents/edit/:id`
  (`src/backend/backend.js:3499-3529`); `POST /torrents/create|update|delete|opinions|favorites|comments` (`:8857-8900`).
- Al subir, un `.torrent` que llega como `application/octet-stream` se reetiqueta
  `application/x-bittorrent` (`:10590`).

## En la web abierta (HUB clearnet)

- `GET /c/torrents/:id` (`backend.js:6651-6662`): ficha HTML del torrent **solo si su autor activó
  `clearnetTorrents`** en sus preferencias de visibilidad (`:4783`, `:669`); si no, «no encontrado».
- `GET /c/blob/:id` (`:4911-4945`): sirve el blob. **Reconoce un `.torrent` por su contenido**
  (bencode: empieza por `d` y contiene `announce` o `4:info`) y lo entrega como
  `application/x-bittorrent` con `Content-Disposition: attachment; filename="download.torrent"`
  y caché inmutable de un año.
- Ese handler **carga el blob entero en memoria** y **no atiende `Range`**: pensado para ficheros pequeños.

## Límites

| Límite | Valor | Dónde |
| :-- | :-- | :-- |
| Tamaño máximo de un blob | **50 MB** | `src/server/ssb_config.js:45` (`config.blobs.max`) |
| Tamaño máximo de subida por formulario | 50 MB | `src/backend/backend.js:2412` |

Un `.torrent` pesa kilobytes: cabe de sobra. Un zip de obra (1,5 GiB) **no**: el contenido no puede
viajar por SSB como blob.

## Lo que Oasis NO hace

- **No siembra ni descarga.** No hay ninguna dependencia BitTorrent en el árbol: ni `webtorrent`, ni
  `bittorrent-dht`, ni `parse-torrent`, ni tracker (búsqueda en `src/` y `package.json` [V]).
  Tener Oasis abierto no sirve el contenido a nadie: solo replica el **anuncio**.
- **No interpreta el `.torrent`**: no extrae infohash, nombre, tamaño ni semillas web; `size` lo
  teclea quien publica. No hay campo para `magnet:` ni para `ed2k://` (la descripción es texto libre).
- **No verifica procedencia**: la confianza es la del autor del mensaje SSB (su feed firmado), no la
  del contenido al que apunta el torrent.

## Lectura

Oasis resuelve bien **el descubrimiento dentro de la red**: quién publica qué, con qué etiquetas, con
opiniones y moderación, replicado sin servidor. Deja fuera, a propósito o por alcance, **la
distribución de los bytes**. Ese hueco es exactamente donde un pub puede aportar sin tocar `src/`.
