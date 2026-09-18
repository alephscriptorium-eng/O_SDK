# 05 — Dualidades que la propia red encarna (foco: contraejemplos)

Leyenda: [V] leído · [E] reportado por exploración, sin cotejo · [NV] · `<pendiente>`. Ver `00-indice.md`.

Propósito: la tercera pata de `../dosier-relacional/contraejemplos/`.
`dualidad.md` lista dualidades de sapiens 2026; `tabla.md` mide cuánto las
bloquea el ensayo. Aquí: **qué dualidades tiene escritas nuestra red en su
código y su doctrina**, para contrastar el ensayo con lo que tenemos, no solo
con lo que se piensa fuera.

Columna «Cómo la trata la red», vocabulario fijo:
- **sustancial** — frontera dura, tipada o cableada (no hay gradiente).
- **gradiente** — continuo con umbral configurable o por opt-in.
- **rito** — la frontera se cruza solo por un verbo explícito (ceremonia).
- **convención** — declarada en doctrina, sin gate que la haga cumplir.

Columna «Tesis del ensayo» → ids de `06-elementos-diseno-ensayo.md` (D1–D16)
y tesis T1–T6. Última columna: se rellena solo donde el dato lo impone; el
juicio es trabajo de contraejemplos y queda `<pendiente>`.

## Tabla

