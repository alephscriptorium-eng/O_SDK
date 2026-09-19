# Dosier P2P — sacar las obras del Teatro a la escena p2p

**2026-09-19 · Dosier F4 · exploración + opciones + plan · plan aprobado por el custodio, sin ejecutar**

Qué es: lo que se miró, se explicó y se decidió al preguntar *«¿cuál es la forma más fácil de servir
nuestros zips como semillas para la escena p2p, en paralelo al Teatro?»*. Primero caracteriza **lo que
Oasis ya trae de fábrica** para torrents; después, **lo que nuestro pub añade encima**, para que la
gente de Oasis vea por dónde extendemos desde su upstream sin tocar su código.

## Leyenda

- **[V]** leído directamente en esta sesión (fichero abierto o comando ejecutado).
- **[E]** reportado por una exploración con fuente (`repo/fichero:línea` o URL); no cotejado a mano.
- **[C]** dicho por el custodio.
- **[NV]** no verificado.
- `pendiente` dato o decisión que falta.

Base de código: o-sdk `main` en `74d5c6a` (2026-09-19), con `src/` = **Oasis 1.1.4** más 5 guards.

## Mapa de ficheros

| Fichero | Contenido |
| :-- | :-- |
| `01-oasis-nativo.md` | **Lo que Oasis ya hace**: el módulo Torrents, el mensaje SSB `torrent`, el blob, el HUB clearnet, límites. Y lo que no hace |
| `02-opciones.md` | Las opciones miradas: BitTorrent con semilla web, eD2k/Kad con aMule 3, metalink, IPFS y otras; herramientas; qué se descarta y por qué |
| `03-extension-pub.md` | **Lo que añade nuestro pub**: artefactos por generación, fichas en el Teatro, semillas opcionales, cartelera. Tabla upstream → extensión. Ideas que podrían subir a upstream |
| `04-infra-y-reglas.md` | El VPS y las reglas de la casa que condicionan el diseño (recursos, puertos, patrón de servicio opcional, irreversibles) |
| `05-conversacion.md` | El hilo: qué se preguntó, qué se corrigió, qué se decidió y por qué |
| `06-plan-wp-o110.md` | El plan aprobado, verbatim |

## En una página

1. **Oasis anuncia torrents; no los siembra.** Su módulo Torrents es un catálogo: un mensaje SSB de
   tipo `torrent` con el fichero `.torrent` como blob. No lleva ninguna librería BitTorrent. → `01`.
2. **El pub ya es una semilla BitTorrent sin saberlo.** El zip se sirve por HTTPS con `Range`; un
   `.torrent` con *semilla web* (BEP 19) convierte esa URL en fuente permanente sin ningún demonio. → `02`.
3. **Para la escena aMule sí hace falta un demonio**: aMule ignora las fuentes HTTP de los enlaces
   ed2k. aMule 3.0.1 (junio de 2026) trae `amuled` y hay imagen Docker mantenida. → `02`.
4. **El pub es un hub, no un almacén**: una obra se sostiene mientras está **en cartelera**; cuando ya
   vive en la red, se retira el soporte con un comando. Eso es lo que modera el hardware. → `03`.
5. Todo cuelga de la **raíz de confianza que el Teatro ya tiene** (sha256 + firma ed25519 +
   manifiesto): un torrent o un enlace ed2k son solo otro camino hacia los mismos bytes verificables.

## Estado

- Plan WP-O110 aprobado [C]; ejecución pendiente de abrir la rama.
- `pendiente` medir el tráfico saliente real del VPS antes de fijar el tope de subida de las semillas
  (no hay dato de cuota en ningún repo de la casa [E]).
- Siguiente paso anotado, fuera de este WP: paquetes delta por generación (la media de una obra solo crece).
