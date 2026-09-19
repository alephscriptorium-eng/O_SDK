# 07 · Revisión del plan y secuencia de la fase 0

**2026-09-19 · revisión contra `src/` = Oasis 1.1.4 y contra el estado real del cliente y del VPS de hoy.**
El plan de `06` se conserva verbatim; esto es lo que hay que corregir o añadir al ejecutarlo, y el orden
en que encaja con lo que ya está en marcha (cliente del custodio en 1.1.4 con cartera, WP-O108).

Leyenda como en el índice: **[V]** leído o medido en esta sesión.

## Veredicto

El planteamiento es correcto: Oasis anuncia y no siembra, el HTTPS con `Range` del pub hace de semilla
web, y el anuncio es un mensaje SSB irreversible que pide GO. Lo comprobado [V]: `POST /torrents/create`
es multipart con `torrent`, `title`, `description`, `tags` (`src/backend/backend.js:8857`);
`/c/torrents/:id` solo enseña la ficha si el autor tiene `clearnetTorrents` (`:6655`); `/c/blob/:id`
reconoce el bencode y lo sirve como `application/x-bittorrent`.

**Lo que no puede hacerse «ya que estamos»**: el anuncio necesita que exista el `.torrent`, y el texto
enlaza una ficha P2P que todavía no existe. Un anuncio irreversible con un enlace roto o con un torrent
cuyo contenido cambie en el siguiente deploy es peor que no anunciar. **El anuncio es el último paso de
la fase 0, no el primero**: antes van los artefactos por generación (URL inmutable) y la ficha.

## Correcciones al plan

1. **Activar «Torrents en clearnet» no es un interruptor: es un `about` entero.** `POST /profile/edit`
   publica nombre, descripción, imagen y **todas** las `vis_*` reconstruidas desde el formulario
   (`:4765-4845`): lo que no viaja en el POST queda en **falso**, y `name`/`description` ausentes se publican
   **vacíos**. Por tanto: **se hace desde el formulario del navegador**, que llega relleno con el estado
   actual, marcando solo la casilla nueva; **nunca con `curl`** salvo que se reenvíen todos los campos
   vigentes. Antes y después, comparar el `visibilityPrefs` del último `about` propio: la única diferencia
   debe ser `clearnetTorrents` (y `clearnet`, que es su OR). Es un mensaje irreversible: GO aparte.
2. **`size` no es el tamaño de la obra.** `createTorrent` guarda el tamaño **del fichero `.torrent`**
   subido (`:8866`), no «lo que teclea quien publica» (`01` lo dice así: corregir). La ficha clearnet
   mostrará unos KB junto a «⇩»: el tamaño real del zip debe ir **en la descripción** (el texto propuesto ya lo hace).
3. **Los POST desde fuera del navegador exigen `Host` y `Referer` con el mismo host:puerto**
   (`AGENTES.md` §4). Si se usa `curl -F` para `/torrents/create`, con esas dos cabeceras; si no, 403/400.
4. **El cliente ya no es el que midió el plan.** Era 1.1.2; desde hoy es **1.1.4** (WP-O108) y, con la
   cartera cableada, **la primera visita a la GUI publica sola la dirección ECOin** (`CLIENT-PROTOCOL.md`
   §8.2). Orden obligado: primero se cierra la cartera (un mensaje `wallet`, verificado), después el torrent.
   Así cada mensaje irreversible del feed del custodio se cuenta y se atribuye por separado.
5. **Secuencia del feed antes de publicar** (paso 0 del plan: correcto y se mantiene): `pub-feed-seq.sh`;
   si el pub ve una secuencia mayor que la local, **parar** (publicar con el log corto bifurca el feed).
   Tras el upgrade y la cartera, la local habrá subido (`oasisVersion`, `wallet`): esperar a que el pub la alcance.
6. **El HUB sirve el `.torrent` solo cuando tiene el blob.** Los blobs se piden bajo demanda: el primer
   `GET /c/blob/<id>` puede no darlo; reintentar tras unos segundos antes de darlo por roto. El bot del HUB
   está a hops 3: comprobar que la entrada aparece en `/c/torrents` antes de estampar su id en la ficha.