| # | Dualidad en la red | Categoría | Dónde (fichero:línea) | Cómo la trata la red | Tesis del ensayo que la toca | ¿Contraejemplo o confirmación? |
|---|---|---|---|---|---|---|
| R1 | **L1 / L2** — «L1 = ∞, L2 = sesión»; pub que no se apaga vs. ciudades volátiles | topológica | `scriptorium/plan/VISION.md:10-16` [E]; `o-sdk\plan\BACKLOG.md:36-37,409-416` [E] | **sustancial + rito**: nada de la sala escribe directo al pub; retorno solo por cristalización explícita (WP-O51 «un solo verbo de entrada a L1», `BACKLOG.md:552-557`) | D8 (commit = cristalización provisional), D11 (metabolismo), §2.1 interior/exterior como gradiente | candidato a **contraejemplo** de §2.1 (la red hace frontera dura donde el ensayo pide continuum) y a **confirmación** de D8 (cristalización explícita) — `<pendiente>` |
| R2 | **Lectura / escritura** — HUB clearnet GET-only (403/405 a todo no-GET) vs. cliente que escribe | topológica / política | `docs\PUB\HUB-PROTOCOL.md:56-58`, `pub\caddy\Caddyfile:18`, `hub-cache` 405 [E] | **sustancial**: segunda cuenta SSB sin `ports`, solo `/c` | D9 (interfaz enactiva: «el usuario no consume información sino que piensa-haciendo») | candidato a **contraejemplo** de D9 en el tramo clearnet — `<pendiente>` |
| R3 | **Interior / exterior del habitante** — opt-in de visibilidad que viaja con el feed; el HUB «no decide quién aparece y no se lista a sí mismo» | ontológica | `docs\PUB\clearnet.md:20-36`; `src\views\main_views.js:2436-2449`; `HUB-PROTOCOL.md:71-73` [E] | **gradiente por opt-in**: `visibilityPrefs.clearnet*` por módulo | §2.1 «cada nodo es simultáneamente privado y público»; D16 (qué hacer visible es ético-político) | candidato a **confirmación** de §2.1 como gradiente de intimidad — `<pendiente>` |
| R4 | **Permiso / transporte** — «el permiso no gobierna el transporte»: fail-closed en capacidades, fail-open en topología (D-O7); transporte base ≠ capacidad WebRTC (D-O11) | política | `o-sdk\plan\DECISIONES.md:48-53, 85-92` [E] | **sustancial** (dos regímenes separados por diseño) | D14 (libertad técnica/política), §2.5 descentralizado ≠ distribuido | `<pendiente>` |
| R5 | **Ámbito / autoridad** — `CA-ANTI-AUTORIDAD`: «el grafo NO declara jerarquía de autoridad — declara ámbitos»; WP-O14 «zona = alcance, no ubicación; ningún permiso se deriva de la zona» | política | `DECISIONES.md:41-46`; `BACKLOG.md:136-145, 169-175` [E] | **convención con gate** (WP-O11, 5 puntos) | T6 ética inmanente; §2.5 rizoma «sin jerarquía estructural»; D2 (zonas solapables ≈ hiperaristas de alcance) | candidato a **confirmación** de §2.5 — `<pendiente>` |
| R6 | **Invite (L1) / peercard (L2)** — se emiten por caminos separados; en m-sdk el «invite» es un rótulo de texto | identitaria | `o-sdk\MAPA.md:136-139`, `PLAN.md:246`; `m-sdk sala-things.ts:560-573` [E] | **sustancial** en o-sdk; **ausente** en m-sdk (modo `card` sin cablear, `DEUDA.md:4`) | D6 (grafos situados que interoperan), D14 | `<pendiente>` |
| R7 | **Atlas / taller** — «El atlas apunta; el LAB construye»; gitlinks solo lectura; bump solo con GO | operativa | `scriptorium/plan/MAPA-TALLER.md:12-16` [E]; `../dosier-relacional/02-croquis.md:9-23` [V] | **sustancial + rito** (GO del custodio, DA-S11) | D8 (cristalización), DS-5 «apuntar, no contener» | `<pendiente>` |
| R8 | **Memoria / codebase** — «memoria = arena, codebase = piedra»; «si discrepan, la codebase es la verdad» | epistémica | `s-sdk/LLM.md:8-27` [V] | **sustancial** (regla capital) | D11 (documentación como metabolismo), D13 (`<pendiente>` = meta-ignorancia declarada) | candidato a **confirmación** de D13 y **contraejemplo** parcial de D11 (la verdad se fija en piedra) — `<pendiente>` |
| R9 | **Ceguera ascendente / acceso descendente** — un holón no concibe a su sucesor; el sucesor relee a los anteriores | ontológica / histórica | `s-sdk\DEVOPS\METODOLOGIA\HOLONES.md:5-8` [V] | **sustancial** (ley de la cadena); crece solo por junturas | §2.2 niveles lógicos de Bateson, strange loops (holón 07 «se descubrió siendo él mismo un holón», `:28-30`); T4 devenir | candidato a **confirmación** de §2.2 (autorreferencia) — `<pendiente>` |
| R10 | **Primitiva / proyección** — exactamente 5 primitivas; «todo lo demás es proyección»; `Grafo` es una clase de `Artifact` | ontológica | `lore-hm\README.md:40-49` [V]; `src\projections.ts:9-17,34-37` [V]; `primitives.ts:71-79` [E] | **sustancial** (conteo = 5 con gate) | D3 (proyecciones múltiples de un mismo sustrato); §3.3 «ambos y ninguno» | candidato a **confirmación** de D3 en doctrina, con la salvedad de que aquí «proyección» es clase, no filtro — `<pendiente>` |
| R11 | **H / M** — «roles/capacidades, no tipos de ser»; `Peer.roles: 'H'\|'M'\|'observer'` | ontológica | `lore-hm\README.md:42` [V]; `primitives.ts:29` [E] | **gradiente** (un peer puede tener varios roles) | T1 (entidad = patrón de relaciones); §2.1 | candidato a **confirmación** de T1 — `<pendiente>`. Eco directo de `dualidad.md` «mente/cerebro» y «Yo» (Popper): la red no reconoce un «Yo» distinto por sustrato |
| R12 | **Humano / agente** — «Ningún jugador privilegiado»: humano con credencial federada, agente por MCP con la misma tarjeta firmada, residente autómata | política / ontológica | `scriptorium/docs/ciudad.md:21-28` [E] | **convención** (contrato público) | T6; §6.1 transindividual | `<pendiente>`. Contrasta con `dualidad.md` fila Popper («la máquina carece de Yo») |
| R13 | **Nodo / arista** (modelador) — nodo puro que no cita a otro nodo; arista entre exactamente dos, que nunca reescribe a sus nodos | ontológica | `modelador-redes\llms.md:24-25` [V]; `catalogo.py:105` [E] | **sustancial** (cardinalidad 2 cableada) + **convención** (pureza sin gate, `6de31f6`) | T2 (n-arias irreductibles), D2, T1 | **contraejemplo** de T2 impuesto por el dato: el catálogo solo admite binarias — juicio `<pendiente>` |
| R14 | **Doctrina / código** — «doctrina → criterios → auditoría fichero:línea → confrontación → parches → backlog»; parches = especificación, no código | epistémica | `docs\informe-tutoria-plasticidad.md:21-34` [V]; `llms.md:14` [V] | **rito** (seis pasos, tres flexiones) | D11 (documentación como metabolismo), §4.1 pensar-con | candidato a **confirmación** de D11 (drafts como palimpsesto) — `<pendiente>` |
| R15 | **Verificado / `<pendiente>`** — certeza A/B/C del revisor; «nada está verificado contra el libro»; letreros con grado en tiza; penumbra como estado declarado | epistémica | `informe-tutoria-plasticidad.md:55,295` [V]; `../dosier-res-publica/01-croquis.md:56-58` [V]; `s-sdk\LLM.md:25` [V] | **gradiente declarado** (A/B/C, ✓/◐) | D13 (documentar lo que no se sabe; «aquí hay dragones»), §2.6 objetividad situada | candidato a **confirmación** fuerte de D13 — `<pendiente>` |
| R16 | **Simular / rotular** — «el editor rotula, no simula»; «el editor no tiene reloj»; sustrato citable, no vivo | operativa | `../dosier-res-publica/00-dictamen.md:10,41` [V]; `../dosier-colectivizaciones/00-dictamen.md:42-44` [V] | **sustancial** (límite del editor) | D9 (interfaz enactiva), D12 (texto como grafo) | candidato a **contraejemplo** de D9 en el tramo editor — `<pendiente>` |
| R17 | **Prosa / geometría** — la misma proposición escrita dos veces en el mismo documento validado (tesis del tramo y LayoutMap); «la coherencia es del autor» | epistémica | `n-sdk\docs\la-obra.md:45-60` [E] | **convención** (co-presencia sin derivación) | D3 (proyecciones de un mismo virtual), D10 (interoperabilidad parcial) | dato: dos proyecciones **sin sustrato que las derive** — `<pendiente>` |
| R18 | **Vivo / latente / muerto** — estado de cada barrio en el mapa holónico (14 / 7 / 3); `handoffEdges` = 0 | ontológica | `m-sdk\packages\view-kit\assets\mapa\mapa.json` [E] | **sustancial** (enum), sin aristas reales | T1 («nodo sin aristas = potencial no actualizado»), D4 (borrado como proyección) | dato: 24 nodos con grado 0 — `<pendiente>` |
| R19 | **Operador del nodo / cuerpo político** — «la red tiene poderes sin ramas»: la capa cortical (config, hops, invites, `POST /update`, pánico) está fuera del log | política | `informe-tutoria-plasticidad.md:65,83` [V] (`backend.js:4651`, `:9552`, `oasis-pub.js:41` [E]) | **sustancial** (fichero de configuración vs. log) | §2.5 «no basta descentralización técnica»; D14 libertad política; T6 | candidato a **contraejemplo** de D14 en la propia red — `<pendiente>` |
| R20 | **Karma escalar / mérito** — un solo escalar decide desempate, ley (KARMATOCRACY), jueces y renta básica; «el software no es neutral» | económica / política | `informe-tutoria-plasticidad.md:53,83,91` [V] (`parliament_model.js:422`, `courts_model.js:805`, `banking_model.js:932,840` [E]) | **sustancial** (seam P5, cambios de una línea) | §2.4 dato/significado (reificación del escalar), T2 (irreductibilidad de lo múltiple) | candidato a **contraejemplo** de T2 (multiplicidad reducida a escalar) — `<pendiente>` |
| R21 | **Un feed = una persona** — convención sin verificación; salario familiar sobre hogares autodeclarados = sybil | identitaria | `informe-tutoria-plasticidad.md:61,83,89` [V] (`inhabitants_model.js:86-88` [E]) | **convención** (problema abierto de toda red sin territorio) | §4.2 grafos situados por usuario; §6.1 individuación transindividual | `<pendiente>`. Eco de `dualidad.md` «Persona/Máscara» (Jung): la máscara digital sin verificación |
| R22 | **Autor = propietario** — la tribu pertenece a su fundador; la instalación a quien firmó el mensaje raíz | política / económica | `informe-tutoria-plasticidad.md:59,83` [V] (`tribes_model.js:721,726-729`, `industry_model.js:164,980` [E]) | **sustancial** (seam P5) | T1 (relación primaria vs. sustancia), §3.4 (borrar el fundador mata la tribu) | candidato a **contraejemplo** de T1 — `<pendiente>` |
| R23 | **Log inmutable / tombstone** — borrar = tombstone de cliente; el log de solo-anexado conserva la traza; «derogación = tombstone» | ontológica | `informe-tutoria-plasticidad.md:86` [V]; `src\models\tombstone_validator.js` [E] | **sustancial** a favor del ensayo: el borrado ya es proyección | D4 («borrar un archivo solo borra una proyección»), T4 | **confirmación** impuesta por el dato: SSB implementa D4 por construcción — juicio `<pendiente>` |
| R24 | **Hops** — radio de replicación como umbral (2 → 3 en el HUB porque con 2 «/c listaba 0 habitantes») | topológica | `DECISIONES.md:136-146` (D-O15); `pub\config\hub\ssb-config:6` [E] | **gradiente** (entero configurable por el operador) | §2.5 descentralizado ≠ distribuido («no todos conectados con todos»); §2.1 gradientes de intimidad | candidato a **confirmación** de §2.5 — `<pendiente>`. Eco de `dualidad.md` «doble brecha territorial»: quién alcanza a quién es un número |
| R25 | **Solo lectura / obra** — el atlas `S` y `o-sdk` son read-only duro para otros swarms; «ningún plan escribe obra ajena» | operativa / política | `GOBIERNO-LORE-HM.md:39,73`; `PLAN-SCRIPTORIUM-V1.md:34-36` [E] | **sustancial** (territorios con escritor único) | T6 responsabilidad situada; D10 (trading zones sin traducción completa) | `<pendiente>` |
| R26 | **Declarado / en disco** — m-sdk, n-sdk, h-sdk existen y no están en ningún mapa; el modelador no está en ningún asiento | operativa | `04-vista-global.md` §Gobierno | **convención rota** (Regla del LAB incumplida o mapa viejo) | D13 (documentar lo que no se sabe), D11 | dato: la red tiene «dragones» sin cartografiar — `<pendiente>` |

