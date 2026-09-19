# BACKLOG — carril O (o-sdk · el nodo)

Estados: ⬜ pendiente · 🔶 en curso · ✅ aceptado · ⛔ bloqueado.
Serie: **WP-Onn**. Método: `swarm-orquestacion` (lane · WP · BRIEF · CA).
Prioridad: **P0** desbloquea a la mesa o a otro carril · **P1** núcleo del
mundo · **P2** horizonte.

| dato | valor |
| ---- | ----- |
| Mundo | `C:\S_LAB\o-sdk` |
| Encargo | `INFORME-R4 §2` (F2) — proyectar el mundo **acabado**, sin limitarse a lo votado |
| Fuente normativa | `INFORME-R4.md` · consenso H-01 sellado |
| Asientos del carril | [`plan/DECISIONES.md`](DECISIONES.md) (D-O1…D-O12) |
| Régimen | **nada se abre sin GO del custodio**; encolar de más cuesta cero |
| Revisión | 2026-07-26 · relevo de estación (D-O12): +WP-O19 · T5 resuelto en concepto (D-O9) · U93 acotado (D-O11) |
| Edición | **F2-unificada** (Anfitrión + revisión Temis): +O07/O08/O09/O55/O66/O76/O77/O78/O95 · ownership O13/O21/O37 → dependencias externas · O94 = gate de v1 |

**Dependencias externas de este plan** (un solo Scriptorium): U93/torno =
**Z·U186** (O aporta pregunta estrecha D-O11 y CA de integración) · editor
de env = **V·V26** (O posee schema con Z) · T9 = **V·V44** (O aporta
storage/fixture) · contrato de import = **Z·U199–U206** · entrada al grafo
= **Z-D1 + HUB-022** · frontera kit/pack = **G** (notario/loader).

---

## 0 · El mundo acabado (la imagen que se proyecta)

o-sdk terminado **no es un proxy con vhosts**: es **un nodo de la Ciudad**
que además custodia la capa permanente.

1. **Nodo** — hospeda sala, se anuncia, federa en horizontal, relaya por
   alcance y **se deja observar**. Nunca es obligatorio para que otros dos
   se hablen.
2. **Tres superficies** — *hackería* (Zeus en registro manual-de-uso),
   *parlamento* (sidecar L2), *node-red + Socket.IO Admin UI* (editar y ver).
3. **Registro permanente** — pub SSB (L1) + blobstore; la cristalización
   L2→L1 es un rito explícito, no un efecto colateral.
4. **Molde local reproducible** — el playground arranca **sin red**; el VPS
   es *una instancia* del molde, no su destino.
5. **Soberanía** — forja propia + seed web; imágenes publicadas; salida
   ordenada de dependencias externas.
6. **Sin deuda heredada** — cuenta anulada fuera de la superficie pública,
   identidad fuera de git y de las imágenes, edge con frontera declarada.

Invariante transversal del mundo: **ninguna pieza de O convierte una
posición en la red en poder sobre otros** (`CA-ANTI-AUTORIDAD`).

---

## L0 · Gobierno y método

| WP | prio | título |
| -- | ---- | ------ |
| **WP-O01** | **P0** | Fundar `plan/` del carril |

**BRIEF** · Este backlog + `plan/DECISIONES.md` (asientos de O con fecha y
dueño) + `plan/BRIEFS/` + `plan/REPORTES/`. Hoy el gobierno de O vive
disperso entre `MAPA.md`, `PLAN.md`, `pub/BACKLOG.md` y `sincronia/`.
**CA** · Un WP ✅ tiene brief y reporte trazados · `DRAFT.md` apunta aquí ·
cero decisiones vivas fuera de `plan/`.

| **WP-O07** | **P0** | Gobierno de ejecución F2 |

**BRIEF** · 74 WPs no se despachan planos: grafo de dependencias, ficheros
calientes, olas, techo de workers, gates por lane y **DoD O-v1**. (V ya pagó
esta lección con 3 WPs pisándose un `package.json`.)
**CA** · Cada WP con deps y paths · lotes paralelos con alcance disjunto ·
ningún WP huérfano de gate · DoD escrita antes del primer despacho.

| **WP-O08** | **P0** | Identidad y licencia FOSS |

**BRIEF** · `package.json` dice `oasis-dockerized@1.0.0` sin `license`; el
fichero LICENSE es paródico y declara no crear obligaciones. Para un mundo
FOSS eso es deuda de nacimiento: **el custodio decide nombre, primera
versión y SPDX real** — no se hereda un `1.0.0` de un producto que nadie usó
(INÉDITO).
**CA** · SPDX validado · package/LICENSE/docs/imágenes coherentes · nombre
propio decidido y aplicado.

