# WPS — pack SOLID×MCP · ronda 2 (el mapa abierto)

| dato | valor |
| ---- | ----- |
| Misión | enseñar Solid a los equipos del Scriptorium para implementarlo **desde z-sdk** |
| Naturaleza | **pre-WPs**: educan primero, encolan después; no backlog vivo |
| Serie | **WP-SMnn** · ids de ronda 1 estables (SM01–SM16) · nuevos SM17–SM24 |
| Régimen | **propuesta · INÉDITO** — nada se abre sin GO del custodio; ✎ recomienda, no decide |
| Teoría | [`TEORIA.md`](TEORIA.md) §T1–§T10 · territorio: [`MAPA.md`](MAPA.md) |
| Caminos abiertos | [`DICOTOMIAS.md`](DICOTOMIAS.md) DIC-1…DIC-7 |
| Demolición | pack aditivo; quien traduzca a su serie, declare la suya |
| Fecha | 2026-07-28 · ronda 2 |

Organización por **olas** (grafo en MAPA.md); dentro de una ola, lo no
dependiente es paralelizable. «Dueño sugerido» ≠ ownership (lo asigna la
mesa).

---

## OLA A · FUNDAMENTOS

| **WP-SM01** | P0 | Adoptar el anexo como material de carril |

**BRIEF** · Espejar `TEORIA.md` + `MAPA.md` + `DICOTOMIAS.md` donde cada
mundo lea material (enlace o submódulo, no copia). Sección superada →
[cita inerte] con el asiento que la supera (trato WP-O03).
**CA** · Cada WP-SM encolado cita §T sin repetir teoría · cero
contradicción con asientos vivos · superación por cita.
**Dueño sugerido** · gobierno de cada mundo.

| **WP-SM17** | P0 · nuevo | Glosario bilingüe Solid ↔ Zeus |

**BRIEF** · La barrera real de los equipos no es técnica, es de idioma:
tabla término-Solid ↔ término-de-casa con la pieza z-sdk donde vive
(WebID↔peercard/ssbId · pod↔volumen · LDP↔`http-contract` ·
contenedor↔carpeta de volumen · ACL↔capacidades/features · Solid
Notifications↔`rooms` events · IdP↔puerta). Columna «falso amigo»
obligatoria (p.ej. pod NO es el feed; tool NO es predicado, §T5).
**CA** · Todo término §T1 tiene fila · cada fila apunta a paquete real
(`packages/engine|mesh/...`) o a «no existe aún» explícito · los falsos
amigos citan la sección que desarma la confusión.
**Dueño sugerido** · Z (dueño del idioma de casa) con revisión O.

| **WP-SM24** | P1 · nuevo | Ruta de onboarding: orden de lectura + katas |

**BRIEF** · Currículo mínimo por equipo: orden de lectura (§T1→§T2→
glosario→su ola) + una kata por ola (p.ej. B: levantar CSS y leer un pod
con `curl`; D: expandir un acta con `@context` en jsonld.js; E: llamar un
tool y verificar su output schema). Katas sobre el molde local, nunca
contra VPS.
**CA** · Un dev nuevo completa la ruta sin tocar producción · cada kata
tiene verificación automática (script PASS/FAIL) · tiempo total medido y
publicado.
**Dueño sugerido** · mesa (es material de todos los carriles).

---

## OLA B · MOLDE

| **WP-SM02** | P0 | Starterkit CSS local (pod por jugador, sin red) |

**BRIEF** · Community Solid Server 7.x como pieza del molde local (§T1):
config + seed de pods en arranque, env vars vía `presets-sdk`/`loadZeusEnv`
(D-O4: cero literales), arranque **sin red** (cerco D-O8: CSS local no es
ancla viva). Entregable = boilerplate `starterkit-css/` instalable por
consumidor limpio (regla de despacho G: inspección de tarball).
**CA** · Boot offline PASS · un pod por jugador sembrado y legible por
LDP · cero puertos literales · el VPS es *una instancia* del molde.
**Dueño sugerido** · O (co-ubicación con pub) con kit consumible desde Z.

| **WP-SM20** | P1 · nuevo | CSS junto al pub: la instancia del molde en o-sdk |

**BRIEF** · Llevar el starterkit SM02 al nodo real: CSS al lado del pub
SSB (edge = plomería, D-O1), WebID del pub publicado, dominios/rutas por
env. NO abre rotaciones ni claves (⛔ D-O10 sigue vivo).
**CA** · La instancia usa el starterkit sin fork (molde manda) · WebID del
pub dereferenciable · cero secreto nuevo en imagen o git (caso fundante
D-O10 como material del gate).
**Dueño sugerido** · O · dep: SM02.

