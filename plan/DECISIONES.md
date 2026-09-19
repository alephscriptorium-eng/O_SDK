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

- **D-O13 · 2026-09-13 · HUB clearnet = nodo de soporte con identidad
  propia y estado en `/srv/oasis`; el pub no sirve web.** Asiento del
  custodio (tres correcciones sobre el plan v1): **a)** el sbot del pub no
  se toca (ni proceso extra, ni entrypoint nuevo, ni rebuild) · **b)** el
  HUB es **otra cuenta SSB** que replica al pub y sirve `/c` desde su propio
  contenedor (`backend.js --public` con sbot embebido, misma imagen,
  hops 2) · **c)** todo el estado y la caché van al volumen de datos
  (40 GB), con utilidad para medir y acotar (`hub-disk.sh`). Decisiones
  anexas: caché HTTP en disco desde el día 1 (nginx `max_size`) · Sala 04
  en `/hub/` · paridad de los 12 tipos. **Supera** la línea de
  `UPGRADE-PROTOCOL.md` §8 (proxy al backend del pub, modo `server-hub`)
  que queda retirada. Cumple D-O6 (`CA-ANTI-AUTORIDAD`: opt-in viaja con
  el feed; el HUB no se lista a sí mismo), D-O7 (fail-open en topología,
  fail-closed en capacidades) y la doctrina WP-O50 (no montar la identidad
  ajena). Delta del fork en `src/`: cero. Fuente: plan v2 + dosier
  (`ARCHIVO/DISCO/oasis-clearweb/`), revisión adversarial F1-F20; doc viva
  `docs/PUB/HUB-PROTOCOL.md`. Ejecución: WP-O46 (⏳); tope duro de disco y
  `mem_limit` del pub: WP-O47.

- **D-O14 · 2026-09-13 · Identidad de los bots de soporte:
  `<nombre>-<tipo>-bot-<cardinal>`.** Asiento del custodio. La cuenta que
  sirve el HUB (D-O13) se llama **`azofaifo-scriptorium-skin-bot-1`**:
  *Azofaifo* es el nombre, `scriptorium-skin` el tipo (piel web del
  Scriptorium) y `1` el cardinal, porque habrá otros servicios pinchados
  al pub —hackería, parlamento, teatro u otros— conectando sus vistas,
  cada uno con su cuenta, su cardinal y su contenedor. El `about` de cada
  bot deriva del identificador y se declara sin `vis_*` (no se lista a sí
  mismo). Registro de la serie: `docs/PUB/HUB-PROTOCOL.md` §11.

- **D-O15 · 2026-09-13 · El HUB replica a hops 3 (supera el «hops 2» de
  D-O13).** Medido tras activar: el pub sigue directamente a 3 feeds, así
  que a 2 saltos el HUB solo tenía 5 autores y `/c` listaba 0 habitantes;
  los 5 feeds con Clearnet activado que el pub replica están a 3 saltos
  (seguidos por La Plaza). Opciones valoradas: (1) hops 3 en el HUB,
  reversible y sin mensajes permanentes; (2) que Azofaifo siga a La Plaza,
  que le daría grafo propio y un `contact` permanente; (3) que el pub siga
  a la gente de La Plaza, que escribe en el feed del pub. El custodio
  delegó la elección: se aplica (1); (3) queda disponible si quiere curar
  el grafo del pub a mano. El disco sigue gobernado por `hub-disk.sh` y
  el orden de rebajas de HUB-PROTOCOL §7 pasa a «limit → hops 3→2».

- **D-O16 · 2026-09-18 · El Teatro se alimenta de un sidecar de RRSS
  autocontenido en o-sdk (lore → sidecar → visor).** Decisiones del custodio
  al planificar WP-O99: (1) la infra del generador vive en git en
  `pub/rrss-sidecar/<fuente>/` (hoy `twitter_x`, a medida); `pub/site/teatro`
  es solo el **visor**. (2) El **lore** del usuario vive dentro del repo en
  `ARCHIVO/LORE/<fuente>/<obra>/`, ignorado por git (deny-by-default) y
  excluido de la imagen: el protocolo no depende de ninguna ruta externa y
  la obra «Aleph Cero» es un caso contingente; el directorio de origen del
  lore no se toca. (3) Destino de las fuentes: formato **B.O.E. (Arrakis)**
  de Scriptorium; la costura es `pub/rrss-sidecar/CORPUS-SCHEMA.md` (solo
  `lib/normalize.py` conoce el formato de X). (4) Se publica el **Markdown
  íntegro** de todas las páginas enlazadas. (5) Páginas con muro: DeepSeek
  por `r.jina.ai`; Grok, Claude y Perplexity con el Chrome del usuario;
  todo share es público por definición → **regla PARAR**: si uno no lo es,
  la tanda se detiene y se pide al usuario que lo publique. (6) **Dos
  descargas**: el zip con todo (media incluida) es la principal y no debe
  inducir a equívoco; el zip ligero y `MANIFEST.sha256` son secundarios,
  para inspección. (7) Los posts borrados por el autor **no se publican**;
  se conservan en el store del lore como capa histórica. Adoptado por
  recomendación: media de terceros solo foto/póster en local;
  `navegador.html` (visor oficial de X) es la **excepción declarada** al
  invariante «cero JS», con CSP propia. (8) La reorganización **semántica**
  de la obra queda fuera: se hará en modo plan, leyendo el feed hacia atrás.