## Ecos con las 14 dualidades de `contraejemplos/dualidad.md` (solo señalar; hermenéutica `<pendiente>`)

| Dualidad sapiens (dualidad.md) | Eco en la red | Filas |
| :-- | :-- | :-- |
| Dualismo interaccionista (Popper): la máquina carece de «Yo» | H/M como roles, no tipos de ser; «ningún jugador privilegiado» | R11, R12 |
| Dualismo cartesiano | primitiva/proyección; nodo/arista | R10, R13 |
| Dualismo post-humano (naturaleza/artificio en el mismo organismo) | peercard firmada compartida por humano, agente MCP y autómata | R6, R12 |
| Brecha explicativa (Chalmers) | prosa/geometría sin sustrato que las derive («la coherencia es del autor») | R17 |
| Persona / Máscara (Jung), amplificada por redes | opt-in de visibilidad; un feed = una persona sin verificación | R3, R21 |
| Sombra (Jung): lo reprimido se proyecta en el «otro digital» | HUB que no se lista a sí mismo; operador del nodo fuera del log | R3, R19 |
| Self / integración de opuestos | holón 07 que relee y ancla sin contener; cristalización L2→L1 como rito | R9, R1 |
| Dualismo civilizatorio (superhumanos / prescindibles) | operador del nodo como poder exterior; karma escalar; hops | R19, R20, R24 |
| Doble brecha territorial | hops; pubs L2 «no padres obligatorios»; read-only duro por territorio | R24, R25 |
| Dualismo humano como conflicto permanente (Saña) | ceguera ascendente / acceso descendente como ley de la cadena | R9 |
| Unidualidad (Peña Vial) | «la capa no cierra el stack: lo abre» (hipótesis OSI, no doctrina); holarquía | R9, `04` §capas |
| Dualidad holográfica / información-campo | sin eco verificado — `<pendiente>` | — |
| Anima / Animus | sin eco verificado — `<pendiente>` | — |

## Lo que esta tabla no hace

No pone porcentaje de bloqueo (eso es de `tabla.md` y del ensayo, no de la
red). No decide si una fila es contraejemplo: marca «candidato» donde el dato
apunta y deja el juicio `<pendiente>`. No inventa filas sin coordenada.
