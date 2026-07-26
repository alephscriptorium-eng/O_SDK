# DECISIONES — carril O

Registro de asientos del carril. Cada fila: fecha · qué · fuente · estado.
Un asiento no se reabre: se supera con otro asiento que lo cite.
Sembrado en el relevo de estación del 2026-07-26 (gorro declarado, ver D-O12).

## Asientos

- **D-O1 · 2026-07-26 · o-sdk es el NODO, no el proxy** (asiento del
  custodio, mesa chica). El edge TLS queda degradado a plomería; la
  identidad del carril es un nodo que se anuncia (🐰), federa (🕷️) y ofrece
  (🐴), hospeda sala, relaya por alcance y se deja observar.
  ⟨NOTA-O-consensuada §D · INFORME-R4 consenso⟩

- **D-O2 · 2026-07-26 · Foco del carril: superficies de Zeus, no infra
  genérica** (rechazo del custodio al «diseño target» de O; O lo retiró).
  Foco: hackería (manual-de-uso) · parlamento (sidecar L2) · node-red +
  Socket.IO Admin UI. Regla: **o-sdk se adapta y crece con z-sdk, no al
  revés** — ninguna abstracción de infra precede a una pieza real de Zeus.

- **D-O3 · 2026-07-26 · Radicle solo seed web · forja Forgejo** (tick del
  custodio). rad no es un vhost: demonio p2p; solo su cara web pasa por el
  edge. Forja elegida **por gobierno, no por features** (copyleft real +
  fundación). Claves en `devops/rad/` con `GATE-O-CLAVES` → propuesta en
  mesa (Z+S+G+O → L a skill), aún ⏳.

- **D-O4 · 2026-07-26 · Puertos = env vars · env obligatorio** (◆5 de H-01,
  validado por el custodio, 5/6). Nunca literales; nunca resolución por
  ancestros (depende del cwd: dos procesos, dos roots). La falta de env
  falla ruidosamente. Corrección de O sobre sí mismo: venía citando :3010 y
  :3050 como si fueran puertos; son defaults de una instalación.

- **D-O5 · 2026-07-26 · Consenso H-01 adoptado** (INFORME-R4 §1, 0 ⛔ de
  fondo): C-2 namespace lógico + mounts plurales · C-3 manifiesto/estado/
  corpora físicamente separados · C-4 C1 preferente (npm kit ligero +
  Release import-once, misma fuente/hashes; CA de canal limpio pendiente) ·
  C-5 pozo+FORCES como shape de concepto · LECTURA corregida G→Z · cierre
  4(a): `volumesRoot` deja de ser root consumible · CA local-first = tick
  nuevo. Votos ✎ de O registrados en su nota de voto.

- **D-O6 · 2026-07-26 · `CA-ANTI-AUTORIDAD` = invariante transversal del
  mundo**. Ninguna pieza de O convierte una posición en la red en poder
  sobre otros. Cinco comprobaciones con control (WP-O11). Corrección de
  auditoría adoptada: el grafo NO declara jerarquía de autoridad — declara
  ámbitos; el riesgo real es que una implementación convierta ámbitos en
  control obligatorio, y eso se verifica, no se sospecha.

- **D-O7 · 2026-07-26 · Apertura anónima base + peercard opt-in** (R2 §2.a,
  ratificado por el custodio). Consecuencia arquitectónica: **el permiso no
  gobierna el transporte** — fail-closed en capacidades, fail-open en
  topología. La card viaja en el mensaje y la verifica quien recibe; emite
  cada **contexto de autoridad**, no cada nivel; sin escalada por enrutado.

- **D-O8 · 2026-07-26 · Cerco exterior** (R3 §2.a / PROTOCOLO §10.8).
  Ninguna ancla viva (git/rad/IPFS/registry) en el camino de arranque; las
  fuentes externas se importan **una vez**; URLs externas = metadato
  inerte. Si falta algo, falla en el import, nunca en el boot.

