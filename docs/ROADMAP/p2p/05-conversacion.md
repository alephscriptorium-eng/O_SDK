# 05 · El hilo — qué se preguntó, qué se corrigió, qué se decidió

Sesión del 2026-09-19. Las frases del custodio van entre «…» [C].

## 1. El encargo

> «Se trata de un plan para agregarle a o-sdk la forma más fácil de servir los zips nuestros
> (debidamente etiquetados con su checksum y fuentes de origen a nuestro teatro) en semillas para la
> escena p2p. Seguro para mundo amule (que han sacado en 2026 la versión 3 y parece la escena se
> mueve). Tú decides balance de qué infra metemos para poder servir nuestra semilla. Al final todo debe
> ir paralelo al teatro (servir obras, y agregar a los modos de visita actuales las fichas
> correspondientes para p2p).»

Condición: solo lectura sobre o-sdk mientras otros trabajaban en él.

## 2. Lo que se miró (tres exploraciones en paralelo)

- **o-sdk**: cómo se generan y firman los zips, qué admiten las guardas, el patrón de servicio
  opcional, el trabajo en curso de otros. → `04`.
- **s-sdk**: qué es de cada mundo en el VPS y qué reglas hay para añadir un servicio. No hay en la casa
  ningún precedente de distribución p2p de ficheros: es vocabulario nuevo.
- **La escena en 2026**: el custodio acertaba con aMule 3. → `02`.

## 3. Primera propuesta del editor, y por qué no valía

Tres escalones (artefactos sin demonio · semilla BitTorrent · semilla aMule) presentados como elección,
con avisos sobre RAM, disco y cuota. El custodio pidió aclarar antes de elegir.

## 4. Aclaraciones

**«El pub usa torrent web de Oasis (puedes explicar bien en qué consiste eso). Entonces, abrimos el
cliente de o-sdk, mi cuenta aleph y lo sirvo dejando mi máquina encendida?»**
Se leyó el código: el módulo Torrents es un **catálogo** (mensaje SSB + blob `.torrent`), sin ninguna
librería BitTorrent. Dejar Oasis encendido replica el anuncio, no sirve la obra. → `01`.

**«Ya que tengo mi zip en el vps, no veo por qué no puedo tener una semilla permanente para ayudar a
crecer a la red.»**
Ya la tiene: el HTTPS del pub, declarado como semilla web en el torrent, es una fuente permanente de
BitTorrent sin demonio. Para aMule sí hace falta `amuled`, porque ignora las fuentes HTTP.

**«Ese formato es de timeline… aparecen nuevos fragmentos para append. Pero no hay edit.»**
Cierto para el contenido de la obra; el contenedor zip cambia entero en cada generación, y BitTorrent
hashea bytes: de ahí la URL inmutable por generación. La intuición abre la mejora siguiente —paquetes
delta, porque la media solo crece—, anotada fuera de este trabajo.

## 5. La corrección de rumbo

> «Tampoco me has mirado la parte de teatro que tiene obras. Al fin el objetivo del pub es servir de
> hub… si hay que soportar algunas obras al principio pues tiene que haber protocolo en o-sdk, pero
> vaya que una vez que una obra está en la red p2p ya no hay que estar soportándolo. Así que igual
> puede estar el zip descargable por ejemplo cuando está en "cartelera" y simplemente agregamos un
> setting que permita moderar el uso de hardware habilitando o retirando… es decir, soluciones, no
> pegas.»

De ahí sale el modelo: **cartelera** como ciclo de vida por obra, ajustes de hardware por variable de
entorno, y un comando para pasar de estado. Las cautelas sobre recursos dejan de ser objeciones y pasan
a ser **valores de un ajuste** que se fijan midiendo. Consecuencia técnica: si el zip puede retirarse de
HTTPS, la semilla web muere con él, así que la semilla BitTorrent real deja de ser opcional en el diseño.

## 6. Decisiones

| Decisión | Quién |
| :-- | :-- |
| Multi-obra y genérico: protocolo en o-sdk, datos de Scriptorium en su ficha | custodio |
| Cartelera (`cartelera` · `red` · `retirada`) y ajustes para moderar hardware | custodio |
| Semilla permanente en el VPS, sin esperar al servidor perfecto | custodio |
| Artefactos por generación inmutable; vigente = enlace duro; retener 1 anterior por defecto | editor |
| aMule 3.0.1 por imagen fijada, Kad-only; no el paquete 2.3.3 de Debian | editor |
| Stack de semillas independiente del compose del pub | editor |
| Herramientas en contenedor efímero, nada instalado en el host | editor |
| Anuncio en el módulo Torrents de Oasis: manual, con GO y texto aprobado | editor |
| Descartados: IPFS, WebTorrent, blobs SSB para el contenido, torrents mutables | editor |
| Plan WP-O110: aprobado, se guarda verbatim (`06`) | custodio |
| Este dosier, con el soporte nativo de Oasis primero y la extensión después | custodio |