---

## OLA C · IDENTIDAD

| **WP-SM03** | P1 | Identidad triple: mapa WebID↔peercard↔ssbId |

**BRIEF** · Documentar los tres contextos de identidad y su NO-fusión
(§T9; D-O7: contexto de autoridad, no nivel). Incluye DIC-1 (topología
IdP) con el drill SM14 como criterio de cierre.
**CA** · Tabla identidad×contexto×emisor×verificador · ningún texto deriva
permisos de posición en la red · DIC-1 con criterio ejecutable.
**Dueño sugerido** · mesa (O: pub/WebID · Z: peercard).

| **WP-SM18** | P1 · nuevo | Attestation peercard ⇄ WebID (doble cita, cero fusión) |

**BRIEF** · El enlace concreto entre mundos: la peercard (dos tipos ya en
`peer-card-seat`: humano-puerta y agente-MCP) **cita** el WebID del
portador, y el perfil WebID **publica** la(s) card(s) vigentes. Doble
referencia verificable, sin identidad maestra (§T9). La verificación la
hace quien recibe (D-O7: la card viaja en el mensaje).
**CA** · Verificador de doble cita con control positivo y negativo ·
**hostil-omite**: card sin WebID y WebID sin card siguen valiendo en su
propio contexto (degradación honesta, no fusión forzada) · cero campo
nuevo obligatorio en la card.
**Dueño sugerido** · Z (dueño de peercard) con O como consumidor real.

| **WP-SM19** | P1 · nuevo | Login Solid-OIDC en cliente browser (spike) |

**BRIEF** · Spike educativo en `operator-ui` o cliente Angular: flujo
completo `@inrupt/solid-client-authn-browser` contra el CSS del molde —
login, DPoP, refresh, logout, lectura de un recurso protegido. Hueco §T10
declarado; el spike lo convierte en conocimiento de equipo.
**CA** · Flujo completo contra molde local (nunca VPS) · tokens jamás en
localStorage sin decisión de mesa (anotar como riesgo, no resolver) ·
reporte de spike con lo que rompió.
**Dueño sugerido** · Z/mesh · dep: SM02.

| **WP-SM14** | P2 | Drill de portabilidad: migrar pod+IdP y sobrevivir |

**BRIEF** · La prueba de que DIC-1 no es teatro (§T9, §T10): jugador migra
de proveedor y su identidad/actas siguen valiendo. Sin drill, cualquier
elección de IdP es acto de fe.
**CA** · Migración completada en molde · huellas siguen verificando ·
ningún paso requiere permiso del proveedor de origen.
**Dueño sugerido** · mesa · dep: SM02, SM18.

---

## OLA D · CONTRATO

| **WP-SM04** | P1 | Mapa de reúso de vocabularios + namespace propio mínimo |

**BRIEF** · Aplicar §T3: tabla término-de-dominio → término estándar
(AS2/PROV-O/DCTERMS/FOAF) y lista mínima que exige namespace propio
(barrio, zona, acta, estados, peercard, línea). Publicación
dereferenciable, versionada y **con hash** (WP-O15 semántico). Backbone:
DIC-2 abierta.
**CA** · Cada término propio justifica por qué ningún estándar lo cubre ·
la URL del namespace resuelve y casa con su hash · alineación
`subClassOf`/`subPropertyOf` presente.
**Dueño sugerido** · Z (dominio) con revisión de mesa.

| **WP-SM05** | P1 | `@context` sobre los DTOs existentes (sin tocar shapes) |

**BRIEF** · JSON-LD por adición (§T4, §T5.2): `@context` estable para los
DTOs de `@zeus/protocol` (intents), `acta-kit` (acta/1) y snapshot — mismo
JSON válido como DTO y expandible a RDF. **Cero cambio** en shapes ni en
`huellaLedger` (DIC-4: bytes intactos por defecto).
**CA** · Mismo payload pasa JSON Schema Y expande a RDF sin pérdida ·
huellas antes/después idénticas byte a byte · hostil-omite: payload sin
`@context` sigue válido para el runtime actual.
**Dueño sugerido** · Z (`@zeus/protocol` · `acta-kit`) · dep: SM04.

| **WP-SM06** | P1 | Acta/1 como nodo-actividad (tabla de mapping) |

