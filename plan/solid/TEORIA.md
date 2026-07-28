# TEORIA — anexo del pack SOLID×MCP (citable, no normativo)

Régimen: material de educación de carril. **Aquí no se decide nada**: donde
hay camino doble, se remite a [`DICOTOMIAS.md`](DICOTOMIAS.md). Los WPs del
pack citan estas secciones por ancla (§T*n*) — la teoría vive UNA vez
(don't repeat yourself).

Fuente: ronda de estudio 2026-07-28 (custodio + IA de estación) contra
código real de `Z_SDK-games-library/packages/ciudad` y `O_SDK/plan`.

---

## §T1 · Las seis piezas de Solid

Solid (Berners-Lee) invierte quién manda sobre los datos: la app pide
permiso a un almacén del usuario, no al revés. Vocabulario mínimo:

1. **WebID** — identidad = URL dereferenciable que devuelve un perfil RDF.
2. **Pod** — almacén personal de recursos en contenedores (LDP).
3. **Solid-OIDC** — login: OpenID Connect adaptado, tokens ligados con DPoP.
4. **RDF** — modelo de tripletas sujeto→predicado→objeto; serializable en
   Turtle, **JSON-LD**, N-Triples (el servidor negocia por contenido).
5. **LDP** — lectura/escritura por HTTP puro: GET/PUT/POST/DELETE/PATCH.
6. **WAC / ACP** — control de acceso por recurso (read/write/append/control)
   concedido a WebIDs, grupos o público. (Elección WAC vs ACP: DIC-3.)

Implementación de referencia FOSS servidor: **Community Solid Server (CSS)
7.x**, TypeScript. Cliente TS: `@inrupt/solid-client`,
`@inrupt/solid-client-authn-browser` / `-node`.

## §T2 · El pod como volumen (encaje con D-O9)

Doctrina ya asentada en carril O: *«el ancla ALIMENTA al volumen; no lo
sustituye; el runtime solo lee el volumen»* (D-O9). Encaje propuesto:

- **SSB feed (L1)** = el libro: append-only, firmado, historia.
- **Pod** = el volumen/vista: estado consultable por HTTP/RDF con ACL.
- El ancla (L1/L2) **siembra y sincroniza** el pod; el cerco (D-O8) sigue
  en pie: nada de anclas vivas en el arranque.

**No-dicotomía reconocida** (corrección del custodio en ronda): el pod no
es «o proyección o fuente de escritura». Es **ambas, por zona**: fuente
directa donde el jugador es autor (perfil, intents firmados) y proyección
donde el estado viene reconciliado (ciudad, censo). Ver §T7 y DIC-5.

## §T3 · Vocabularios: reúso por capas

En RDF no se hace un vocabulario entero desde cero ni se reusa uno solo.
Tres capas:

1. **Reúso estándar** para lo genérico:
   - Perfil/identidad → FOAF + vCard + `solid:`
   - Acciones sociales/federación → **ActivityStreams 2.0** (as:Announce,
     as:Offer, as:Join — mapea casi 1:1 a 🐰/🐴/federar)
   - Procedencia/traza → **PROV-O** (alimenta WP-O16)
   - Metadato de unidades selladas → **DCTERMS**
   - Políticas de uso → ODRL
2. **Namespace propio** (`z-sdk#` o el que la mesa acuñe) SOLO para el
   dominio real: barrio, zona, acta, estados vivos, peercard, ronda.
3. **Alineación**: `rdfs:subClassOf` / `subPropertyOf` de la capa propia a
   la estándar (interop sin dependencia).

Gobierno vs copyleft (los dos criterios de D-O3 tiran en direcciones
opuestas aquí): tier W3C Rec/DCMI = fundación + proceso abierto; schema.org
= CC BY-SA (copyleft real) pero gobernado por cuatro corporaciones. Matiz
resolutorio: **usar** URIs ajenas es libre en todos; la licencia solo
muerde al **forkear/republicar** la definición. Elección de backbone:
DIC-2. Anti-autoridad del namespace propio: publicarlo dereferenciable,
versionado y **con hash** — un término se cree por el hash, no por quién
lo sirve (WP-O15 aplicado a la semántica).

## §T4 · JSON-LD y hashing: la trampa de la canonicidad

JSON-LD es serialización RDF de primera y vale como DTO+RDF a la vez vía
`@context`. Trampa: **JSON-LD no es canónico** — dos documentos
equivalentes pueden dar bytes distintos → hashes distintos → rompe
content-addressing (D-O9 «hash por pieza», WP-O15 «se cree por el hash»).

Dos salidas limpias (elección por familia: DIC-4):
- **Hash de bytes sellados**: el hash es del snapshot tal cual; el RDF es
  vista de lectura. Es lo que `huellaLedger` de ciudad **ya hace**
  (`sha256(JSON.stringify(evento))`).
- **Hash de grafo**: canonicalizar con **RDFC-1.0** (ex URDNA2015) antes de
  hashear; estable sobre significado, costoso; solo donde haga falta
  igualdad semántica entre fuentes distintas (p.ej. reconciliación).

Regla práctica citada en ronda: bytes por defecto; RDFC-1.0 quirúrgico.
Al «RDFizar» actas, no romper el hash de bytes existente.

## §T5 · MCP ↔ Solid: la misma URI con tres sombreros

Un recurso MCP se identifica por URI; un recurso Solid es una URL; un nodo
RDF es una URI. Puentes:

1. **Resources ← pod**: `resources/read` = GET autenticado a LDP;
   passthrough de URI y mimeType; el pod ya sirve JSON-LD → el recurso MCP
   llega como tripletas.
2. **Tools → pod/L2**: `tools/call` escribe (PATCH/PUT) o despacha a L2.
   El spec MCP (RC 2026-07-28) da **output schema JSON Schema 2020-12**:
   añadir `@context` al schema hace la E/S del tool RDF sin duplicar
   contrato.
3. **Auth = relé, no autoridad**: MCP se alinea con OAuth2/OIDC (issuer
   validation, RFC 9207) → el token Solid-OIDC (o peercard) del jugador
   cabalga el transporte; **decide el pod (WAC/ACP), el servidor MCP solo
   releva**. Un token-dios del bridge sobre todos los pods viola
   CA-ANTI-AUTORIDAD de forma exacta (WP-O11.3/.4, D-O7).

Anti-patrón señalado: **tool ≠ predicado**. Un predicado es relación
declarativa; un tool es acción con argumentos, efectos y fallo. Colapsarlos
mezcla estado con comportamiento. Forma correcta: §T6.

Regalo del RC: **W3C Trace Context** en metadato de llamada — atado al
nodo-actividad PROV es la traza de WP-O16 (`traceparent` = hilo de
procedencia).

## §T6 · El acta como nodo-actividad (estrella, no tripleta)

Una invocación no se modela como una tripleta sino como un **nodo
actividad** con una estrella de aristas (PROV-O / AS2):

```turtle
<…/actas/plaza-centro#t812> a prov:Activity, zsdk:ActaDeBarrio ;
    zsdk:viaTool      <…/tool/wake#v0.1> ;     # intent como recurso versionado+hash
    zsdk:barrio       <…/barrio/plaza-centro> ;
    zsdk:estado       "vivo" ;                  # vivo|latente|muerto|roto
    zsdk:ultimaClase  "residente" ;             # residente|visitante|flujo
    prov:wasAssociatedWith <WebID del actor> ;
    zsdk:tickEmision  812 ;
    zsdk:huellaLedger "sha256:…" .              # la huella existente, intacta
```

`ActaDeBarrio v1` (`packages/ciudad/src/acta.mjs`) ya contiene todo lo
necesario: el mapeo es **tabla de correspondencia, no refactor**. Los cinco
intents (join/walk/announce/wake/sleep) son los verbos; `resumen` y
`pendientes` van como literales; el ledger `kind:'acta'` es el log que
ancla a L1.

## §T7 · Autoría vs orden (la costura dura)

El juego necesita **orden total** (tick, decay, objetivo colectivo) y hoy
lo da *una* autoridad por room («límite actual del engine»,
`authority.mjs`). Descentralizar identidad NO descentraliza la simulación.
Separación conceptual:

- **Autoría** (descentralizada): el intent lo firma el actor (peercard) y
  puede vivir en su pod — pod como fuente de escritura.
- **Orden** (secuenciado): la autoridad **no fabrica** actas; las ordena en
  el ledger ancladas por huella al intent firmado — pod como proyección.

Consecuencia anti-autoridad: la autoridad queda como relé-secuenciador
(WP-O11: ningún relay reescribe payload); no puede forjar intents porque no
puede falsificar la peercard. Diseño de detalle: pre-WP de mesa (WP-SM15).

## §T8 · Dos planos de eventos — no fusionar

- **Eventos de sala/juego (L2)**: socket.io, efímeros, tick-rate.
- **Cambios de recurso del pod**: Solid **Notifications Protocol**
  (WebSocketChannel2023 / webhooks), soportado por CSS.

Puente en node-red si hace falta, pero cada plano con su semántica. Si se
fusionan, node-red acaba de fuente de verdad de cambios de dato — la
confusión exacta que D-O9 evita.

## §T9 · Identidad triple: WebID ↔ peercard ↔ ssbId

Tres identidades coexisten en el Scriptorium: WebID (Solid), peercard
(Zeus, ya con dos tipos: humano-puerta y agente-MCP, seats distintos) y
ssbId (L1). No se ha decidido jerarquía ni fusión — y quizá no deba
haberla: son **contextos de autoridad** distintos (D-O7: la card emite por
contexto, no por nivel). Punto caliente: si un CSS central es el IdP de
todos los WebIDs, esa posición es poder sobre otros (CA-ANTI-AUTORIDAD).
Salida estándar de Solid: el WebID es **portable** (migración pod+IdP con
identidad superviviente). Elección de topología IdP: DIC-1. El molde manda:
CSS es *un* IdP, no *el* IdP.

## §T10 · Lo NO tocado en la ronda (huecos honestos)

Temas que la ronda no cubrió y que algún WP debe abrir antes de v1:

- **Shapes** (SHACL / ShEx) como validación ejecutable del contrato RDF —
  el gemelo semántico del JSON Schema que ya se usa.
- **Solid-OIDC + DPoP en el cliente Angular** — flujo completo de login en
  navegador, refresh, logout, multi-pod.
- **Descubrimiento** — type indexes / perfiles públicos: cómo una app
  encuentra dónde escribe cada cosa en un pod ajeno.
- **Drill de portabilidad** — migrar un pod+IdP de verdad y que el jugador
  sobreviva (la prueba de que DIC-1 no es teatro).
- **Coste real de RDFC-1.0** — medir antes de prometer (DIC-4).
- **Versionado/backup del pod** — el pod muta; el libro es L1; ¿qué
  garantiza reconstrucción pod-desde-ancla?

---

*Material educativo del pack. Se supera con asientos que lo citen.*
