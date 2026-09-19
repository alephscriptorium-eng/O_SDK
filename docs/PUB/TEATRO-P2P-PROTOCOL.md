# Protocolo del Teatro P2P · las obras salen a la red

> **Estado · fase 0 ejecutada el 2026-09-19** con *Aleph Cero* (WP-O110): obra congelada, artefactos P2P
> publicados y firmados, descarga verificada por semilla web, anuncio en Oasis. **Sin demonios**: las
> semillas propias (BitTorrent y eD2k/Kad), la cartelera y la medición son fases siguientes; el porqué de
> cada decisión está en el dosier `ROADMAP/p2p/` (el plan en `06`, su revisión en `07`).
> Método genérico; los datos de la casa, en `INSTANCIA-SCRIPTORIUM.md`.

> **Modelo mental.** Oasis **anuncia** torrents (un mensaje SSB `torrent` con el `.torrent` como blob) pero
> no siembra ni descarga. El Teatro ya sirve sus zips por HTTPS con `Range`: un `.torrent` con **semilla web**
> (BEP 19) convierte esa URL en fuente permanente sin ningún proceso nuevo. Un torrent, un enlace ed2k o un
> magnet apuntan a **bytes**, no a un nombre: si los bytes detrás de la URL cambian, todos los enlaces
> publicados se rompen en silencio. Por eso lo primero es **congelar**.

## 0. Invariantes

- **Lo que tiene enlaces publicados no muta.** Una obra congelada no regenera sus zips; una edición nueva
  sale con **otro nombre** (`TEATRO_ZIP_SUFIJO`), con su sha256, su firma y su torrent.
- **La raíz de confianza no cambia**: sha256 + firma ed25519 + manifiesto del Teatro. El P2P es otro camino
  hacia los mismos bytes verificables. `p2p.json` va firmado con la misma clave, que **no viaja** al host.
- **Nada se instala en el host**: las herramientas corren en un contenedor efímero y sin red.
- `p2p/`, `CONGELADO.json` y los zips quedan **fuera** de `MANIFEST.sha256`, de los zips y del `rsync --delete`.
- **Anunciar en Oasis es irreversible** (`AGENTES.md` §3): texto literal aprobado y GO, cada vez.

## 1. Congelar

```bash
TEATRO_OBRA=<obra> TEATRO_MOTIVO="<por qué>" bash devops/scripts/teatro-p2p.sh congelar
```

Comprueba cada zip contra su `.sha256` publicado y escribe `<obra>/CONGELADO.json` (ficheros, tamaños,
sha256, fecha, motivo); deja zips y marca en solo lectura. Idempotente: si ya existe, verifica que los bytes
siguen siendo los mismos y, si no, **para**. Desde ese momento `deploy-teatro.sh`:

- no toca los zips congelados ni reescribe sus `.sha256`;
- sin `TEATRO_ZIP_SUFIJO` publica las páginas y **ningún** zip;
- con `TEATRO_ZIP_SUFIJO=<sufijo>` genera `<obra>-<sufijo>.zip` y `<obra>-cerebro-<sufijo>.zip` (y se niega a
  pisar un sufijo que ya exista).

Deja además una nota junto al árbol local del generador, `volumes-dev/teatro/<obra>.CONGELADO.md`:
`deploy-teatro.sh` la imprime en cada deploy. Las páginas de la obra sí pueden redeployarse; el zip congelado
lleva dentro su propio manifiesto.

## 2. Publicar los artefactos

```bash
TEATRO_OBRA=<obra> TEATRO_TITULO="<título>" bash devops/scripts/teatro-p2p.sh publicar
```

Exige la marca de congelación. Construye `teatro-p2p-tools` en el host (`pub/teatro-seed/tools/`), y en un
contenedor efímero genera en `<obra>/p2p/`: `<fichero>.torrent` (semilla web = la URL HTTPS del zip; piezas
de 4 MiB, o 256 KiB por debajo de 100 MiB), `<fichero>.meta4` (metalink), **`p2p.json`** (fuente única:
sha256, infohash, magnet, ed2k con AICH, URLs de firma) e `index.html` (ficha sin JS). Firma `p2p.json` en
local. Idempotente: un `.torrent` que ya existe **no se rehace** (su infohash ya está publicado).
Trackers: `TEATRO_P2P_TRACKERS` (tres abiertos por defecto; `-` = solo DHT/PEX).

## 3. Verificar

`publicar` comprueba desde fuera `p2p/` 200, cada `.torrent` y `.meta4` 200 y **206** en cada zip (sin `Range`
no hay semilla web). La prueba que vale es descargar con el torrent **sin pares**, desde una máquina ajena al host:

```bash
docker run --rm alpine sh -c 'apk add -q aria2; cd /tmp && wget -q <URL del .torrent> && \
  aria2c -q --seed-time=0 --enable-dht=false <fichero>.torrent && sha256sum <fichero>'   # = el de p2p.json
```

Caddy sirve `.torrent` como `application/x-bittorrent` de fábrica: no hay que tocar el edge.

## 4. Anunciar en Oasis

Desde la cuenta que responde por la obra, en un cliente **al día con el pub**
(`devops/scripts/pub-feed-seq.sh <feed>`: `seq_pub` = secuencia local; si el pub va por delante, **parar**:
publicar con el log corto bifurca el feed).

1. Texto literal **con los valores de `p2p.json` ya sustituidos**, aprobado por el custodio. El tamaño real va en
   la descripción: el campo `size` de Oasis guarda el tamaño del `.torrent`, no el de la obra.
2. Contar antes los mensajes `torrent` propios. Una entrada por fichero: formulario de `/torrents`, o
   `POST /torrents/create` multipart (`torrent`, `title`, `description`, `tags`) desde el loopback con `Host` y
   `Referer` idénticos. **Contar después de cada una**: +1 exacto, o parar.
3. Comprobar que el blob publicado es byte a byte el `.torrent` del Teatro (mismo sha256) y anotar ids de
   mensaje y de blob en `p2p/oasis.json` (sin firmar: no es procedencia de los bytes).
4. **Visibilidad en clearnet** (`/c/torrents/…` en el HUB): la casilla «Torrents» del perfil. Es un `about`
   entero —`POST /profile/edit` reconstruye **todas** las casillas y publica nombre y descripción tal como
   lleguen—: **solo desde el formulario del navegador**, que llega relleno. Otro irreversible, otro GO.
5. El HUB sirve el `.torrent` cuando tiene el blob (se pide bajo demanda): reintentar `GET /c/blob/<id>`.

## 5. Registro

**2026-09-19 · Aleph Cero.** Congelada (`aleph-cero.zip` 1 631 937 463 bytes, sha256 `39d726c8…2c1d`;
`aleph-cero-cerebro.zip` 35 064 225 bytes, sha256 `634feaf4…24bf`). Infohash `7b50c7cd…704c` y `14eb4b43…c2f8`.
`p2p.json` firmado. Desde una máquina ajena al VPS, `aria2c` completó el cerebro solo con el `.torrent`, sin DHT ni
pares, y el sha256 coincidió. Anuncio en Oasis: mensajes 73 y 74 del feed del custodio (ids en `p2p/oasis.json`),
blobs idénticos a los `.torrent` del Teatro, replicados al pub. Pendiente: casilla de clearnet (paso 4),
puerta «P2P» en el sitio de la obra y publicidad. Reporte: `plan/REPORTES/WP-O110-teatro-p2p-fase0.md`.