**BRIEF** · La estrella PROV/AS2 de §T6 como **tabla de correspondencia**
campo-a-campo desde `ActaDeBarrio v1` (`acta-kit` / ciudad) — mapeo, no
refactor. Los cinco intents como verbos; ledger `kind:'acta'` como anclaje
a L1. Entregable incluye la **tabla zona→rol del pod** (cierra el cabo de
DIC-5: dónde es fuente y dónde proyección, por zona).
**CA** · Ida-vuelta acta↔grafo sin pérdida · `huellaLedger` intacta ·
ningún campo nuevo obligatorio en acta/1 · tabla zona→rol entregada.
**Dueño sugerido** · Z/G · dep: SM04, SM05.

| **WP-SM13** | P2 | Shapes (SHACL/ShEx) como CA ejecutable del contrato |

**BRIEF** · El gemelo semántico del JSON Schema: validar grafos (actas,
perfiles) contra shapes, como gate. Hueco §T10: partir de cero, sin
recomendado.
**CA** · Un shape por clase publicada del namespace · gate falla con grafo
inválido (control negativo real).
**Dueño sugerido** · Z · dep: SM04.

---

## OLA E · PUENTES

| **WP-SM07** | P1 | Resource-bridge: recursos MCP ← pod (LDP passthrough) |

**BRIEF** · §T5.1: exponer recursos LDP como recursos MCP (URI y mimeType
passthrough; JSON-LD tal cual) en `player-mcp-kit`. Generaliza el patrón
ya vivo en ciudad (`ciudad://player/state|scene|casos`) a `pod://…` sin
inventar transporte. Dónde vive: DIC-6/DIC-7.
**CA** · `resources/read` ≡ GET autenticado (mismo status, mismo cuerpo) ·
el bridge no transforma payload (WP-O11.3) · denegado por ACL = denegado
por MCP, no maquillado.
**Dueño sugerido** · Z (`player-mcp-kit`) · dep: SM02.

| **WP-SM08** | P1 | Tool-bridge: tools MCP → pod/L2 con E/S RDFeable |

**BRIEF** · §T5.2: los tools existentes (`player_join/walk/announce/wake`)
declaran output schema (JSON Schema 2020-12, spec MCP RC 2026-07-28) con
el `@context` de SM05. Tool ≠ predicado (§T5): el efecto se asienta como
actividad (SM06), nunca como tripleta suelta.
**CA** · Toda salida de tool valida contra su output schema · la misma
salida expande a RDF · efecto persistido = actividad con actor y huella.
**Dueño sugerido** · Z (`player-mcp-kit`) · dep: SM05, SM06.

| **WP-SM09** | P0 | Auth relé: el token del jugador cabalga, el bridge no manda |

**BRIEF** · §T5.3: la credencial del actor (Solid-OIDC o peercard) viaja
por el transporte MCP y **decide el pod** (WAC/ACP). Prohibición educativa
explícita: token-dios del bridge sobre pods ajenos = CA-ANTI-AUTORIDAD
violado con exactitud (WP-O11.3/.4; D-O7: fail-closed en capacidades,
fail-open en topología).
**CA** · Los 5 puntos de WP-O11 aplicados al bridge con control positivo y
negativo · **hostil-omite**: probar la AUSENCIA de credencial, no solo la
inválida · cero credencial emitida o elevada por transportar.
**Dueño sugerido** · mesa (cambio de confianza ⇒ hostil-omite) · dep: SM07/08.

| **WP-SM10** | P2 | Traza: Trace Context → PROV (WP-O16 casi gratis) |

**BRIEF** · Propagar `traceparent` (W3C Trace Context, metadato MCP del
RC) hasta el nodo-actividad (§T5). Toda decisión de relay deja rastro
consultable sin privilegio (WP-O16).
**CA** · Llamada MCP → actividad con traza enlazada · leer el rastro no
requiere privilegio · relay sin traza = fallo de gate, no aviso.
**Dueño sugerido** · O · dep: SM06, SM08.

---

## OLA F · EVENTOS-ACL

| **WP-SM11** | P1 | Dos planos de eventos, puente declarado |

**BRIEF** · §T8: eventos de sala (`rooms`/`socket-core`, efímeros) y
cambios de recurso (Solid Notifications, soportado por CSS) son planos
distintos con puente explícito (node-red, superficie D-O2) — nunca fusión;
evita que node-red devenga fuente de verdad de datos (D-O9).
**CA** · Ningún cambio de recurso viaja SOLO como evento de sala · puente
= configuración visible · apagarlo no rompe ninguno de los dos planos
(degradación honesta, cf. WP-O17).
**Dueño sugerido** · O · dep: SM02.

| **WP-SM12** | P2 | Matriz de acceso: WAC vs ACP × zonas |

