# 05 · Propuestas — seis banners y el texto del post

Todos: 1200 px de ancho, B/N sobre papel, Courier, colofón de la casa, **checksums completos**,
delta fijado, tres salidas y call4obras. HTML en `banners/`, PNG en `banners/png/`. Datos: un solo
`dict` en `banners/make_banners.py`; regenerar con `bash banners/render.sh`.

| # | Fichero | Idea | Cuándo usarlo |
| :-- | :-- | :-- | :-- |
| 1 | `banner-01-ficha` | **La ficha.** Cifras, tabla técnica, checksums, verificación, llamada. Lo más «dato» | **Recomendado** para el anuncio: es el que mejor aguanta como último mensaje fijo del timeline |
| 2 | `banner-02-delta` | **El diff.** `+490 posts`, `+553 media`… y una caja negra con la hora y el id donde queda fijado el delta | Si lo que se quiere subrayar es el «update» sobre el zip anterior (encaja con recitar la promesa del 11-sep) |
| 3 | `banner-03-tres-puertas` | **Tres maneras de entrar**: leer sin JS · navegar con el visor de X · llevárselo offline | Para quien llega de nuevas y no sabe qué es el Teatro |
| 4 | `banner-04-call4obras` | **«Tu archivo es una obra».** Aleph Cero como prueba; vía A (te acogemos), vía B (DIY oficial + o-sdk), federar (connect + caps) | Segundo post, o respuesta al primero: la convocatoria |
| 5 | `banner-05-terminal` | **«No te fíes: comprueba».** Sesión de terminal en negro: `curl`, `sha256sum -c`, `ssh-keygen -Y verify`, `ls` de la obra | call4cypherpunks; para público técnico |
| 6 | `banner-06-p2p` | **La obra sale a la red** (2026-09-19). Edición **congelada**; cuatro caminos: torrent con semilla web · eD2k/Kad · metalink · anuncio en Oasis; infohash y hash ed2k de cada fichero, checksums, «el pub es un hub, no un almacén» | Anuncio de la vía P2P: como post propio o como respuesta al anuncio de la obra. Datos de `p2p.json` |

Combinación sugerida: **1 (o 2) como anuncio**, **4 como respuesta** con la convocatoria, y una
segunda respuesta con los checksums en texto.

## Texto del post (dato, sin relato)

**Anuncio** (citando `2098506086038868372`):

```
Hecho. Aleph Cero · generación 2026-09-18
1454 → 1940 posts. Delta fijado en 2100802059889000553 (04:20 UTC).
Leer (sin JS): pub.escrivivir.co/teatro/aleph-cero/
Navegar: …/aleph-cero/navegador.html
Offline: aleph-cero.zip (1,52 GiB) · aleph-cero-cerebro.zip (33 MiB)
Checksums 👇
```

**Respuesta 1 — checksums en texto** (para copiar):

```
sha256
39d726c8bdad2c5a9c9c789ae1b92cc25ca3403615b28c2bc947e85dff1b2c1d  aleph-cero.zip
634feaf422054ce911ceb52168a987aa527f5f0eb9cbcbf6a936e65ec95c24bf  aleph-cero-cerebro.zip
Firma ed25519 (teatro@escrivivir.co) y MANIFEST.sha256 junto a los zips.
```

**Respuesta 2 — call4obras** (con `banner-04`):

```
#call4obras Aleph Cero es una obra. Tu archivo también puede serlo.
A) Te acogemos: secretaria@escrivivir.co · asunto: call4obras
B) DIY: solarnethub.com · github.com/epsylon/oasis · o-sdk.escrivivir.co (wrapper no oficial)
Y federamos: connect + invite en pub.escrivivir.co
```

## `alt` del pantallazo

Plantilla en `02-protocolo-publicidad.md` §4. Para el banner 1:

> Ficha de la obra Aleph Cero, generación 2026-09-18: 1940 posts (antes 1454), 1844 media, 259 hilos,
> 891 voces ajenas, 331 enlaces en Markdown, 38 conversaciones con agentes, 22 constructos. Delta
> fijado en el post 2100802059889000553, 04:20 UTC. Leer en pub.escrivivir.co/teatro/aleph-cero,
> navegar en navegador.html, descargar aleph-cero.zip o aleph-cero-cerebro.zip; checksums en la
> respuesta. Convocatoria call4obras: secretaria@escrivivir.co.

## Antes de publicar

`curl -s https://pub.escrivivir.co/teatro/aleph-cero/aleph-cero.zip.sha256` y comparar con el banner:
si hubo un redeploy entre medias, el hash cambió → actualizar `D` y `bash banners/render.sh`.
