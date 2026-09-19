# 02 · Las opciones miradas

Investigación del 2026-09-19. Todo [E] con su fuente, salvo lo marcado. El caso: unos pocos zips
grandes (uno de ~1,5 GiB, otro de ~33 MiB por obra), ya servidos por HTTPS con `Range`, sha256 y firma
ed25519, desde un VPS pequeño con Docker.

## A. BitTorrent con semilla web — cero demonios

Un `.torrent` puede declarar URLs HTTP(S) como fuente permanente (**BEP 19**, clave `url-list`). El
cliente pide rangos de bytes al servidor web como si fuera un peer más y verifica cada pieza contra
los hashes del torrent.

| Cliente | BEP 19 | Nota |
| :-- | :-- | :-- |
| libtorrent ≥ 2.1 / qBittorrent 5.x | ✅ | BEP 17 (la otra variante) eliminado: usar solo BEP 19 |
| Transmission 4.x (4.1.3, 2026-06-30) | ✅ | 4.1 cuenta piezas malas y **banea la semilla web que sirve bytes que no casan** |
| aria2 1.37 | ✅ | además entiende metalink |
| WebTorrent | ✅ | pero exige JS y trackers WSS: no aplica a un sitio sin JS |
| rtorrent | ❌ | PR sin mergear |

Fuentes: libtorrent.org/manual-ref.html · github.com/transmission/transmission/releases ·
github.com/webtorrent/webtorrent/blob/master/docs/bep_support.md

**Consecuencia de diseño:** la URL de la semilla web debe servir **siempre los mismos bytes**. Un zip
que se regenera en cada despliegue necesita una URL por generación; si no, quien conserve un torrent
antiguo recibe piezas inválidas y banea la fuente. Los mecanismos de «torrent mutable» (BEP 39, BEP 46)
no tienen adopción real en clientes.

Crear el torrent, sin interfaz: **`mktorrent -w <url>`** (en Debian 13; semilla web, comentario, fuente,
privado). `transmission-create` no admite semilla web; `torrenttools` está archivado (2025-03);
qBittorrent 5 es el único mantenido que crea híbridos v1+v2, que para un solo fichero no aportan nada y
restan compatibilidad.

Magnet: `magnet:?xt=urn:btih:<infohash>&dn=<nombre>&ws=<url>&tr=<tracker>`. El parámetro `ws=` tiene
soporte desigual: **el `.torrent` es el portador fiable de la semilla web**; el magnet va de acompañante.

Trackers: `github.com/ngosang/trackerslist` se actualiza a diario; 2-3 abiertos (opentrackr…) aceleran
el arranque. Lo que sostiene un enjambre a largo plazo es DHT + PEX. Con solo semilla web, el pub no
aparece como peer en ningún tracker.

## B. eD2k / Kad con aMule 3

**aMule 3 existe** [E]: **3.0.0 el 2026-06-08, 3.0.1 el 2026-06-24**, en la organización nueva
`github.com/amule-org/amule` (el repo histórico `amule-project` quedó sin mantenimiento). Anuncio:
amule-org.github.io/blog/amule-3-0-0 («aMule is back after 5 years»).

- CMake, wxWidgets ≥ 3.2, E/S de disco fuera del hilo principal, arreglos O(N²) en la lista de
  compartidos, búsquedas Kad en paralelo, **auto-rescan de carpetas compartidas**, WebUI rehecha.
- **`amuled` (demonio sin interfaz) sigue soportado**, con `amulecmd`.
- **Sin IPv6** en 3.0.x (PR #1318 abierto).
- Debian 13 empaqueta la **2.3.3**, con **CVE-2026-51105** abierta (desbordamiento al procesar un
  mensaje de **servidor** eD2k; CVSS 7.5). La 3.0.1 entró en `sid` el 2026-09-17.
- Imagen Docker mantenida: **`ghcr.io/ngosang/amule` 3.0.1-2** (2026-08-21), multi-arquitectura, por
  un miembro del equipo de aMule.

Publicar un fichero: carpeta compartida + enlace `ed2k://|file|<nombre>|<tamaño>|<md4>|h=<AICH>|/`.
El enlace se calcula **sin demonio**: `rhash --ed2k-link <fichero>` (Debian 13) da MD4 por bloques de
9,28 MB y raíz AICH.

Dos hechos que deciden:

1. **aMule ignora la fuente HTTP** (`|s=http…|`) de un enlace ed2k (wiki.amule.org/wiki/Ed2k_link:
   *«silently ignores the URL»*; [NV] si 3.0.x lo cambió). El HTTPS del pub no sirve de semilla en
   eD2k: **si nadie comparte el fichero, el enlace está muerto**. Para estar en esa escena hace falta
   un `amuled` real (o que el custodio lo comparta desde su aMule).
2. **HighID o nada**: sin TCP 4662 + UDP 4672 (+ UDP 4665) accesibles desde fuera, el nodo queda en
   LowID y apenas puede subir. En Docker: publicar esos puertos y abrirlos en el cortafuegos.

Servidores eD2k: pocos y menguantes; **Kad** (sin servidores) es la vía robusta, y además esquiva el
vector del CVE.

## C. Metalink (`.meta4`, RFC 5854)

Un XML que junta **espejos HTTPS + hashes + el `.torrent`** en un fichero. `aria2c obra.meta4` baja
por HTTPS multi-conexión y BitTorrent a la vez y verifica. Estándar estable, sin demonio, audiencia
pequeña; se emite desde el script de despliegue.

## D. Miradas y descartadas

| Opción | Por qué no, hoy |
| :-- | :-- |
| **IPFS (kubo)** | Las pasarelas públicas `ipfs.io` y `dweb.link` se retiran el 2026-09-21; las sustitutas son *service workers* que exigen JavaScript. Publicar un CID ya no le sirve a quien no tenga nodo. blog.ipfs.tech/2026-08-beyond-sponsored-gateways |
| **Blobs SSB** | Tope de 50 MB por blob [V]: vale para el `.torrent`, no para la obra |
| **blobstore-sidecar de la casa** | Troceo en blobs de 5 MB sobre `ssb-blobs`; escrito y sin desplegar (WP-O50); procesa en memoria. Complementario a futuro, no el camino corto |
| **WebTorrent en el navegador** | Exige JavaScript y trackers WSS; el Teatro es sin JS por diseño |
| **Radicle / Hypercore** | Forja git p2p / sin ecosistema de clientes genéricos: no aplican a blobs grandes |
| **BEP 39 / 46 (torrents mutables)** | Sin adopción real |
| **rtorrent** | Sin semilla web |

## E. Coste comparado

| Escalón | Qué da | Infra nueva |
| :-- | :-- | :-- |
| 0 · artefactos | `.torrent` con semilla web, magnet, enlace ed2k, metalink, fichas | ninguna (una línea de MIME en el edge) |
| 1 · semilla BitTorrent | un peer real; imprescindible si se retira el zip de HTTPS | 1 contenedor (~20 MB RAM), 1 puerto |
| 2 · semilla eD2k/Kad | presencia real en la escena aMule | 1 contenedor, 3 puertos |

Nota operativa: distribuir **contenido propio, firmado y con su ficha** protege frente a quejas de
derechos, no frente a una cuota de tráfico. La del VPS no está documentada [E]: se mide y se pone tope.
