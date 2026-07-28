# DICOTOMIAS — registro de caminos abiertos (pack SOLID×MCP)

Esto NO son asientos de decisión. Es el inverso: caminos deliberadamente
**abiertos**, con criterios para decidir cuando toque y, donde procede, un
recomendado ✎ (recomendación ≠ decisión; decide el custodio/mesa de cada
mundo). Regla de la ronda: no aplanar falsas dicotomías — si la respuesta
buena es «ambas, por partes», se registra así.

| id | pregunta | opciones | criterio de cierre | recomendado ✎ |
| -- | -------- | -------- | ------------------ | ------------- |
| **DIC-1** | Topología de IdP para WebIDs de jugadores | (a) CSS del pub como IdP común · (b) IdP por jugador/portable · (c) común de arranque + drill de migración garantizado | CA-ANTI-AUTORIDAD ejecutable: ¿puede un jugador irse sin perder identidad? (drill §T10) | ✎ (c): pragmático sin volverse poder |
| **DIC-2** | Backbone de vocabulario | (a) tier W3C Rec + DCMI (AS2/PROV-O/DCTERMS…) · (b) schema.org · (c) mixto con schema.org solo suplementario | criterio D-O3 (gobierno) vs necesidad real de forkear definiciones (§T3) | ✎ (c) con backbone (a) |
| **DIC-3** | Control de acceso en CSS | (a) WAC (ACL clásico) · (b) ACP | expresividad requerida por zonas/roles de ciudad vs simplicidad; invariante WP-O14: la zona no deriva permiso — vale igual en ambas | — (falta matriz de casos; abrir con WP-SM12) |
| **DIC-4** | Unidad de hash al RDFizar | (a) bytes sellados (statu quo `huellaLedger`) · (b) RDFC-1.0 sobre grafo · (c) por familia: bytes por defecto, RDFC quirúrgico | dónde se necesita igualdad semántica entre fuentes distintas + coste medido (§T4, §T10) | ✎ (c); jamás romper huellas existentes |
| **DIC-5** | Rol del pod por zona | ~~proyección XOR fuente~~ — **falsa dicotomía reconocida**: ambas, por zona (§T2, §T7) | tabla zona→rol por juego/mundo; se cierra por zona, no global | ✎ tabla explícita zona→rol como entregable |
| **DIC-6** | Dónde vive el bridge MCP↔Solid | (a) en o-sdk (superficie del nodo) · (b) en z-sdk (kit `@zeus/*` reusable) · (c) kit en z-sdk + instancia en o-sdk | regla D-O2: o-sdk se adapta y crece con z-sdk, no al revés — ninguna abstracción de infra precede a una pieza real de Zeus | ✎ (c) si y solo si ya existe la pieza real que lo consume |
| **DIC-7** | Empaquetado del código Solid en z-sdk | (a) extender kits existentes (`player-mcp-kit`, `acta-kit`, `http-contract`) · (b) kits nuevos (`solid-kit`, `webid-kit`) · (c) extender primero, extraer kit cuando haya 2+ consumidores reales | inventario WP-SM22: tabla WP→destino con pieza consumidora nombrada; frontera de publish (allowlist) vigente | ✎ (c): la extracción sigue al uso, no lo precede |

Una dicotomía se cierra con asiento en el DECISIONES del mundo que
corresponda, citando este registro como material.
