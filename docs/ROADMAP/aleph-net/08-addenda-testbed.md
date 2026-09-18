# 08 — El testbed de la addenda, leído desde la red que tenemos

Leyenda: [V] leído · [E] reportado por exploración, sin cotejo · [NV] · `<pendiente>`. Ver `00-indice.md`.

Para quien llegue desde `../dosier-relacional/contraejemplos/` sin saber que
existe el modelador de redes: **existe** (`F4/modelador-redes`,
descrito en `01-modelador-redes.md`), y la casa tiene ya varias piezas de lo
que la addenda pide. Este fichero las pone en correspondencia. No decide.

## Qué propone la addenda (`contraejemplos/addenda.md` [V])

- Opción **e**: la Salida 4 (transponer la brecha de Chalmers) no resuelve el
  *hard problem*, pero produce tres cosas: una reformulación («experiencia =
  dimensión interior de un proceso relacional»), un programa
  (neurofenomenología: 1ª y 3ª persona se constriñen mutuamente) y un
  artefacto («hipergrafo como co-productor de experiencia, no representador;
  testeable: úsalo y observa qué pasa con el inside al externalizarlo»).
- La pista es una cadena de desplazamientos del hueco: ontológico →
  conceptual → metodológico → **empírico**. El último eslabón es un
  **testbed**: «un hipergrafo mínimo donde documentar un estado interno (un
  sentimiento, una intuición) no sea meter un dato, sino inscribirlo en
  relaciones que lo transforman». Pregunta empírica: ¿cambia la experiencia
  al ser cartografiada relacionalmente?
- Siguiente paso operativo declarado: definir **qué mediría** el testbed (qué
  se registra, qué se relaciona, qué se observa al cabo de N iteraciones).
- Regla: declarar siempre el hueco restante.

`contraejemplos/roadmap-hard-problem.md` [V] es el taller que precede a la
addenda: método de «PR teórico» en seis pasos (§1) y el parche §IV.4 para el
ensayo (§2.3), con límites declarados (§2.6: «no se operacionaliza cómo medir
la interioridad de un proceso»).

## Correspondencias con la casa

| Lo que pide la addenda / el roadmap | Lo que ya hay | Dónde | Estado |
| :-- | :-- | :-- | :-- |
| Método de PR teórico: localizar · diagnosticar · parche · justificar · verificar no-regresión · declarar límites (`roadmap:9-16`) | **Los seis pasos del modelador**: corpus → auditoría `fichero:línea` → confrontación → parches → backlog → revisión; deuda siempre declarada | `modelador-redes/docs/informe-tutoria-plasticidad.md:21-34` [V]; `01` | vivo (3 nodos, 1 arista) |
| El parche §IV.4 como intervención en el documento | un `draftvN.md` + fichas `revision/NN-*.md` de un nodo del catálogo; nunca se reescribe el draft anterior (palimpsesto) | `modelador-redes/llms.md:56-66` [V] | requiere nodo `relacional` (vía 1 del dictamen, `<pendiente>`) |
| «Qué se registra, qué se relaciona, qué se observa tras N iteraciones» | **Vía C**: estudio observacional sobre el pub, `modelador observar` que lee un log SSB y emite `data/observaciones.json` con las métricas de la vía B; protocolo ético de consentimiento explícito | `informe-tutoria-plasticidad.md:269` [V] | propuesto, no implementado |
| Testbed sin personas reales | **Vía B**: simulación multiagente, N contenedores con `ssb-server` y agentes sintéticos; el log append-only es el dataset | `informe-tutoria-plasticidad.md:267` [V] | propuesto, no implementado |
| «Inscribir en relaciones que lo transforman» | SSB por construcción: log append-only, follows/blocks, `about`, `post` con `recps`/`root`/`branch`, tribus, `vote`; **borrar = tombstone = proyección** | `02` §Modelo de datos; `05` R23 | vivo en L1 |
| Dónde vive el testbed | **L2 = sesión** («nada de la sala escribe directo al pub»); cristaliza a L1 solo por un verbo (WP-O51); G3 «el parte viaja por el pub» = checkpoint | `02` §Doctrina; `05` R1 | doctrina viva; L2 real solo en playground localhost |
| 1ª y 3ª persona que se constriñen mutuamente | tres prácticas documentales ya en uso: certeza A/B/C del revisor frente a `fichero:línea`; letreros con grado en tiza y penumbra como estado declarado (dosieres Novelist); la misma proposición en prosa y en geometría «validadas juntas» en `la-obra.md` | `05` R15, R17; `03` §Dosieres hermanos | vivo como práctica, no como código |
| Vocabulario para «quién inscribe qué, con qué autorización» | LORE-HM: `Peer` (H/M como roles), `Activity` con `causedBy`, `Lease` revocable, `Artifact`; WP-HUB-101 con reuso obligatorio de PROV-O/AS2/DCTERMS | `04` §LORE-HM, §Ontología H/M | sellado, sin consumidor; package pendiente del custodio |
| Interfaz donde «pensar-haciendo» | Novelist `/scene` (m-sdk): things, offers, layouts; **pero «el editor rotula, no simula» y no tiene reloj** | `03`; `05` R16 | vivo; límite declarado |
| Ética de la inscripción | `CA-ANTI-AUTORIDAD` (ámbitos, no jerarquía); opt-in que viaja con el feed; «ningún jugador privilegiado» | `02` §Opt-in; `05` R3, R5, R12 | doctrina viva con gate (WP-O11) |