| **WP-O02** | **P1** | Mapas de territorio (#19) |

**BRIEF** · `plan/MAPA-RAIZ.md`, `MAPA-REPO.md`, `MAPA-TALLER.md` desde las
plantillas del método. Habilita el pulso *territorio == mapa* del vigía,
hoy inaplicable en O.
**CA** · `verificar-territorio-mapa.sh` PASS · entrada sin fila = FAIL de
ronda · ampliar mapa = commit de gobierno.

| **WP-O03** | **P1** | Consolidar gobierno disperso |

**BRIEF** · Fusionar/retirar `MAPA.md`, `PLAN.md` (mi diseño target
retirado), `BASE-*.md` y `pub/BACKLOG.md` hacia `plan/`. Marcar como
[cita inerte] lo superado en vez de borrarlo.
**CA** · Un solo lugar de verdad por tema · cero contradicciones entre
documentos vivos · lo retirado sigue siendo legible con su motivo.
**Eje III** (re-layout): gate de dedup — un contrato no puede estar
definido en dos documentos.

| **WP-O04** | **P1** | Ceguera de la cara pública |

**BRIEF** · `comprobar-ceguera.sh` en CI sobre superficie pública, con la
regla de `BASE-3-MECANISMO.md`. Hoy la doctrina existe y no se ejecuta.
**CA** · `ceguera: 0` en árbol **e historial alcanzable** (regla 14) ·
excepciones declaradas con motivo, no silenciadas.

| **WP-O05** | **P2** | CHANGELOG derivado del backlog |

**BRIEF** · Cada WP ✅ se refleja en `CHANGELOG.md`; cruce automatizado.
**CA** · Desfase backlog↔changelog = 0 antes de cualquier release.

| **WP-O06** | **P2** | Estación de O reproducible |

**BRIEF** · `ESTACION.md` ya calibrado; falta que el arranque sea un
comando y que el residuo conocido **R-1** no ahogue la señal.
**CA** · Un comando levanta estación + timbre · `anomalias.log` filtrado
da 0 en mundo sano · relevo levanta estado sin preguntar.

---

## L1 · El NODO (concepto central)

| WP | prio | título |
| -- | ---- | ------ |
| **WP-O10** | **P0 · BLOQUEA:** | Modelo nodo/pub/relay escrito y validado |

**BRIEF** · Ex `O-j.1`. Modelo operativo con vocabulario ya corregido por
auditoría: barrio y ciudad son **pubs L2** de encuentro, relay,
reconciliación y reenganche — **no** padres obligatorios ni escalones de
mando; no hay camino obligatorio. Incluye las dos vías de señalización de Z
y STUN/TURN como facilitación sin autoridad.
**CA** · Cero uso de «jerarquía» como cadena de mando · las dos vías
descritas y trazadas a evidencia · el modelo no presupone que el VPS sea
autoridad por co-ubicar servicios.
`BLOQUEA:` L2, L4 y la parte de red de L3 — sin él se construiría sobre
supuestos de transporte.

| **WP-O11** | **P0** | `CA-ANTI-AUTORIDAD` como gate ejecutable |

**BRIEF** · Ex `O-j.2`. Los 5 puntos convertidos en comprobación con
control positivo y negativo, aplicable a **cualquier** entregable de O.
**CA** · (1) dos nodos que se alcanzan siguen hablando si cae un tercero ·
(2) el transporte no exige credencial · (3) ningún relay reescribe payload ·
(4) ningún pub L2 emite ni eleva credenciales por transportar · (5) toda
decisión de relay deja rastro. Cada punto con su control.
**Hostil-omite**: probar la **ausencia** (sin card, sin flag), no solo el
valor inválido.

| **WP-O12** | **P0** | Entrada real al grafo — arista A2 (`O → Z`) |

**BRIEF** · Ex `O-01`. Entrar de verdad con cliente MCP y marcar **solo mi
fila** con evidencia literal. Política ya asentada: **apertura anónima base
+ peercard opt-in**.
**CA** · Fila O marcada con ruta/log verificable · modalidad declarada ·
cero marca sin entrada real (falsedad de interfaz).
Dep: **Z-D1 + HUB-022** (la puerta del grafo es `rooms`/`socket-server` —
verificado; el torno WebRTC es otra capa y NO condiciona esta entrada).

| **WP-O13** | **P0 · ⛔ externa** | U93 — CA de integración (obra de **Z**) |

**BRIEF** · **Dependencia externa con owner: Z (U186/Z-D4).** El refactor
del torno no es obra de O; ningún worker O toca `webrtc-signaling`. Lo que
O conserva: (a) la **pregunta estrecha D-O11** como aporte al WP de Z — si
WebRTC es capacidad opt-in, ¿el `room-join` del signaling gobierna la sala
genérica o solo la antesala WebRTC?; (b) el **CA de integración**: cuando Z
entregue, el punto 2 de WP-O11 debe pasar sin excepciones.
**CA** · Contrato de retorno declarado (qué entrega Z, cuándo, cómo se
verifica desde O) · WP-O11.2 pasa contra la entrega real · cero diseño de O
construido sobre el estado previo del torno.

| **WP-O14** | **P1** | Zonas como ámbito de suscripción |

**BRIEF** · Especificar zona = alcance, no ubicación; solapables,
cruzando niveles. Es el desacople que impide que *ver* y *mandar* sean lo
mismo.
**CA** · Dos zonas con el mismo topic = dos conversaciones · una zona puede
contener nodos de distinto nivel · ningún permiso se deriva de la zona.

| **WP-O15** | **P1** | Anuncio de capacidad verificable |

**BRIEF** · El nodo anuncia lo que tiene; se cree **por el hash, no por
quién lo dice**. Traducción a datos de «la autoridad firma, no enruta».
**CA** · La copia de un par cualquiera vale igual que la del nodo
«oficial» · no existe copia canónica, existe contenido correcto.

| **WP-O16** | **P1** | Observabilidad del relay |

**BRIEF** · Toda decisión de relay deja rastro consultable. «El poder que
existe, se ve.»
**CA** · Un relay sin traza es fallo de gate, no aviso · el rastro no
requiere privilegio para leerse.

| **WP-O17** | **P2** | Degradación honesta (fail-open topológico) |

**BRIEF** · Sin ruta hacia arriba, la conversación local **sigue**, marcada
como no federada. Negar por falta de permiso es correcto; por falta de
camino, es avería disfrazada de política.
**CA** · Corte de enlace superior → sesión local viva y **etiquetada** ·
reenganche sin pérdida de la conversación local.

| **WP-O18** | **P2** | Corte silencioso — mi riesgo #1, realizado |

**BRIEF** · R3 verificó *allowlist de 8 sin traza* + `MAKE_MASTER`
suprimido en la obra de Z. Un mensaje que desaparece sin rastro es peor que
uno rechazado.
**CA** · Todo descarte deja traza · control: mensaje fuera de allowlist →
rastro presente. Coordinar con Z (`Z-D7`).

| **WP-O19** | **P1** | Posición de O en el hilo peercard-reúso |

**BRIEF** · El hilo (Z·G, anunciado desde R2 §4) decidirá si las cards se
reúsan al subir de ámbito o si se emite por contexto. Posición de O ya
argumentada y corregida por auditoría: **emite cada contexto de autoridad**
que conceda capacidades limitadas; un pub/relay no emite ni eleva por
transportar — el reúso ascendente es el mecanismo por el que la topología
se convierte en autoridad. Incluye el material de `Z-D7` (colapso de
identidad del bridge: `scriptorium-bridge` único + secreto compartido =
N actores, una identidad).
**CA** · Posición presentada en el hilo con los dos casos (reúso vs
emisión por contexto) contrastados contra `CA-ANTI-AUTORIDAD` · Z-D7
tratado como caso, no como excepción · lo que la mesa decida queda
asentado en DECISIONES con su motivo.
Dep: tick del hilo (Z·G convocan; O participa).

---

## L2 · Playground · molde local

| WP | prio | título |
| -- | ---- | ------ |
| **WP-O20** | **P0** | Fichero de env único de la demo |

**BRIEF** · Ex `O-c`. Fuente única de puertos y URLs de la demo, en el
playground. Hoy cada carril arranca con números propios y la demo no es
reproducible. **Los puertos no son números: son env vars.**
**CA** · Cero literales de puerto en cualquier artefacto de O · el fichero
falla **ruidosamente** si falta una variable · Z valida contra
`presets-sdk/env`.
Dep: coordinación con Z. Habilita **WP-O21**.

| **WP-O21** | **P1** | Editor de configuración (encargo a V) |

**BRIEF** · Ex `O-d`. V ya tiene paneles y árboles; falta apuntarlos al
**fichero real del playground** en vez de a ajustes locales. Interfaz que
**nace nueva** — no se hereda (el acoplamiento O↔V no existía).
**CA** · V edita el fichero real · validación antes de escribir · O declara
su contrato de lectura antes de que V escriba.
**Dependencia externa con owner: V (V26).** O posee schema/validación (con
Z); ningún worker O toca la extensión. Contrato de retorno: V consume el
schema publicado, no lo inventa.

| **WP-O22** | **P0** | Compose del laboratorio |

**BRIEF** · Levantar en Docker Desktop el runtime que la demo necesita,
**parametrizado por env** (WP-O20), sin declarar ningún concepto de Ciudad
en YAML. Barrio, rol y ancla viven en el carril dueño del modelo.
**CA** · Un comando levanta el lab **desde checkout limpio** · cero
literales · cero conceptos de Ciudad en YAML · `CA-ANTI-AUTORIDAD` pasa ·
**health de cada servicio verificado** · **shutdown limpio sin residuos**
(no basta «compose up»).
Dep: WP-O10, WP-O20.

| **WP-O23** | **P1** | Arranque sin red (garantía offline) |

**BRIEF** · Cerco exterior (§10.8) hecho propiedad verificable: si falta
algo, falla en el **import**, nunca en el arranque.
**CA** · Desconectar la red y arrancar → PASS · control: si falla, hay
ancla viva no declarada · ninguna ancla (git/rad/IPFS/registry) en el
camino de arranque.

| **WP-O24** | **P1** | Emulación del edge por alias de red |

**BRIEF** · El Caddyfile resuelve por **alias**, no por IP: los 5 vhosts
con backend externo son **enchufes ya cableados**. Levantar los servicios
locales con el alias correcto y quedan servidos sin tocar config.
**CA** · Cero cambios en el Caddyfile para el lab · cada enchufe declara qué
lo llena y qué queda vacío a propósito.

| **WP-O25** | **P1** | Sembrado del playground desde el registry del método |

**BRIEF** · La demo debe poder levantarse por alguien que solo tenga el
repo y el kit. Documentar el camino mínimo.
**CA** · Un tercero sin contexto levanta la demo siguiendo solo el
documento (**Eje IV**: el segundo consumidor como sensor).

| **WP-O26** | **P2** | Paridad molde local ↔ instancia |

**BRIEF** · Declarar qué del molde es replicable y qué es de instancia.
Precede a cualquier movimiento hacia WAN.
**CA** · Tabla replicable/instancia sin `<pendiente>` inventados · el
contrato es el mismo, los paths no.

---

## L3 · Volúmenes (O = consumidor del contrato)

| WP | prio | título |
| -- | ---- | ------ |
| **WP-O30** | **P0** | Contrato de montaje: root único, orígenes plurales |

**BRIEF** · Consenso H-01 C-2 con **env obligatorio** (validado por el
custodio). El contrato es el **catálogo, no la ruta**; mismo contrato en
local y VPS con paths distintos.
**CA** · Root resuelto **solo** por env explícito · cero resolución por
ancestros (depende del cwd: dos procesos, dos roots) · falta de env falla
ruidosamente.

| **WP-O31** | **P0** | Separación física manifiesto / estado / corpora |

**BRIEF** · Consenso C-3 desde el lado de storage: no es distinción
conceptual, **quieren almacenamiento distinto**. Si conviven, el árbol
hereda lo peor de ambos y deja de poder montarse en solo-lectura.
**CA** · Root monta `:ro` y el juego arranca · escritura al mount mutable
aparte · el estado mutable **nunca** dentro del árbol del manifiesto ·
import no pisa curación humana · **locking del mount mutable declarado**
(dos procesos no corrompen) · **backup/restore del mutable probado**.

| **WP-O32** | **P1** | Reconciliación por hash, nunca por mtime |

**BRIEF** · `mtime` y tamaño mienten: una copia los cambia, el reloj deriva
y los bind mounts normalizan metadatos. Correcto hasta el día que no, y ese
día no avisa.
**CA** · Reconciliación contra manifiesto con hashes · **control**: tocar
mtime sin tocar contenido **no** dispara resync.

| **WP-O33** | **P1** | Drivers por patrón de acceso, no por formato |

**BRIEF** · Lo que varía por familia: unidad de replicación · append-only
vs reescribible · registry autoritativo o derivado. **Un flujo no se
reconcilia como un árbol**: se reanuda.
**CA** · Las 4 familias (LINEAS · FORCES · FIREHOSE · SSB) con su unidad
declarada · familia desconocida = **error**, no adivinanza.

| **WP-O34** | **P1** | FIREHOSE: representación local (T6) |

**BRIEF** · 8.388 ficheros sueltos son un acantilado de rendimiento en bind
mounts de Windows/Docker Desktop, que **es nuestro molde local**. No es
detalle de implementación: condiciona el contrato. **Dirección fijada en
D-O9**: la unidad es el **segmento con cursor** — N segmentos empaquetados
+ índice en lugar de 8.388 ficheros; T5 y T6 son la misma decisión vista
desde dos lados.
**CA** · Medición antes/después en el molde real · el contrato admite
representación empaquetada sin cambiar el catálogo · reanudar por cursor
funciona sobre la representación empaquetada.
Deuda declarada de O (T6). Dep: WP-O35 (comparten decisión de unidad).

| **WP-O35** | **P0** | T5: el ancla ALIMENTA — validar contra el contrato de import |

**BRIEF** · **Deuda mía con la mesa** (compromiso R4 §1) — **resuelta en
concepto en D-O9**, pendiente de validación: el ancla alimenta al volumen,
no lo sustituye; el runtime solo lee el volumen montado; el ancla
referencia **unidades selladas del manifiesto** que el import materializa.
Unidad por familia: snapshot sellado (packs/FORCES) · árbol manifiesto+hash
(LINEAS) · **segmento con cursor** (FIREHOSE) · feed (SSB) · CID (blobs).
Cuatro apoyos, todos ya votados (cerco · convergencia 1 · CA-LOCAL-FIRST
punto 5 · los tres momentos del COMPACTO).
**CA** · La posición contrastada contra el contrato de import de Z cuando
exista — si el contrato la refuta, se reabre con asiento nuevo · las cinco
familias con unidad declarada · presentada a la mesa en el tick que
corresponda.
Dep: contrato de import (Z) — para **validar**, ya no para responder.

| **WP-O36** | **P1** | `CA-LOCAL-FIRST` ejecutable (tick nuevo, ya votado) |

**BRIEF** · Los 6 criterios con control. La mesa votó tick nuevo con
LECTURA renovada: aquí se encola, **no** se ejecuta.
**CA** · (1) arranque sin red · (2) import idempotente · (3) montaje `:ro` ·
(4) hash no mtime · (5) réplica A→B **sin contactar a A ni a un tercero** ·
(6) cero identidad en volúmenes. Cada uno con control.

| **WP-O37** | **P2** | T9: verificación por un tercero |

**BRIEF** · Corrección aceptada del COMPACTO: mi prueba demostraba
independencia **desde dentro del par**. Falta que un tercero pueda
verificar la réplica sin consultar a A ni a B.
**CA** · Un verificador externo valida con solo el manifiesto público.
**Dependencia externa con owner: V (V44) + mesa.** O aporta el lado de
storage y las fixtures; la evidencia final la consume HUB-084.

| **WP-O38** | **P1** | Consumo del pack Release al root cercado |

**BRIEF** · C-4/C1 preferente. O **no decide canal**; necesita el
**contrato de import**: qué recibe, cómo valida, dónde aterriza.
**CA** · Import: staging → validar → fusionar → sellar · **reimport = no-op**
· falla en import, nunca en arranque.

| **WP-O39** | **P2** | Porte histórico one-off (soporte a Z-D8/D9) |

**BRIEF** · La fuente histórica existe y está censada; `registry.yaml` de
LINEAS está **stale** → tratar el registry como incompleto antes de
importar. O aporta destino de montaje, no semántica.
**CA** · Destino declarado por familia · cero datos reales montados sin
import validado · OASIS no se mueve.

---

## L4 · Superficies

| WP | prio | título |
| -- | ---- | ------ |
| **WP-O40** | **P1** | Hackería: Zeus en registro manual-de-uso |

**BRIEF** · Ex `O-g`. Envolver lo que z-sdk ya publica con piel de
**manual**, no de spec: el usuario ve para qué sirve, no cómo está hecho.
Zeus ya construye su portal; esto **envuelve**, no reimplementa.
**CA** · Cada pieza del censo con entrada legible sin conocer el código ·
cero duplicación de la spec · se regenera cuando Zeus publica.
**Eje I**: un consumidor real (alguien ajeno) encuentra una pieza usando
solo la hackería.

| **WP-O41** | **P1** | Parlamento: sidecar layer-2 |

**BRIEF** · Ex `O-h`. Juego de ventana de contexto sobre la sala. Doctrina
que lo gobierna: **L1 = ∞, L2 = sesión**; nada de la sala escribe directo
al pub — el retorno es por **cristalización explícita**.
**CA** · El parlamento no escribe a L1 · la cristalización es un acto
declarado, con rastro · caída del sidecar no rompe la sala.
Dep: WP-O10.

| **WP-O42** | **P1** | node-red como editor |

**BRIEF** · Editor sobre el tubo, con contribs **rediseñadas** — las viejas
viven en la cuenta anulada y dependen de un secreto compartido.
**CA** · Cero dependencia de la cuenta vieja · identidad por peer, no
secreto compartido · el editor no es requisito para que la sala funcione.

| **WP-O43** | **P1** | Socket.IO Admin UI de los nodos room |

**BRIEF** · Observabilidad del nodo. Es media razón de ser de WP-O16: el
poder que existe, se ve.
**CA** · Estado del nodo visible sin privilegio de mando · leer no habilita
actuar.

| **WP-O44** | **P2** | Superficie pública del nodo |

**BRIEF** · Landing que explique qué es este nodo, qué ofrece y cómo
entrar — con la política correcta: **anónimo base, card opt-in**.
**CA** · Un visitante entiende cómo entrar sin pedir permiso a nadie · cero
material de identidad en la página (caso fundante: token en claro).

| **WP-O45** | **P2** | Retirar superficie muerta |

**BRIEF** · `pub-frontend` apunta a un contexto de build inexistente;
`catalog.json` duplicado byte a byte en dos rutas.
**CA** · Cero servicios declarados sin código · cero duplicados de datos ·
lo retirado queda documentado con motivo.

| **WP-O46** | **P1** | Sala 04 · HUB clearnet como nodo de soporte |

**BRIEF** · Servir el HUB web de solo lectura de Oasis 1.0.8 (`/c`, 12
tipos) desde un **segundo nodo SSB con identidad propia** (`oasis-hub`:
`backend.js --public` con sbot embebido, misma imagen, `command:
["backend"]`, hops 3 desde D-O15; el plan decía 2) que redime un invite del pub y replica su grafo;
caché HTTP en disco (`hub-cache`, nginx `max_size`) y estado en el volumen
de datos (`/srv/oasis/oasis-hub/*`); bloque `@hub` en Caddy; puerta
estática Sala 04 (`/hub/`); utilidad `hub-disk.sh`. El contenedor del pub
**no cambia** (ni imagen, ni entrypoint, ni su servicio en el compose).
Visibilidad opt-in del habitante (`CA-ANTI-AUTORIDAD`); la cuenta de
soporte `azofaifo-scriptorium-skin-bot-1` (D-O14) se declara en su `about`
y no se lista a sí misma. Doc viva:
`docs/PUB/HUB-PROTOCOL.md`; plan y dosier: `ARCHIVO/DISCO/oasis-clearweb/`.
**CA** · `/c`, `/c/inhabitant/%40%2F…`, `/assets/images/snh-oasis.jpg` →
200 con CSP `script-src 'none'`, **una** `X-Frame-Options` y
`X-Cache-Status` · segunda petición a `/c` = HIT · landing,
`/assets/fanzine.css`, `/public/status` y los 5 vhosts intactos tras
`caddy reload` · el feed del pub solo crece por el `contact` del
follow-back (secuencia antes/después = +1) · el pub sigue healthy y no se
reinicia en ningún paso · todo el estado nuevo bajo `/srv/oasis/oasis-hub`
y `df /` igual antes/después · feed del HUB tras 24 h = solo `contact`,
`pub` (lo publica ssb-invite al aceptar), `about` y `oasisVersion` (cero
`private`) · `hub-disk.sh check` → 0 · rollback ensayado
(< 5 min) · journal.
**Hostil-omite** · habitante sin `visibilityPrefs.clearnet` → «not
accessible» (200 upstream), nunca contenido · `POST /c` → 405 en nginx (en
el backend: 400 sin Referer, 302 `?error=…public mode…` con Referer) ·
`/settings`, `/profile`, `/publish`, `/update`,
`/json/x`, `/qr/x` desde el vhost → respuesta estática de Caddy, jamás el
HUB · parar `oasis-hub` no afecta al pub (`whoami`, `invite`, replicación)
· parar el pub deja `/c` sirviendo réplica/caché (STALE) ·
`OASIS_HUB_PUBLIC=false` **nunca** con `@hub` activo en Caddy · invite con
host reescrito: `conn.json` del HUB apunta a `oasis-pub`, no a la IP
pública.
Dep: WP-O74. Relación: WP-O44, WP-O50 (doctrina), WP-O53, WP-O91, WP-O01
(crear `plan/BRIEFS/`, `plan/REPORTES/`). Asientos: D-O13, D-O14.

| **WP-O47** | **P2** | Tope duro de disco para el HUB |

**BRIEF** · `hub-disk.sh` mide y poda pero no impide; falta un límite
físico para `/srv/oasis/oasis-hub` (imagen loop de tamaño fijo o cuota de
proyecto ext4) y `mem_limit` también para el pub (hoy sin límite: un pico
del HUB puede empujarlo al OOM-killer).
**CA** · llenar el HUB hasta el tope no toca `/srv/oasis/oasis-pub` ni `/`
· el pub sobrevive a un OOM del HUB · decidido con 30 días de
`hub-disk.sh --json`.
Dep: WP-O46.

| **WP-O97** | **P1** | Upgrade Oasis 1.0.8 → 1.1.2 con el HUB activo |

**BRIEF** · Primer upgrade del fork con el nodo de soporte en producción.
Seguir `UPGRADE-PROTOCOL.md` + `HUB-PROTOCOL.md` §5: overlay limpio,
4 guards, greps de invariantes del HUB sobre el árbol nuevo, adaptar lo
que upstream cambió del visor (`/c/assets/*`, rutas de detalle nuevas),
deploy pub-primero/HUB-después con rollback preparado, journal
`--mode server+hub`.
**CA** · `git diff oasis-upstream/main --stat -- src/` = 4 guards +
`blockchain-cycle.json` · greps §5.1 ≥ 1 · pub y HUB healthy con la imagen
nueva, ambos feed id sin cambios · `pub:invite` funciona · `/c`,
`/c/inhabitant/%40%2F…`, `/c/assets/images/snh-oasis.jpg` 200 y MISS→HIT ·
landing, `/assets/fanzine.css`, `/public/status` intactos · directorio
verde en ciclo 6 · rollback (retag + `up --no-build oasis-pub oasis-hub`)
preparado antes del build · journal.
**Hostil-omite** · `POST /c` → 405 · `/settings`, `/update`, `/qr/x` desde el
vhost nunca llegan al HUB · `/c/qr/x` sin `X-Cache-Status: HIT` (`no-store`).
Dep: WP-O46. Relación: WP-O80, WP-O77.

| **WP-O98** | **P1** | Cliente fresco en o-sdk + importación de identidad |

**BRIEF** · El cliente personal nunca se inicializó desde este repo (vivía en
un checkout antiguo, Oasis 0.8.8). Probar el protocolo de alta fresca del
cliente en esta misma carpeta, sin solaparse con el pub/HUB local, y añadir
el paso «importar identidad» (secret + log + gossip) sin bifurcar el feed:
sbot puro hasta sincronizar con el pub, GUI al final. Lo antiguo deja de
usarse; solo importa la identidad. Doc viva: `docs/CLIENT-PROTOCOL.md`.
**CA** · alta fresca reproducible con los comandos del protocolo (`setup` →
`build` → `up`; healthy; versión) · `import-identity.sh` verifica origen
(frames del log, id = public, sin NUL), deja backup verificado y flag
`oasis-first-contact` · `sync-only start` rehúsa con GUI viva y se para si
el sbot no es el feed del secret · `status --pub` llega a SYNC-OK (seq local
= seq pub, log estable) · tras arrancar la GUI: `whoami` = feed importado,
`POST /settings/verify` sin forks propios, `seq_pub` = seq importado +
`oasisVersion` · `volumes-dev/` del cliente y del pub disjuntos ·
`git check-ignore pub/.env.prod` ignorado.
**Hostil-omite** · destino no vacío sin `--force` → rechazo · origen sin
`log.offset` íntegro o con `id ≠ public` → rechazo · sbot con otra identidad
→ parada automática · nunca GUI sobre log importado sin flag.
Dep: WP-O97. Relación: WP-O77, WP-O80, WP-O46 (§3 invite desde sbot puro).

| **WP-O99** | **P1** | Teatro · sidecar de RRSS con fuente en exports de x.com |

**BRIEF** · El Teatro (Sala 03) estaba en producción sin gobierno: el generador
de la Obra Nº 1 solo existía fuera del repo, el deploy tenía la obra
hardcodeada y no había WP, asiento ni changelog. Traer **toda la infra a
git** (`pub/rrss-sidecar/twitter_x/`, Python stdlib), con el **lore del
usuario dentro de o-sdk pero fuera de git** (`ARCHIVO/LORE/`) para que el
protocolo sea autocontenido y la obra del custodio un caso contingente.
Store aditivo multi-generación; protocolo (a) voces ajenas a 1-2 niveles
(incluidas las **citas**, que el export no trae); protocolo (b) cada enlace
externo a Markdown íntegro, con cola de navegador y **regla PARAR** para
shares de agente no públicos; deploy por obra con verificación; higiene del
VPS (permisos, 404 real, CSP, backup de lo no regenerable). Costura
`fuente → corpus normalizado → visor` lista para un adaptador B.O.E.
(Arrakis). Docs vivas: `docs/PUB/RRSS-SIDECAR-PROTOCOL.md`,
`docs/PUB/TEATRO-PROTOCOL.md`.
**CA** · `npm run teatro:test` verde sobre un export sintético (multi-parte,
store aditivo, contrato del corpus, guardas que fallan con `ip-audit.js`
sembrado) · `lore-import + init + ingest + build` sin editar código ·
`git ls-files ARCHIVO/LORE` = 2 ficheros y `obra.json` sin rutas fuera del
repo · obra regenerada con la generación 2026-09-18 (1940 posts visibles;
los borrados solo en el store) · worklist de voces 100 % en estado terminal,
0 `error` · todos los enlaces en el store, `links_blocked.json` vacío o con
dispensa del custodio, ninguno `pending_browser` · `teatro:check` verde ·
deploy con verificación automática verde · permisos 755/644 · 404 real bajo
`/teatro/` · `data/ip-audit.js` → 404 · resto de vhosts intactos.
**Hostil-omite** · el parche multi-vídeo del visor solo se aplica si el
sha256 del bundle stock coincide · la migración del store antiguo no pierde
texto ya recuperado · un share privado **para** la tanda (exit 3), nunca se
salta · la denylist se aplica también dentro de los zips · `.dockerignore`
excluye lore y sidecar · el Caddyfile vivo se valida antes del reload y
nunca se reinicia `pub-web` · ningún proceso escribe en el origen de un export.
**Fuera de alcance (punto final anotado)** · reorganización **semántica** de
«Aleph Cero»: se decide en modo plan, leyendo el feed hacia atrás.
Dep: WP-O46 (volumen y layout del VPS). Relación: WP-O47 (disco), WP-O55 (backup).

| **WP-O100** | **P1** | Teatro · puerta semántica: «El sistema» y «El cantar» (capa curada) |

**BRIEF** · El Teatro solo ofrecía puertas mecánicas. Añadir la puerta que
explica la obra como **visión del mundo expresada como sistema** (teoría →
máquina → red → juguetes → libro; los protagonistas son los constructos del
autor), como **capa editorial declarativa**: genérica en el sidecar
(`lib/editorial.py`, `editorial.example/`, subcomandos `editorial-init |
check | delta`) y con el contenido en el lore privado
(`ARCHIVO/LORE/<fuente>/<obra>/editorial/obra-semantica.json` + `.md` + SVG).
Segunda puerta «El cantar de Aleph» (recap T1, 13 cortes). Puertas mecánicas
intactas y ampliadas: **Conversaciones** e **Interlocutores**. Portada con
sigilo SVG inline. Protocolo para revisar, actualizar y seguir curando:
`docs/PUB/TEATRO-CURADURIA-PROTOCOL.md`.
**CA** · `npm run teatro:test` verde (sin capa editorial la salida no cambia;
con ella: páginas, chips, índices, portada) · `editorial-check` sin errores
sobre Aleph Cero (21 constructos, 13 cortes, 143 citas literales
verificadas) · `teatro:check` verde · `git ls-files ARCHIVO/LORE` = 2
ficheros · deploy con verificación automática verde; `/sistema/` y
`/cantar/` → 200 · resto de vhosts intactos.
**Hostil-omite** · una cita no literal, un `.md` ausente, una ruta fuera de
`editorial/` o un `version` desconocido **detienen el build** · un id borrado
o inexistente se avisa y se omite, nunca se rellena · curado y mecánico se
muestran separados · la portada SVG con script, eventos, `<image>` o recursos
se rechaza, y las guardas barren todo SVG del árbol · los vídeos solo se
enlazan · el JSON y los dosieres de `editorial/` no se publican.
**Pendiente del custodio (sesión de revisión)** · hacer suya la propuesta v1
(`curated_by`), aportar las 12 letras que faltan, y los flecos de WP-O99
(enlace de Perplexity, copia de backups fuera de la máquina).
Dep: WP-O99.

| **WP-O101** | **P2** | Roadmap · los dosieres de trabajo publicados en `docs/ROADMAP/` |

**BRIEF** · El material prospectivo de la casa (seis dosieres de trabajo:
aleph-net, relacional, colectivizaciones, res-publica, oasis-faircoin,
publicidad-rrss) vivía fuera del repo. Publicarlo como **«Roadmap futuro»**
en la web (`docs/ROADMAP/`, con anexos en `docs/public/dosieres/`) y
enlazarlo desde README, portada, menú y barra lateral. Se publica la **copia
saneada** que produce `scripts/roadmap-import.py` (rutas de disco → nombres
de repo; sin Google Fonts; sin enlaces a artifacts privados; la fila del panel
remite a WP-O52; los datos de conexión del pub **no se duplican**: se enlaza
`/public/status`). `modelador-redes` se enlaza (proyecto propio);
`oasis-clearweb` no entra: ya es `ARCHIVO/DISCO/` + `HUB-PROTOCOL`. De paso
se declara la diferencia `archive/` vs `ARCHIVO/` (`ARCHIVO/README.md`,
README, MAPA).
**CA** · `npm run docs:build` sin enlaces muertos · gate `verificar-sitio.mjs`
verde · 0 rutas `C:\S…`, 0 `fonts.googleapis`, 0 `claude.ai/code/artifact` y
0 copias de `connect`/`caps` en lo publicado · `/ROADMAP/` responde en la web.
**Hostil-omite** · páginas y anexos no comparten nombre salvo mayúsculas
(`ROADMAP/` vs `roadmap/` colisiona en Windows → anexos en `dosieres/`) · el
origen de los dosieres no se modifica · reimportar es idempotente.
Dep: —. Relación: WP-O52 (panel), WP-O100 (Aleph Cero como manual de cobertura).

| **WP-O104** | **P1** | Protocolo para agentes: entrada única, irreversibles, trampas, nombres |

**Estado** · ✅ 2026-09-19 en `main`. Asientos D-O20, D-O23.
`AGENTS.md` raíz → `docs/AGENTES.md` (árbol intención → protocolo, reglas
universales, tabla de irreversibles, trampas agregadas, convención de
nombres) · ficha de instancia `docs/PUB/INSTANCIA-SCRIPTORIUM.md` (método
genérico, datos aparte) · `HUB-PROTOCOL.md` §11-§12 (serie de bots y
renombrado) · `plan/PRACTICAS.md` · índices con los 8 protocolos.
Dep: —. Relación: WP-O46, WP-O102, WP-O103.

| **WP-O105** | **P1** | Upgrade mínimo Oasis 1.1.2 → 1.1.4 con pub, HUB y hub-wallet activos |

**Estado** · ✅ 2026-09-19: gates locales pasados (`plan/REPORTES/WP-O105-upgrade-oasis-1.1.4.md`).

**BRIEF** · Overlay con `git rm -r src` + **5 guards** (D-O22). Estado de bot-2:
retirar `OASIS_BANKING_DIR` y copiar antes `banking/*.json` a
`ssb-data/oasis/banking/` (1.1.4 muda el estado a `~/.ssb/oasis/**` y
`backend.js` ignora la variable: riesgo de segunda dirección publicada).
Motor apagado (`pub: false`). Avisos de obsolescencia en ECOIN §5.3/§9 y
CLIENT §8. Gates: build, G0 migración de estado, G4 del HUB, bot-2.
Dep: WP-O104. Relación: WP-O97 (upgrade anterior).

| **WP-O106** | **P1** | Aplicar en el VPS: 1.1.4 + renombrado de los dos bots |

**BRIEF** · pub → HUB → bot-2; renombrado con `HUB-PROTOCOL.md` §12; reporte con
correcciones al protocolo. GO expreso antes del deploy y de cada `about`.
Dep: WP-O105.

| **WP-O107** | **P2** | Motor de RBU en 1.1.4: interruptor `pub: true` y gestión de admin |

**BRIEF** · D-O21. `ssb-config.engine-on` vía `OASIS_WALLET_BOT_SSB_CONFIG_FILE`;
limpiar `walletPub`, marcador y `OASIS_WALLET_BOT_PUB_ID`;
`devops/scripts/hub-wallet.sh status|ready|on|pause`; gate con `pub: true`
(cambia el plugin a `ssb-invite`: efecto sobre conexión y `hub-conn-fix.js`);
reescribir ECOIN §9; encendido y primer `pubAvailability`.
Dep: WP-O106.

| **WP-O108** | **P2** | Cliente en 1.1.4: entrypoint, scripts y CLIENT-PROTOCOL §8 |

**BRIEF** · Symlink muerto de `wallet-addresses.json` y cableado de `walletPub`
en `docker-entrypoint.sh`; `client/scripts/*`; banco autodescubierto (§8.7);
drill. **Hasta entonces no reconstruir el cliente con 1.1.4.**
Dep: WP-O105.

| **WP-O109** | **P3** | Endurecimiento: agente en frío, `limit_req` en `/c`, docs de upstream |

**BRIEF** · Primera prueba formal de D-O23 · `limit_req` en la location `^/c/`
(`/c/<tipo>/<slug>` reconstruye el índice, O(N·k)) · traer `deploy.md` e
`inventory.md` de upstream.
Dep: WP-O106.

| **WP-O103** | **P1** | Cliente · ECOin en la app (dirección o cartera propia) |

**Estado** · ✅ 2026-09-18: protocolo asentado en `main`; gate G1 y drill con
identidad desechable pasados (`plan/REPORTES/WP-O103-cliente-ecoin.md`).
BRIEF: `plan/BRIEFS/WP-O103-cliente-ecoin.md`. **Fuera de alcance por
decisión del custodio**: aplicarlo a su identidad scriptorium; lo hará él
cuando se publique Oasis 1.1.3.

**BRIEF** · El cliente también necesita ECOin, en **dos niveles**: (i) *solo
dirección* — aparecer, recibir y reclamar RBU (el claim es un mensaje SSB;
paga el `ecoind` del banco); (ii) *cartera propia* — saldo, envíos e
historial exigen `ecoind` propio con `wallet.dat` propia. El cliente **nunca**
apunta al `ecoind` del VPS (HTTP plano, monedero único) y la identidad
importada no trae dirección. `docker-compose.yml` raíz: `ecoin-wallet` sin
`ports`, credenciales del `.env` raíz, healthcheck, `mem_limit`, `logging`,
`stop_grace_period`, `wallet.dat` en **volumen nombrado `external`**
(`o-sdk-client-ecoin-data`); `oasis-client` con `depends_on … required:
false`, `ECOIN_RPC_URL` vacía por defecto, `OASIS_WALLET_PUB_ID`,
`OASIS_BANKING_DIR=/app/state/banking`. `docker-entrypoint.sh` (zona
wholesale; `src/` sigue con 4 guards): `persist_client_state()` y
`wire_wallet_config()` con **guarda anti-remoto** (host ∈ {`ecoin-wallet`,
`localhost`}) y `pubId` validado; solo se activan con
`OASIS_CLIENT_STATE_DIR` → pub, HUB y bot sin regresión. Scripts
`client/scripts/` (`ecoin-init.sh`, `backup-wallet.sh`, `guard-destroy.sh`,
`ecoin-verify.sh`) y npm `ecoin:*` sin credenciales en claro. Sección ECOin
en `docs/CLIENT-PROTOCOL.md`.
**CA** · ensayo completo con **identidad desechable**
(`client/docker-compose.drill.yml`, proyecto `o-sdk-drill`, sin conectar al
pub), D1-D9: RPC por DNS de servicio y **no** desde el host · exactamente 1
mensaje `wallet` tras N recreates · config y `banking/` sobreviven · `down -v`
no borra la cartera · backup/restore con sha256 · guarda anti-remoto · pub,
HUB y bot arrancan igual sin `OASIS_CLIENT_STATE_DIR` · `npm run docs:build`
+ `verificar-sitio.mjs`. **Puerta**: confirmación expresa del custodio antes
de publicar su dirección en el feed real (mensaje permanente); después
`OASIS_WALLET_PUB_ID` = feed de bot-2.
**Hostil-omite** · `wallet.url` a un host remoto → rechazo · `pubId` mal
formado → rechazo · `downDELETEVOLS`/`cleanDELETEVOLS` sin pasar por
`guard-destroy.sh` → no borra la cartera · `.env` sin credenciales → el
compose falla (`${…:?}`), nunca arranca con `ecoinrpc` · `setup.sh` e
`import-identity.sh` no tocan `ecoin-data`.
Dep: WP-O102. Relación: WP-O98 (cliente fresco), WP-O97.

---

## L5 · Pub / L1 permanente

| WP | prio | título |
| -- | ---- | ------ |
| **WP-O50** | **P1** | GO del blobstore sidecar |

**BRIEF** · Código y tests existen; deploy no. Cuatro condiciones sin las
cuales no entra: `profiles` (que ningún deploy lo arrastre) · token
declarado (sin él arranca sin auth) · tamaño máximo acorde a la memoria
real · montar **solo el socket**, no el directorio con la identidad.
**CA** · Las 4 verificadas antes de levantar · salud 200 desde el harness ·
el contenedor no ve material de identidad · **rootless/capabilities
mínimas declaradas** (least-privilege por defecto).

| **WP-O51** | **P1** | Cristalización L2→L1 como rito |

**BRIEF** · El único camino de la sesión al registro permanente. O está al
otro lado de esa puerta, recibiendo — no la abre, la sostiene.
**CA** · Un solo verbo de entrada a L1 · nada cristaliza por efecto
colateral · lo cristalizado declara su origen.

| **WP-O52** | **P1** | Panel: quitar el poder que no necesita |

**BRIEF** · El panel monta el socket de Docker en lectura-escritura y corre
como root: quien controle ese proceso puede crear un contenedor
privilegiado. No es «una API de restart».
**CA** · El proceso ya no ve el socket crudo (**socket-proxy mínimo** con
allowlist de operaciones) · control: intento de crear contenedor
privilegiado → denegado · rootless donde el runtime lo permita · la
capacidad se reduce, no se documenta.

| **WP-O53** | **P1** | Invites sin coste por visita |

**BRIEF** · Un GET anónimo dispara una operación cara contra el pub y el
fallo no se cachea; además el resultado cacheado no expira nunca.
**CA** · N peticiones anónimas → 1 operación · caché negativa con
caducidad · invite muerto detectado, no servido.

| **WP-O54** | **P2** | Salud y métricas del nodo |

**BRIEF** · Señal observable `OK/DEGRADED/FAIL`; sin señal trazada **no** se
declara OK.
**CA** · Cada estado con su evidencia · ausencia de señal ≠ salud.

| **WP-O55** | **P1** | Backup / restore / disaster recovery de L1 |

**BRIEF** · El pub y el blobstore son **la capa permanente**: si solo
existen en un disco, no son permanentes — son afortunados. Backup
declarado, restore probado, RPO/RTO escritos.
**CA** · Restauración completa **en host limpio** · RPO/RTO declarados y
medidos · el backup no contiene material de identidad · restore no depende
de la máquina autora.

| **WP-O78** | **P1** | SLO, alertas y capacidad |

**BRIEF** · «Salud OK» sin umbrales medidos es opinión. Límites de disco,
memoria y conexiones conocidos **antes** de que se crucen.
**CA** · SLO escritos por servicio · alerta dispara antes del límite, con
evidencia · capacidad medida en el molde real, no estimada.

| **WP-O102** | **P1** | hub-wallet del pub: `ecoind` + `azofaifo-scriptorium-wallet-bot-2` |

**BRIEF** · Oasis 1.1.2 trae Wallet, Banking y RBU, y upstream pide a los
operadores de pub un `ecoind` 0.0.4 junto al pub (la 1.1.3, sin fuente aún,
promete autodetectarlo). El motor de RBU vive solo en `backend.js` y exige
`walletPub.pubId` = feed del proceso: el pub (solo sbot) no puede ejecutarlo.
Se monta un **hub-wallet** con el método de WP-O46: imagen `ecoin/`
endurecida y compartida con el cliente (`.deb` con sha256 versionado y build
que falla si no casa, conf sin credenciales en git, fail-closed ante
`ecoinrpc`, puerto P2P 7408) · servicio `ecoin` en contenedor propio, **sin
`ports`**, con límites y cierre limpio de BDB · servicio `oasis-wallet-bot`
(misma imagen, `command: ["backend"]`, hops 3, `OASIS_BANKING_DIR`
persistente) con la config **renderizada fuera de git** · ambos bajo el
perfil compose `wallet` · backup de `wallet.dat`, control de disco y
presupuesto de memoria (HUB 1536m→768m). El motor nace **armado y apagado**:
`OASIS_WALLET_BOT_PUB_ID` vacío hasta la dote. Caddy no cambia; el pub no se
reinicia. Doc viva: `docs/PUB/ECOIN-PROTOCOL.md`. Asiento D-O19.
**CA** · gates locales: G1 sintaxis + build con hash bueno y **build que
falla** con hash alterado; `pub:local:up` sin perfil intacto · G2 ecoind
healthy, RPC 200 desde la red, nada publicado al host, `ecoinrpc` → 401, sin
credenciales → exit 1 · G3 bootstrap del bot, motor apagado (cero
`pubAvailability`), dirección publicada **una** vez, `up --force-recreate`
conserva `banking/` y no genera otra dirección, ensayo del interruptor
(encender → 1 tick → apagar) · G4 aislamiento (stop ecoin / stop bot → pub y
HUB intactos) · G5 backup y restore de `wallet.dat` (misma dirección,
`ismine:true`) · G6 CPU/memoria durante el sync con `cpus 0.75`.
Invariantes en el VPS: `docker port oasis-pub-ecoin` vacío y
`curl 127.0.0.1:7474` rechazado desde el host · `getinfo` con
`connections ≥ 1` · feed de bot-2 solo con los tipos permitidos · `StartedAt`
del pub sin cambios, +1 `contact`, HUB, Caddy y los 6 vhosts intactos ·
backup de `wallet.dat` verificado **antes** de comunicar la dirección ·
`ecoin-disk.sh check` = 0 · `npm run docs:build` + `verificar-sitio.mjs` ·
delta en `src/` = cero.
**Hostil-omite** · `.deb` con un byte alterado → el build falla · arranque
con `ecoinrpc` o sin credenciales → exit 1 · `up` sin `--profile wallet` no
levanta ni exige nada nuevo · motor apagado → cero `pubAvailability`,
`ubiAllocation` y pagos · ningún script borra `wallet.dat` (restore = apartar
a `.bak-<fecha>`) · render con credencial no hex, feed mal formado o destino
directorio → aborta · nunca `private` ni `post` en el feed de bot-2.
Dep: WP-O46, WP-O97. Relación: WP-O47 (memoria del pub, disco), WP-O55
(backup), WP-O103 (cliente).
Anotado, sin numerar: WP futuro **«presentación comunitaria de los bots
oficiales»** (quiénes son los bots Azofaifo, qué firma cada uno y por qué la
RBU llega de bot-2).

---

## L6 · Soberanía (forja · seed · imágenes)

| WP | prio | título |
| -- | ---- | ------ |
| **WP-O60** | **P1** | Forja Forgejo |

**BRIEF** · Decidida por tick. Criterio: **gobierno, no features** — única
con copyleft real y fundación detrás; con permisiva + empresa, la siguiente
relicencia no la decidimos nosotros.
**CA** · Repos alojados y clonables · el arranque de la demo **no** depende
de la forja (cerco) · migración reversible.
Dep: **WP-O70**.

| **WP-O61** | **P1** | Radicle: solo seed web |

**BRIEF** · Ex `O-b`. Espejo público de lectura. rad **no es un vhost**:
demonio p2p con puerto propio; solo su cara web pasa por el edge.
**CA** · Repo con remote rad replicado · seed sirve lectura · **el seed no
es dependencia de arranque** (acotado por el cerco).
Dep: WP-O70.

| **WP-O62** | **P1** | Publicar imágenes |

**BRIEF** · Hoy las imágenes se construyen **en el destino**, y por eso una
clave acabó horneada. Construir en origen y publicar cambia la clase entera
de fuga: el destino deja de tener contexto de build.
**CA** · Imágenes con tag versionado · el destino solo tira, no construye ·
contexto de build sin material de identidad (**WP-O70**).
Dep dura: **WP-O70 + WP-O76** — forja, seed e imágenes **nunca** preceden
al gate de claves ni al CI de producto.

| **WP-O66** | **P1** | Imágenes reproducibles, firmadas, con SBOM |

**BRIEF** · Publicar imágenes sin procedencia es mudarse de problema: de
«clave horneada» a «binario inexplicable». Digest verificable, SBOM y
provenance por imagen.
**CA** · Dos builds del mismo tip comparan manifest · digest citado en el
deploy · SBOM publicado junto a la imagen.

| **WP-O76** | **P0** | CI de producto |

**BRIEF** · Hoy solo hay workflow de docs; el backlog promete compose,
imágenes, pub, sidecars y seguridad **sin gate continuo**. PR sin gate = no
merge.
**CA** · compose config-check · shellcheck · tests · build sin secretos ·
inspección de imagen (W-1: contra el artefacto, no el patrón de ignore) ·
vulnerability scan · smoke offline. Todo en verde antes de cualquier
release.

| **WP-O63** | **P2** | CI propio |

**BRIEF** · Hoy el CI externo depende del registry propio: ya somos
dual-dependientes sin haberlo decidido. Runner propio con sintaxis
compatible.
**CA** · El portal se construye y publica sin el proveedor externo,
end-to-end, una vez.

| **WP-O64** | **P2** | Servir la documentación desde el edge propio |

**BRIEF** · Paso reversible: el edge sirve el sitio construido como espejo;
el proveedor externo sigue siendo primario hasta que el DNS decida.
**CA** · Mismo contenido en ambos · cambio de primario sin reconstruir.

| **WP-O65** | **P2** | Independencia de terceros en la superficie |

**BRIEF** · Insignias y recursos servidos por terceros hacen que la página
dependa de quien no controlamos.
**CA** · La superficie pública renderiza completa sin red externa.

---

## L7 · Seguridad y deuda

| WP | prio | título |
| -- | ---- | ------ |
| **WP-O70** | **P0** | `GATE-O-CLAVES` |

**BRIEF** · Ex `O-a`. Material de identidad fuera de git **y** del contexto
de imagen, verificado **antes** del build. Caso fundante: una clave vivía
fuera del árbol versionado y acabó dentro de una imagen porque el contexto
de build no la excluía — **el gitignore solo no basta; la segunda puerta es
el contexto, y fue la que falló**.
**CA** · Ambas exclusiones presentes · listado del árbol versionado sin
material de identidad · inspección del contexto de build con 0 ficheros de
clave · el gate corre **antes** del build, no después.
`BLOQUEA:` WP-O60, WP-O61, WP-O62.

| **WP-O71** | **P1** | Identidad fuera del plano de datos |

**BRIEF** · Invariante ya aplicable de la mesa: ningún volumen aloja
identidad; los secretos van por env, nunca en el árbol.
**CA** · Búsqueda de material de identidad en volúmenes = 0 · control: un
fichero de clave colado hace fallar el gate.

| **WP-O09** | **P0** | CLI segura + threat model |

**BRIEF** · Los scripts públicos incluyen `downDELETEVOLS`,
`cleanDELETEVOLS`, `update` con `git pull` y credenciales de ejemplo en
comandos. Para un nodo que **custodia datos**, el default debe ser
conservador: lo destructivo se gana, no se tropieza.
**CA** · Comandos destructivos separados y con confirmación + backup previo
obligatorio · secretos por store/env, jamás en argv/README · matriz de
amenazas escrita (hostil-omite incluido) · least-privilege por defecto.

| **WP-O72** | **P1** | Deuda de la cuenta anulada en superficie pública |

**BRIEF** · La superficie pública enlaza a una cuenta que la propia
doctrina de ceguera declara anulada, e incluye un `curl | bash` desde esa
cuenta y una rama vieja — un onboarding público que ejecuta código de un
origen retirado.
**CA** · Cero enlaces a la cuenta anulada en superficie pública · el
onboarding se retira hasta tener sustituto propio (**WP-O42**) · gate de
ceguera lo protege en adelante (**WP-O04**).

| **WP-O73** | **P2 · ⛔** | Rotación de credenciales históricas |

**BRIEF** · ⛔ **BLOQUEADO por el custodio**: no se toca, solo se planifica.
Alcance previsto para cuando se levante: la clave de acceso al destino, el
secreto de sala publicado y el token del panel. Todos siguen en el
historial.
**CA** · Cada credencial rotada con evidencia · el gate WP-O70 impide la
reincidencia · nada se ejecuta sin GO explícito.

| **WP-O74** | **P1** | Frontera del edge compartido |

**BRIEF** · Este repo posee el TLS de servicios cuyo código vive en otro
sitio: es punto único de fallo de cosas que no controla. Declarar la
frontera antes de crecer.
**CA** · Cada vhost con dueño declarado · reinicio del edge con
consecuencia conocida y escrita.

| **WP-O75** | **P2** | Ceguera del historial |

**BRIEF** · La regla 14 alcanza al historial, no solo al árbol. Decidir qué
se puede sanear y qué queda declarado como pasado.
**CA** · Decisión escrita por caso · nada se reescribe sin GO.

---

## L8 · Upstream (fork Oasis)

| WP | prio | título |
| -- | ---- | ------ |
| **WP-O80** | **P1** | Cablear el protocolo de upgrade |

**BRIEF** · El protocolo está documentado y **no se puede ejecutar**: falta
el remoto del upstream del que depende cada paso.
**CA** · El preflight de upgrade corre de principio a fin · deriva de
versión detectable · overlay reproducible.

| **WP-O81** | **P1** | Consolidar parches duplicados |

**BRIEF** · La misma corrección se mantiene en dos sitios con caminos de
activación distintos; solo una actúa según cómo se instale.
**CA** · Una definición por parche (**Eje III**: gate de dedup) · ambas
rutas de instalación aplican lo mismo.

| **WP-O82** | **P1** | Sacar el dato de red de la zona de overlay |

**BRIEF** · Un dato de red vive dentro de la zona que el overlay
sobrescribe en cada actualización: se pierde en silencio.
**CA** · El dato fuera de la zona sobrescrita, o protegido explícitamente
por el protocolo · control: simular overlay y comprobar que sobrevive.

| **WP-O83** | **P2** | Devolver al upstream lo que es suyo |

**BRIEF** · Dos parches son correcciones genuinas, no adaptaciones nuestras.
Devolverlos reduce nuestra divergencia permanente.
**CA** · Propuestos aguas arriba con caso reproducible · clasificación
declarada de qué es upstreamable y qué es decisión de despliegue.

---

## L9 · Horizonte: instancia remota y WAN

| WP | prio | título |
| -- | ---- | ------ |
| **WP-O90** | **P2** | Instancia remota como caso del molde |

**BRIEF** · Primero el molde en local; el destino remoto es **una
instancia**, no la meta. Migrar cuando el molde esté probado, tirando
imágenes en vez de construir.
**CA** · Misma demo levanta en local y en remoto con el mismo contrato y
paths distintos · el destino no construye.
Dep: WP-O22, WP-O26, WP-O62.

| **WP-O91** | **P2** | Volumen de datos separado |

**BRIEF** · Existe un volumen separado del disco de sistema; falta ruta y
contrato operativo. Encaja con la separación manifiesto/estado.
**CA** · Contrato común, paths distintos · el runtime no depende de dónde
está montado.
Relación: WP-O46 fija el contrato para el HUB (`/srv/oasis/oasis-hub/*`,
verificado en `verify-debian13-base.sh`; `docs/PUB/HUB-PROTOCOL.md` §2) —
cierra la parte «ruta»; queda el contrato general.

| **WP-O92** | **P2** | Federación LAN → WAN |

**BRIEF** · El salto es una **juntura que aún no está documentada**. No se
inventa el holón siguiente sin juntura verificable: primero se describe.
**CA** · Descripción de la juntura antes de cualquier obra · el
`CA-ANTI-AUTORIDAD` sigue pasando al cruzar de LAN a WAN.

| **WP-O93** | **P2** | Contenido pesado direccionable |

**BRIEF** · Objetos inmutables por identificador de contenido, referenciados
desde manifests. Habilitado por la separación de L3 — pero **jamás en el
camino de arranque** (cerco).
**CA** · Un objeto pesado resoluble desde fuera · el manifiesto es la raíz
de confianza · desconectar la red no impide arrancar.

| **WP-O77** | **P1** | Upgrade y rollback de instancia |

**BRIEF** · Una instancia que solo sabe avanzar es una trampa: la
actualización fallida debe volver al estado anterior **sin perder datos**.
**CA** · Upgrade fallido → rollback probado · datos intactos tras el ciclo ·
el procedimiento corre sin la máquina autora.

| **WP-O94** | **P1 · gate de v1** | Segundo nodo (prueba de que no somos el centro) |

**BRIEF** · La prueba definitiva del modelo — y si el objetivo de la
versión es demostrar federación, esto es **gate de aceptación, no horizonte
ornamental** (sube de P2 por revisión). Un nodo hermano que federa en
horizontal.
**CA** · Dos nodos federados · apagar cualquiera no aísla a los demás ·
`CA-ANTI-AUTORIDAD` punto 1 verificado **en vivo**, no en papel · entra en
la DoD de O-v1 (WP-O95).

---

## L10 · Aceptación

| WP | prio | título |
| -- | ---- | ------ |
| **WP-O95** | **P0** | Aceptación O-v1 por operador externo |

**BRIEF** · La definición de acabado que no se puede autocertificar: un
operador **ajeno al equipo**, desde canales limpios, instala → siembra →
levanta el nodo → hace backup → restaura — sin hablar con el autor. Es la
cara O del test de Scriptorium v1 (10 pasos, integración Temis).
**CA** · Ciclo completo documentado y ejecutado por tercero · cero pasos
que exijan conocimiento no escrito · evidencia literal de cada paso ·
incluye WP-O94 como prueba de federación.

---

## Encolado post-F2 (2026-07-31)

| WP | prio | título |
| -- | ---- | ------ |
| WP-O96 | P2 | Spike: market propio junto al registry npm |

**BRIEF** · Decisión ③ del custodio: el Marketplace de VS Code queda
DEFERRED; se explora un market propio del Scriptorium al lado del registry
npm nuevo (misma soberanía que forja/imágenes, L6). Alcance de spike:
opciones, coste, integración con el canal GitHub Release; cero obra de
runtime. Consumidor directo: V86 (primera release de V).
**CA** · informe con opciones y recomendación · decisión de mesa encolada ·
ninguna infraestructura montada durante el spike.

---

## Trazabilidad de los candidatos del `DRAFT`

| draft | destino |
| ----- | ------- |
| `O-a` | WP-O70 |
| `O-b` | WP-O61 (+ WP-O60) |
| `O-c` | WP-O20 |
| `O-d` | WP-O21 |
| `O-e` | WP-O39 |
| `O-f` | WP-O22 · WP-O30 |
| `O-g` | WP-O40 |
| `O-h` | WP-O41 |
| `O-i` | WP-O42 · WP-O43 |
| `O-j` | WP-O10 · WP-O11 · WP-O13 |

Retirado por O y **no** reencolado: patrón de contenedor genérico
(abstracción de infra que no nacía de obra de Zeus).

---

## Conteo (edición F2-unificada)

| prioridad | WPs |
| --------- | --- |
| **P0** | **16** |
| **P1** | **39** |
| **P2** | **22** |
| **total** | **77** |

(2026-09-13: +WP-O46 P1, +WP-O47 P2 en L4, asiento D-O13.)
(2026-09-17: +WP-O97 P1 en L4 — upgrade 1.1.2 con HUB.)
(2026-09-17: +WP-O98 P1 en L4 — cliente fresco + importación de identidad.)
(2026-09-18: +WP-O99 P1 en L4 — Teatro: sidecar de RRSS, asiento D-O16.)
(2026-09-18: +WP-O100 P1 en L4 — Teatro: puerta semántica, asiento D-O17.)
(2026-09-18: +WP-O101 P2 en L4 — Roadmap: dosieres de trabajo en docs/ROADMAP, asiento D-O18.)
(2026-09-18: +WP-O102 P1 en L5 — hub-wallet del pub (ecoind + wallet-bot-2), +WP-O103 P1 en L4 — ECOin en el cliente, asiento D-O19.)

**P0 (16)**: O01 fundar plan · **O07 gobierno ejecución** · **O08
identidad/licencia FOSS** · **O09 CLI segura** · O10 modelo de nodo · O11
CA-anti-autoridad · O12 entrada al grafo (dep Z-D1) · O13 (⛔ externa: Z) ·
O20 env único · O22 compose · O30 contrato de montaje · O31 separación
física · O35 T5 · O70 gate de claves · **O76 CI producto** · **O95
aceptación por operador externo**.

Distribución: L0 8 · L1 10 · L2 7 · L3 10 · L4 8 · L5 7 · L6 8 · L7 7 ·
L8 4 · L9 6 · L10 1.

`BLOQUEA:` WP-O10, WP-O70 (+O76 bloquea releases). ⛔: O13 (externa Z) ·
O73 (custodio). **Gate de v1**: O94 + O95. Secuencia dura: O70+O76
preceden a O60/O61/O62.

— **O**