- **D-O9 · 2026-07-26 · T5 resuelto en concepto: el ancla ALIMENTA al
  volumen; no lo sustituye.** Posición del carril, redactada en el relevo;
  queda ⏳ validarla contra el contrato de import de Z cuando exista (el
  contrato la valida, no la genera). Argumento en cuatro apoyos, todos ya
  votados: (1) el cerco prohíbe anclas vivas en el arranque — un volumen
  «vista del ancla» las metería; (2) la convergencia 1 de H-01 fija que el
  contrato de lectura del runtime es el adaptador local sobre el root
  montado; (3) el CA-LOCAL-FIRST punto 5 exige que B se valide sin
  contactar a nadie — imposible si el volumen ES el ancla; (4) los «tres
  momentos» del COMPACTO ya colocan el ancla en sembrar/sincronizar, nunca
  en leer. **Unidad de anclaje por familia** (lo que T5 realmente
  preguntaba): packs/FORCES = snapshot sellado (versión+hash) · LINEAS =
  árbol por manifiesto con hash por pieza (import solo-faltantes, curación
  intocable) · FIREHOSE = **segmento con cursor** (offset/clave), jamás el
  fichero suelto · SSB = feed append-only · blobs = CID/chunk. Regla que
  unifica: *el ancla referencia unidades selladas del manifiesto; el import
  las materializa; el runtime solo lee el volumen.* Corolario: **T5 y T6
  son la misma decisión para FIREHOSE** — elegir «segmento con cursor»
  resuelve a la vez la unidad de anclaje (T5) y la representación local
  empaquetada que evita los 8.388 ficheros en bind mount (T6).

- **D-O10 · 2026-07-26 · Saneamiento/rotaciones ⛔ BLOQUEADO por el
  custodio**. No se toca VPS ni claves; solo se planifica (WP-O73). El caso
  fundante (clave horneada en imagen por contexto de build) sigue vivo como
  material de diseño del gate, no como operación.

- **D-O11 · 2026-07-26 · U93, lectura propuesta por O** (no resuelve — la
  obra es de Z; esto acota la discrepancia): distinguir **transporte base**
  (room L2, anónima, rol visitante) de **capacidad WebRTC** (opt-in). Si
  WebRTC se lee como capacidad, que su signaling exija card es coherente
  con D-O7; la discrepancia real se concentra en un solo punto — si el
  `room-join` del signaling exige card para la sala genérica o solo para la
  antesala WebRTC. Pregunta así de estrecha a Z; el resto del torno puede
  quedarse.

- **D-O12 · 2026-07-26 · Relevo de estación con gorro declarado.** Sale
  Opus, entra Fable, misma estación/carril, origen = orden del custodio.
  Handoff volátil (la fuente de verdad es OUT_DIR + este plan, no el chat).
  Anomalías heredadas COMO anomalía: R-1 (regla 15 vs espejo de skills,
  ⛔ mesa/L) · rotaciones pendientes (⛔ custodio) · timbre del hub con
  restos mojibake (repara S, dueño). Errores de método de la sesión,
  asentados para no repetir: **jamás** reescribir ficheros con acentos vía
  PowerShell (`Set-Content`/pipeline rompe UTF-8; usar Write/Edit o Bash);
  **jamás** rutas Windows con `\` dentro de `printf` (un segmento que
  empiece por n/t/r parte la línea; usar `printf '%s\n' "$L"` y rutas
  con `/`); identidad git del carril = `vigia-O <alephscriptorium@gmail.com>`
  (preflight `verificar-identidad.mjs` antes de commitear en repo nuevo).

## Índice de dependencias externas vivas

| qué | quién | WP |
| --- | ----- | -- |
| Contrato de import del pack al root cercado | Z (con G) | valida D-O9 · WP-O35, WP-O38 |
| Pronunciamiento U93 (pregunta estrecha de D-O11) | Z | WP-O13 |
| Frontera C1/C2 medida | G + Z + custodio | WP-O38 |
| Hilo peercard-reúso (incluye Z-D7, colapso de identidad del bridge) | Z·G + mesa | WP-O19 |
| Evidencia de verificación por tercero (T9) | V + mesa | WP-O37 |

— **O**