## Lo que el testbed necesita y no existe (de `07-ausencias.md`)

1. Un tipo de mensaje que registre el uso («consulta X activó nodos Y, Z»,
   D5 meta-grafo). Nadie lo tiene; en SSB sería un tipo nuevo bajo opt-in.
2. Relaciones n-arias tipadas. Ni el modelador, ni `LayoutEnlace`, ni el
   grafo de capa 5 las admiten; SSB tiene listas (`recps`) sin hiperarista.
3. Una API para leer el grafo desde fuera del pub (`friends.graph`, `about`,
   hops). Sin ella `modelador observar` no observa nada; hoy solo hay HTML
   en `/c` y `/public/status`.
4. Proyecciones re-derivables de un sustrato (G_X, G_Y). Las tres
   «proyecciones» de m-sdk son inconexas y la del mapa es import-once.

## Corrección a la cadena de desplazamientos

La addenda desplaza el hueco ontológico → conceptual → metodológico →
empírico. En esta casa hay un eslabón previo al empírico: **cartografiado**.
Hoy m-sdk, n-sdk, h-sdk y el modelador existen en disco y no están en
ningún mapa canónico (`04` §Gobierno; `05` R26). Un testbed que nazca sin
declararse repite el patrón. Regla del LAB: «nada nuevo en esta raíz sin
declararlo en este mapa».

## Camino que se deduce (proyección, no decisión; sigue la tesis «nada sube a L2 sin modelarse»)

1. **Modelar**: nodo `relacional` (o `testbed`) en el modelador. Su `draftv0`
   audita Oasis con una sola pregunta: dónde puede inscribirse un estado
   interno relacionalmente (`about`, `post`+`recps`, tribus privadas, `vote`,
   tombstone), con `fichero:línea` y certeza A/B/C. Convierte en verificable
   la tabla [NV] de `../dosier-relacional/02-croquis.md:71-82`.
   Prerrequisitos `<pendiente>`: decisión de scrum root (vía 1) y permiso de
   autoría del ensayo (`00-dictamen.md:99-102`).
2. **Rotular**: barrio/obra en Novelist con el patrón dictamen → croquis →
   storyboard; el grado de certeza y la penumbra como material escénico.
   Límite: el editor no simula.
3. **Sesionar**: L2 (rooms/Ciudad/peercard). Hoy solo playground localhost
   con la sala en stubs y el modo `card` sin cablear (`03`). Ahí se hacen
   las N iteraciones.
4. **Cristalizar**: WP-O51, un verbo; lo que pasa a L1 es el «parte», no la
   sesión. Es la operacionalización de D8 («commit = cristalización
   provisional») y respeta L1 = ∞.
5. **Observar**: vía C sobre el log (o vía B en contenedores), con el
   protocolo ético del informe. Requiere la API del punto 3 de ausencias.
6. **Declarar el hueco**: lo que el testbed no mide (§2.6 del roadmap) va en
   el índice de revisión del nodo, como deuda, no como nota al pie.

## Lo que este fichero no decide

Si el nodo se llama `relacional` o `testbed`; si el testbed es obra de o-sdk
(pub), de m-sdk (editor) o de un mundo nuevo (el modelo está cerrado a 7
letras, `04`); qué mide exactamente el testbed (la addenda lo deja como
siguiente paso; aquí solo se listan los instrumentos que ya existen).