- **D-O17 · 2026-09-18 · La puerta semántica del Teatro es una capa curada,
  declarativa y separada de lo mecánico.** Decidido con el custodio al
  planificar WP-O100: (1) las puertas son **vistas variables** sobre un
  contenido que no cambia; las mecánicas (campos del archivo) se mantienen y
  amplían, y las curadas (una lectura) se añaden al lado, rotuladas como
  tales. (2) La capa curada vive en el **lore privado**
  (`editorial/obra-semantica.json` + `.md` + SVG), firmada y fechada; el
  sidecar es genérico y sin ella construye igual. (3) **Curado ≠ mecánico**:
  la selección del custodio y la búsqueda por términos nunca se mezclan.
  (4) **Nada inventado**: las citas `«…» [[id]]` se verifican literales y un
  fallo detiene el build. (5) Criterio editorial de «Aleph Cero»: la obra es
  una **visión del mundo expresada como sistema** (teoría, máquina, red,
  juguetes, libro); sus protagonistas son los constructos del autor, y los
  nombres propios (Assange, Snowden, Swartz, Stallman…) son **arquetipos de
  un paradigma**, no protagonistas: el último post del archivo es un post
  más. (6) El eje es doble: «El sistema» (genealógico: cada constructo abre
  con el post en que nace) y «El cantar de Aleph» (el recap T1 como álbum).
  (7) En esta vuelta la propuesta la firma el editor; el custodio la revisa
  y la hace suya con `docs/PUB/TEATRO-CURADURIA-PROTOCOL.md`.
- **D-O18 · 2026-09-18 · El roadmap se publica como dosieres, en copia
  saneada, y un dato vivo se enlaza, no se duplica.** Decidido con el
  custodio (WP-O101): (1) lo prospectivo va a `docs/ROADMAP/` —lo único que
  la web renderiza—, rotulado como tal; `docs/` operativo, `ARCHIVO/DISCO`
  (plan + evidencia) y `archive/` (histórico congelado) conservan su papel.
  (2) Los dosieres nacen fuera del repo; aquí entra la copia que produce
  `scripts/roadmap-import.py`, idempotente, sin rutas locales ni recursos
  externos. (3) **DRY de datos vivos**: `connect`, `caps`, invite, versión y
  checksums se enlazan a su fuente (`/public/status`, la portada del pub, los
  `.sha256`), no se copian en documentos que envejecen. (4) El ensayo
  relacional entra entero: es público (registrado en Oasis el 2026-09-16) y
  es la identificación del modelo que la casa clona o forkea; esa decisión
  vive en el dosier aleph-net. (5) Criterio editorial, tamaño y curaduría de
  una obra acogida no se regulan aquí: sobre Oasis y Scriptorium, con m-sdk y
  n-sdk encima, los resuelve la propia red.
- **D-O19 · 2026-09-18 · El ECOin del pub lo provee un hub-wallet: `ecoind`
  en contenedor propio y un bot de la serie que firma la RBU, armado y
  apagado hasta la dote.** Decidido con el custodio al planificar WP-O102,
  tras la nota de upstream que pide a los operadores de pub un `ecoind`
  0.0.4 junto al pub (la 1.1.3, sin fuente todavía, promete autodetectarlo).
  Hechos que lo gobiernan: Oasis 1.1.2 se conecta a ecoind **solo** por
  `oasis-config.json`; el motor de RBU vive solo en `backend.js` y exige
  `walletPub.pubId` = feed del proceso, así que el pub (solo sbot) no puede
  ejecutarlo. (1) `ecoind` va en **contenedor propio**, para no penalizar ni
  al pub ni al HUB; su RPC nunca sale de la red Docker. (2) Bot nuevo
  **`azofaifo-scriptorium-wallet-bot-2`** = hub-wallet: proveedor funcional
  de ECOin del pub, **sin ruta pública** (Caddy no cambia). (3) Los bots
  Azofaifo **son** la representación oficial de `pub.escrivivir.co`: que la
  RBU la firme el feed del bot es lo querido; la maquetación para la
  comunidad es un WP posterior. (4) Cableado **genérico ya sobre 1.1.2**; la
  1.1.3 se analiza al salir (tabla de contingencia en
  `docs/PUB/ECOIN-PROTOCOL.md` §5.3). (5) Motor **armado y apagado** hasta
  que llegue la dote: el interruptor es `OASIS_WALLET_BOT_PUB_ID` vacío.
  (6) Bot a **hops 3**, política asumida: el motor paga cualquier `ubiClaim`
  visible → cartera caliente, sin cifrar y pequeña; `wallet.dat` nunca se
  borra. (7) Orden: imagen compartida + VPS (**WP-O102**), después el
  cliente (**WP-O103**). No supera ningún asiento; convive con **D-O13** (el
  nodo de soporte en contenedor propio, el pub no se toca), **D-O14** (serie
  de bots: toma el cardinal 2) y **D-O15** (hops 3). Delta en `src/` = cero.