**BRIEF** · Matriz de casos reales (residente/visitante/corriente/dj ×
acta/censo/perfil) evaluada contra WAC y ACP (§T1.6). Invariante que
sobrevive a ambas: **ningún permiso se deriva de la zona** (WP-O14).
Cierra DIC-3 con datos.
**CA** · Matriz completa con caso hostil por celda sensible · expresada en
ambos modelos o constancia de dónde uno no llega · recomendación trazada a
filas concretas.
**Dueño sugerido** · mesa · dep: SM02, SM03.

---

## OLA G · FEDERACIÓN

| **WP-SM15** | P2 · mesa | Split autoría/orden (pre-diseño) |

**BRIEF** · §T7: intents firmados (autoría descentralizada) + autoridad
como relé-secuenciador (orden). Roza el «límite actual del engine» (una
room = una autoridad, `authority-kit`) — diseño de mesa, no código aún.
**CA** · Documento con los dos caminos y costes · cero implementación
antes de asiento · anti-forja por peercard demostrada en el papel.
**Dueño sugerido** · mesa · dep: SM18.

| **WP-SM21** | P2 · nuevo | Harness SSB ⇄ pod (el ancla alimenta al volumen, ejecutable) |

**BRIEF** · D-O9 hecho código de aprendizaje: arnés que siembra un pod
desde el feed/blobstore (L1→pod) y asienta actividades del pod hacia el
ledger (pod→L1 como rito explícito, nunca efecto colateral). Punto de
partida real: `mesh/blob-sync-harness` + `feed-kit`/`firehose-core`.
FIREHOSE entra por **segmento con cursor** (D-O9/T6), jamás fichero suelto.
**CA** · L1→pod reproducible (mismo ancla ⇒ mismo pod) · pod→L1 solo por
rito con actor y huella · el harness corre contra molde sin red externa.
**Dueño sugerido** · O (L1) + Z (harness) · dep: SM02, SM06.

| **WP-SM16** | P2 | Descubrimiento y reconstrucción del pod |

**BRIEF** · §T10: type indexes (cómo una app tercera localiza actas en pod
ajeno sin rutas hardcodeadas) + garantía pod-desde-ancla (consecuencia
operativa de §T2 sobre SM21).
**CA** · App tercera localiza actas sin hardcodear rutas · drill: pod
borrado → resembrado desde ancla → huellas idénticas.
**Dueño sugerido** · Z · dep: SM21.

---

## TRANSVERSAL

| **WP-SM22** | P1 · nuevo | Empaquetado: ¿kit nuevo o extender kits existentes? |

**BRIEF** · Material para cerrar DIC-7 con la regla D-O2 en la mano:
inventario de qué WPs de este pack piden código y si cabe en kits
existentes (`player-mcp-kit`, `acta-kit`, `http-contract`) o justifica
`solid-kit`/`webid-kit` nuevos — **solo** cuando exista la pieza real que
lo consuma. Incluye frontera de publish (allowlist, canal npm+Release con
hashes, consumidor limpio — régimen ya vivo en z-sdk).
**CA** · Tabla WP→destino de código con la pieza real consumidora
nombrada · cero kit propuesto sin consumidor · publish sujeto a allowlist
vigente.
**Dueño sugerido** · Z + G (notario/loader).

| **WP-SM23** | P1 · nuevo | Gobierno de dependencias Solid (licencias y supply-chain) |

**BRIEF** · Antes de que `@inrupt/*` o `@solid/community-server` entren al
árbol: auditoría de licencia (SPDX real), procedencia y peso de cada dep
nueva, con el criterio D-O3 (gobierno) y la lección O08/G74 (la licencia
es deuda de nacimiento si se hereda sin mirar). CSS es TS/FOSS; las libs
cliente también — pero se **verifica**, no se supone (INÉDITO).
**CA** · Tabla dep×licencia×gobierno×alternativa · cero dep añadida antes
de su fila · pin + hash en canal de import (cerco D-O8: import una vez).
**Dueño sugerido** · mesa (misma acta multi-mundo que la decisión de
licencia ya conocida).

---

## Correspondencia ronda 1 → ronda 2

SM01–SM16 conservan id y fondo (BRIEFs re-anclados a paquetes reales de
z-sdk). Nuevos: SM17 (glosario) · SM18 (attestation) · SM19 (login spike) ·
SM20 (CSS junto a pub) · SM21 (harness SSB⇄pod) · SM22 (empaquetado) ·
SM23 (deps/licencias) · SM24 (onboarding/katas). El cabo suelto de ronda 1
(tabla zona→rol de DIC-5) queda asignado a SM06.

*Pack de ronda. Nada es asiento: material para encolar con GO de cada
custodio.*
