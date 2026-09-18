# 02 · Protocolo de publicidad — anunciar una generación

Cuándo: cada vez que una obra del Teatro se redepliega con un export nuevo (una **generación**).
Quién: el custodio publica; un agente puede preparar el material. Dónde: como **último mensaje del
timeline** de la cuenta fuente, en forma de pantallazo de un banner.

## 0. Principios

1. **Dato sin relato.** El banner es una ficha: cifras, URLs, checksums. Ningún adjetivo que no sea
   comprobable. Lo que la obra significa lo dice la obra («El sistema»), no el anuncio.
2. **Verificable.** Todo banner lleva los **SHA-256 completos** de los zips (64 caracteres, sin
   truncar) y el modo de comprobarlos. Un checksum en una imagen es incómodo de copiar: por eso
   también va en el texto del post o en una respuesta.
3. **El delta se fija.** Todo anuncio dice hasta qué id y qué hora UTC llega la obra. El anuncio
   mismo queda fuera: es el primer post del delta siguiente.
4. **Tres salidas, siempre las tres**: leer (sin JS) · navegar (visor de X) · descargar (offline).
5. **Una llamada.** call4obras / call4cypherpunks: contacto + vía DIY. Sin embudo, sin registro.
6. **Estética de la casa**: B/N sobre papel, Courier, sello y colofón de los medidores
   (Escrivivir · Scriptorium Skins · Animus Iocandi · F.A.R.O. · licencia).

## 1. Secuencia

| # | Paso | Cómo | Hecho cuando |
| :-- | :-- | :-- | :-- |
| 1 | Desplegar la generación | o-sdk: `docs/PUB/TEATRO-PROTOCOL.md` (`lore-import → ingest → fetch → editorial-delta → build → deploy`) | verificación automática verde |
| 2 | Tomar los datos **del servidor** | `curl …/aleph-cero.zip.sha256`, `…-cerebro.zip.sha256`, `curl -sI` (tamaños), `MANIFEST.sha256` (nº de ficheros), portada (cifras) | anotados en `01-ficha-obra.md` |
| 3 | Fijar el delta | último id y hora UTC del export (último post de `cronologia/<mes>.html`) | escrito en la ficha |
| 4 | Actualizar el `dict D` de `banners/make_banners.py` | un solo sitio para todos los datos | `bash banners/render.sh` sin errores |
| 5 | Revisar los PNG | legibles a 1200 px; checksums enteros; URLs sin cortar en mal sitio | — |
| 6 | Elegir post a recitar | `04-hitos-timeline.md`: el último que prometió o anunció el zip | id elegido |
| 7 | Publicar | cita del post elegido + banner + texto de `05-propuestas.md` | URL del post anotada en `04` |
| 8 | Respuesta con los checksums **en texto** | copiar de `01` | — |
| 9 | Anotar el hito | fecha, id del anuncio, banner usado, en `04-hitos-timeline.md` | — |

## 2. Qué debe llevar todo banner (checklist)

- [ ] nombre de la obra y generación (fecha del export)
- [ ] delta: `N anterior → N actual` posts y fecha del corte anterior
- [ ] **dónde queda fijado**: id del último post + hora UTC
- [ ] URL de lectura, URL del visor, nombre de los zips
- [ ] SHA-256 completo de `obra.zip` y `obra-cerebro.zip` + tamaño
- [ ] cómo verificar (`sha256sum -c`; firma ed25519 si cabe)
- [ ] call4obras: `secretaria@escrivivir.co` · asunto `call4obras`
- [ ] vía DIY: solarnethub.com / github.com/epsylon/oasis (oficial) · o-sdk.escrivivir.co (no oficial)
- [ ] colofón de la casa y licencia

## 3. Lo que no se hace

- No truncar checksums ni poner «…».
- No incrustar un **invite** en una imagen: caduca y no se puede copiar. Se da el `connect` y las
  `caps` (estables) y se remite al invite vivo de `pub.escrivivir.co` [V].
- No afirmar cifras de memoria: salen de la portada desplegada o del store.
- No anunciar antes de que la verificación del deploy esté verde.
- No enlazar acortadores ni páginas con rastreadores.

## 4. Textos alternativos (accesibilidad)

El pantallazo se sube con `alt`. Plantilla: «Ficha de la obra Aleph Cero, generación AAAA-MM-DD:
N posts (antes M). Delta fijado en el post ID a las HH:MM UTC. Leer en pub.escrivivir.co/teatro/aleph-cero,
navegar en …/navegador.html, descargar aleph-cero.zip (sha256 …) o aleph-cero-cerebro.zip (sha256 …).
Convocatoria call4obras: secretaria@escrivivir.co.»

## 5. Reutilizar para otra obra

`make_banners.py` no sabe nada de Aleph Cero fuera del `dict D` y del sigilo (`editorial/portada.svg`
de la obra). Otra obra = otro `D` + su SVG. El protocolo es el mismo.
