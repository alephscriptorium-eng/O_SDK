# Dosier PUBLICIDAD Y REDES — anunciar una generación del Teatro

**2026-09-18 · Dosier F4 · departamento de publicidad y redes · datos + protocolo + propuestas**

Qué es: el material para anunciar en RRSS que una obra del Teatro tiene **delta nuevo**, con un primer
trabajo concreto: el anuncio de la generación **2026-09-18** de «Aleph Cero». Sirve para repetir el
anuncio en cada generación sin rehacer nada. Regla de la casa: **dato sin relato**; si un dato de aquí
contradice el servidor, manda el servidor.

## Leyenda

- **[V]** comprobado en esta sesión contra producción (`curl`) o contra el store del lore.
- **[C]** dicho por el custodio.
- **[NV]** no verificado.
- `<pendiente>` decisión o dato que falta.

## Mapa de ficheros

| Fichero | Contenido |
| :-- | :-- |
| `01-ficha-obra.md` | Ficha de «Aleph Cero» gen. 2026-09-18: cifras, URLs, **checksums**, firma, comandos de verificación |
| `02-protocolo-publicidad.md` | **El protocolo**: qué se anuncia, cuándo, con qué datos, cómo se fija el delta respecto del timeline, checklist |
| `03-call4obras.md` | La convocatoria: acogida en el pub, vía DIY (oficial y o-sdk), datos de federación del pub |
| `04-hitos-timeline.md` | Los anuncios anteriores en X (ids y fechas) y cuál recitar para el «update» |
| `05-propuestas.md` | Las 5 propuestas de banner, para qué sirve cada una y el texto del post |
| `banners/` | `banner-0N-*.html` (autocontenidos), `png/` (1200 px), `make_banners.py` (datos en un solo `dict`), `render.sh` |

## Hacia dónde apunta la obra (por qué se anuncia así)

Los otros dosieres de F4 describen la red de la casa: el modelador de redes y sus modelos
(`../dosier-colectivizaciones`, `../dosier-res-publica`), el pub y su capa L2 (`../dosier-aleph-net/02`),
el hub a la web abierta (`../oasis-clearweb`), la economía (`../dosier-oasis-faircoin`) y el ensayo que
los lee (`../dosier-relacional`). «Aleph Cero» es el **manual o e-libro de cobertura** de todo eso: su
puerta «El sistema» tiene un constructo por cada pieza —Modelador de redes, Pubs Oasis/SSB, ClearNet
Hub, Scriptorium, Animus Iocandi, F.A.R.O.— con el post en que nace cada una [V]. Por eso el anuncio
no vende un archivo: enseña que **un archivo es una obra**, que la obra corre sobre infraestructura
propia y replicable, y que esa infraestructura admite más obras y más pubs (`03-call4obras.md`).

## Estado

- Generación 2026-09-18 en producción, verificada [V]. Checksums en `01`.
- Post a recitar localizado [V]: `04`.
- 5 banners renderizados [V]: `banners/png/`.
- El custodio se queda con los banners 1-4 [C]; publica él (pantallazo como último mensaje del timeline).