7. **`p2p.json` va firmado**: «anotar los ids de Oasis y re-subir solo la ficha» implica **refirmar**
   `p2p.json` (`p2p.json.sig`). Alternativa más limpia: los ids de Oasis en un fichero aparte sin firmar
   (`p2p/oasis.json`), porque no son parte de la procedencia de los bytes.
8. **Límites del mensaje.** Título ≤ 100 y descripción ≤ 5000 los impone solo el formulario; el límite real
   es el mensaje SSB (8192 bytes con todo). Un magnet con tres trackers + ed2k + el texto propuesto ronda
   1,5 KB: cabe. No pegar listas largas de trackers.
9. **Piezas de 4 MiB (`-l 22`)** están bien para el zip de 1,5 GiB; para el cerebro (33 MiB) dan 9 piezas:
   funciona, pero una pieza corrupta obliga a rebajar 4 MiB. Usar `-l 18` (256 KiB) para ficheros < 100 MiB.
10. **Ficheros que ya cambiaron bajo el plan**: `pub/docker-compose.pub.yml` y `pub/.env*.example` ya no están
    «sucios» (WP-O105…O107 están en `main`); el aviso de no tocarlos decae, aunque el stack de semillas
    independiente sigue siendo la decisión correcta.

## Secuencia de la fase 0 (integrada)

| # | Paso | Irreversible | Hecho cuando |
|---|---|---|---|
| 0 | **Cerrar WP-O108**: cartera del cliente cableada, **1** mensaje `wallet`, backups, `client:ecoin:verify` | sí (hecho con GO) | reporte de O108 en `main` |
| 1 | Medir: `deploy-status.sh` · `git status` limpio · `pub-feed-seq.sh` (local ≥ pub **y** pub alcanza a local) · sha del zip vivo = ficha | — | sin desviaciones |
| 2 | Rama `wp/O110-teatro-p2p`: imagen `teatro-p2p-tools`, `teatro-p2p.sh publicar|status` (`--local`), gancho `TEATRO_P2P=1`, ficha P2P del sidecar, guardas y test | — | gate local: `aria2c` completa solo con la semilla web y `sha256sum -c` coincide |
| 3 | **GO** · VPS: MIME en Caddy (backup → in place → `validate` → `reload` → 6 vhosts) → deploy con `TEATRO_P2P=1` | no (reversible) | `/p2p/` 200 · `.torrent` con su MIME · `gen/…zip` 206 · descarga externa del cerebro verifica · firma de `p2p.json` OK |
| 4 | **GO** · Anuncio en Oasis: dos entradas en `/torrents` con el texto literal aprobado, valores tomados de `p2p.json` **en ese momento** | **sí** | +2 mensajes `torrent` propios, ni uno más; blobs presentes |
| 5 | **GO** · «Torrents en clearnet» desde el **formulario del navegador** (corrección 1) | **sí** | el `about` nuevo solo difiere en `clearnetTorrents`/`clearnet` |
| 6 | Esperar réplica → `/c/torrents/<id>` y `/c/blob/<id>` en el HUB → ids a `p2p/oasis.json` → re-subir la ficha | no | la ficha enlaza el anuncio y el HUB sirve el `.torrent` |
| 7 | Publicidad (`dosier-publicidad-rrss`): ficha de obra, banner 5 y banner 3 regenerados desde `p2p.json` | no | sin datos de conexión en los banners |
| 8 | `TEATRO-P2P-PROTOCOL.md`, fila en `AGENTES.md`, ficha de instancia §5, reporte, CHANGELOG, merge | — | `docs:build` y gate verdes |

Semillas (`seed-bt`, `seed-ed2k`), cartelera y medición quedan para las fases siguientes, como en `06`.

## Texto del anuncio

El de `06` vale con dos ajustes: el tamaño real **siempre** en la descripción (corrección 2) y un solo
magnet por entrada. Se aprueba **literal y con los valores ya sustituidos**, no como plantilla, en el
momento de publicar.
