# pack SOLID×MCP — pre-WPs de ronda

Material transversal del Scriptorium (aleph-null.escrivivir.co) para
integrar **Solid** (pods/WebID/LDP) con la circuitería existente
(**MCP · peercard · rooms/L2 · SSB/L1 · node-red**) en o-sdk, z-sdk,
g-sdk o cualquier mundo que lo adopte.

## Qué es (y qué no)

- **Es**: teoría condensada de la ronda 2026-07-28 + pre-WPs con BRIEF/CA
  claros para que cada carril sepa qué encolar (boilerplate, starterkit,
  tablas de mapping) cuando su custodio dé GO.
- **No es**: backlog vivo, ni asientos. **Ninguna dicotomía viene cerrada**;
  hay recomendados ✎ donde la ronda los dio, y criterios de cierre en
  todas.

## Piezas

| fichero | qué contiene |
| ------- | ------------ |
| [`MAPA.md`](MAPA.md) | El territorio completo en 7 olas, anclado a paquetes reales de z-sdk |
| [`TEORIA.md`](TEORIA.md) | Anexo citable §T1–§T10 (DRY: la teoría vive aquí una vez) |
| [`WPS.md`](WPS.md) | Serie WP-SM01…SM24 por olas, prios y dueños **sugeridos** |
| [`DICOTOMIAS.md`](DICOTOMIAS.md) | DIC-1…DIC-7: caminos abiertos con criterio de cierre |
| [`PLAN-PR.md`](PLAN-PR.md) | Destinos, ramas, identidad de commit y mecánica de push |

## Cómo se usa

1. Cada mundo lee `TEORIA.md` (educación de equipo).
2. La mesa/custodio elige qué WP-SM encolar y lo **traduce** a su serie
   local (WP-Onn, Gnn, Unn…) citando §T y DIC en el BRIEF.
3. Las dicotomías se cierran con asiento en el DECISIONES del mundo que
   corresponda, citando `DICOTOMIAS.md`.

Compatibilidad declarada: no contradice D-O1…D-O12 ni H-01; donde roza
doctrina, la cita (D-O2, D-O4, D-O7, D-O8, D-O9, WP-O11/14/15/16/17).

## Estado

Ronda 2 · 2026-07-28 · misión ampliada: «enseñar Solid a los equipos del
Scriptorium para implementarlo desde z-sdk» — mapa abierto entero (olas
A–G, SM17–SM24 nuevos). Ramas espejo preparadas en los tres repos
(`pack/solid-sm-ronda2`, sin push): ver `PLAN-PR.md`.
