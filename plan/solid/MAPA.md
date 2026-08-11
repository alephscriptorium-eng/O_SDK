# MAPA — el territorio Solid × Scriptorium, abierto entero

Ronda 2. Misión fresca: **enseñar Solid a los equipos del Scriptorium en
forma de WPs para que puedan implementarlo desde z-sdk**. El tubo de la
conversación de origen ya no limita: este mapa cubre el territorio
completo, tocado o no en ronda 1.

Anclaje en el z-sdk real (no en abstracto):

| territorio Solid | pieza z-sdk donde aterriza |
| ---------------- | -------------------------- |
| Identidad (WebID, Solid-OIDC, DPoP) | `peer-card` (engine) · `operator-ui` (mesh) · puerta humana |
| Datos (RDF, JSON-LD, vocabularios) | `@zeus/protocol` (DTOs/intents) · `acta-kit` · `story-board-schema` |
| Almacén (Pod, LDP, contenedores) | volumen/ancla (H-01, D-O9) · `volumes-ops` · `blobstore-client` |
| Acceso (WAC/ACP) | capacidades/roles (`jugadores`, features) · zonas (WP-O14) |
| Servidor (CSS 7.x) | molde local (`presets-sdk` env) · co-ubicación con pub (o-sdk) |
| Puentes agente | `player-mcp-kit` · `mcp-launcher` · `http-contract` |
| Eventos | `rooms`/`socket-core` (sala) · Solid Notifications (recurso) · node-red (o-sdk) |
| Sincronía L1⇄pod | `feed-kit`/`firehose-core` · `blob-sync-harness` (¡ya existe el arnés!) |

## Olas (dentro de una ola, lo no dependiente es paralelizable)

```
A FUNDAMENTOS ──► B MOLDE ──► C IDENTIDAD ──► E PUENTES ──► G FEDERACIÓN
      │               │            │                │             ▲
      └──────────► D CONTRATO ─────┴────────► F EVENTOS-ACL ──────┘
```

| ola | qué enseña | WPs | gate de salida |
| --- | ---------- | --- | -------------- |
| **A · FUNDAMENTOS** | vocabulario común, glosario bilingüe Solid↔Zeus, ruta de lectura | SM01 · SM17 · SM24 | un equipo nuevo explica las 6 piezas (§T1) con términos de casa |
| **B · MOLDE** | CSS local sin red, pods sembrados, instancia junto al pub | SM02 · SM04* · SM20 | boot offline PASS con pod por jugador |
| **C · IDENTIDAD** | triple identidad, attestation peercard⇄WebID, login browser, portabilidad | SM03 · SM18 · SM19 · SM14(drill) | drill de portabilidad especificado con CA ejecutable |
| **D · CONTRATO** | vocabularios, @context aditivo, acta como actividad, shapes, hashing | SM04 · SM05 · SM06 · SM13 | mismo payload: DTO válido + RDF expandible + huella intacta |
| **E · PUENTES** | resources←pod, tools→pod, auth relé, traza PROV | SM07 · SM08 · SM09 · SM10 | WP-O11 aplicado al bridge con hostil-omite |
| **F · EVENTOS-ACL** | dos planos de eventos, matriz WAC/ACP, zona≠permiso | SM11 · SM12 | matriz completa con caso hostil por celda |
| **G · FEDERACIÓN** | split autoría/orden, SSB⇄pod harness, descubrimiento, reconstrucción | SM15 · SM16 · SM21 | pod borrado → resembrado desde ancla → huellas idénticas |
| **transversal** | empaquetado (kits) y gobierno de dependencias | SM22 · SM23 | DIC-7 con criterio D-O2 aplicado |

*SM04 aparece en B y D: siembra (B) usa el vocabulario (D); la parte de
seed puede adelantarse con vocabulario provisional marcado.

## Regla de oro del mapa (heredada, no negociable)

**«o-sdk se adapta y crece con z-sdk, no al revés — ninguna abstracción de
infra precede a una pieza real de Zeus»** (D-O2). Traducción a este pack:
ningún `solid-kit` genérico antes de que UNA pieza real (ciudad, operator-ui,
pub) lo consuma. Las olas están ordenadas para que la pieza real llegue
antes que la abstracción.

## Qué es cada WP aquí

Pre-WPs: educan primero, encolan después. Cada mundo los traduce a su
serie (U/O/G/V) citando §T y DIC. Nada se abre sin GO del custodio.
Demolición: el pack es aditivo — ningún WP-SM demuele; quien traduzca,
declare la suya.