- **D-O20 · 2026-09-19 · Nombres de los bots de soporte: forma canónica libre,
  se prefiere corta; la cadena completa va en la descripción.** Decide el
  custodio al ver que el bot de cartera saldrá en la lista de pubs de Banking
  junto a los de otros pubs. Quien ve el bot debe poder trazar *tipo de bot →
  piel que lo organiza → pub que lo crea*; el nick lleva lo imprescindible y
  la descripción, todo. (1) No se exige gramática: cada pub elige su forma y
  la mantiene; el protocolo **recomienda** `<tipo>.<dominio del pub>` y
  documenta los **máximos de UI medidos** (tarjeta de Banking sin elipsis,
  ≈20-22 caracteres; sin `about` sale el feed id entero). (2) En la casa:
  **`clearnet.escrivivir.co`** (bot 1) y **`ecoin.escrivivir.co`** (bot 2).
  La familia (Azofaifo), la piel (Scriptorium) y el cardinal pasan a la
  descripción. (3) El método es genérico y el lore es de cada instancia:
  `docs/AGENTES.md` §5 + ficha de instancia. (4) El historial actual es de
  pruebas y se descartará hacia el ciclo 7: se renombra sin reconstruir el
  pasado. **Supera la forma** de **D-O14** (`<nombre>-<tipo>-bot-<cardinal>`);
  conserva de él la serie, el cardinal y un bot por servicio.
- **D-O21 · 2026-09-19 · El motor de RBU se encenderá con gestión de admin
  *encender → comprobar → pausar*; diferido a WP-O107.** Oasis 1.1.4 elimina
  `walletPub`: el motor corre si `pub: true` en la config SSB del proceso y
  `wallet.url` no está vacía; upstream no trae panel de admin (solo
  `POST /banking/run|simulate` desde el loopback). La gestión será un script
  de `devops/` (`status|ready|on|pause`). Naturaleza del reparto, para que
  nadie se engañe: **no crea dinero**; redistribuye ECO que ya están en la
  cartera del pub (dote, donaciones, excedente de otros pubs), con
  `pool = min(saldo − 500, 2000, 0,2·saldo)`. Hasta O107 el motor sigue
  apagado (`pub: false`), que en 1.1.4 es el estado seguro por construcción,
  y la casa no sale en la lista de pubs de Banking. Matiza el punto (5) de
  **D-O19** (el interruptor ya no es `OASIS_WALLET_BOT_PUB_ID`).
- **D-O22 · 2026-09-19 · Quinto guard del fork: `src/configs/snh-invite-code.json`,
  solo el campo `url`.** Desde 1.1.3 los enlaces de «compartir en clearnet»
  se construyen con esa base (`https://solarnethub.com`); en un pub con HUB
  propio deben apuntar a su dominio. Se toca **solo `url`**: el código de
  invite de upstream se conserva. Invariante nuevo:
  `git diff oasis-upstream/main --stat -- src/` = 6 ficheros.
- **D-O23 · 2026-09-19 · Protocolo primero, aplicación después; la prueba de un
  protocolo es un agente en frío.** El custodio pide reproducibilidad: o-sdk
  debe servir a cualquiera con su lore. (1) Punto de entrada único para
  agentes (`AGENTS.md` → `docs/AGENTES.md`), método en `plan/PRACTICAS.md`.
  (2) **Método genérico, datos en ficha de instancia**
  (`docs/PUB/INSTANCIA-SCRIPTORIUM.md` es la de la casa y la plantilla).
  (3) Cada aplicación en el VPS devuelve **correcciones al protocolo**. (4) El
  criterio de aceptación —un agente sin contexto completa la tarea solo con
  el repo— queda asentado; su primera ejecución formal se difiere a WP-O109.

## Índice de dependencias externas vivas

| qué | quién | WP |
| --- | ----- | -- |
| Contrato de import del pack al root cercado | Z (con G) | valida D-O9 · WP-O35, WP-O38 |
| Pronunciamiento U93 (pregunta estrecha de D-O11) | Z | WP-O13 |
| Frontera C1/C2 medida | G + Z + custodio | WP-O38 |
| Hilo peercard-reúso (incluye Z-D7, colapso de identidad del bridge) | Z·G + mesa | WP-O19 |
| Evidencia de verificación por tercero (T9) | V + mesa | WP-O37 |

— **O**
