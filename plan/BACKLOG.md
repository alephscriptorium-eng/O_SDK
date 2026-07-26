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
| Régimen | **nada se abre sin GO del custodio**; encolar de más cuesta cero |

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
Dep: endpoint del nodo de prueba · resolución de **WP-O13**.

| **WP-O13** | **P0 · ⛔** | U93: separar transporte de permiso |

**BRIEF** · Discrepancia registrada: el torno de `@zeus/webrtc-signaling`
exige peer-card para `room-join`, offer, answer e ICE — **la card habilita
el cable**, contra la política de apertura anónima. O **no diseña sobre
esto** hasta que Z se pronuncie.
**CA** · Transporte y signaling anónimos separados de capacidades opt-in ·
verificación fuerte **cuando** haya card · el CA de WP-O11 punto 2 pasa.
⛔ Dependencia dura de Z. No es trabajo de O; se encola porque **bloquea** a O.

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
Dueño: **V**. O aporta contrato.

| **WP-O22** | **P0** | Compose del laboratorio |

**BRIEF** · Levantar en Docker Desktop el runtime que la demo necesita,
**parametrizado por env** (WP-O20), sin declarar ningún concepto de Ciudad
en YAML. Barrio, rol y ancla viven en el carril dueño del modelo.
**CA** · Un comando levanta el lab · cero literales · cero conceptos de
Ciudad en YAML · `CA-ANTI-AUTORIDAD` pasa sobre el resultado.
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
import no pisa curación humana.

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
detalle de implementación: condiciona el contrato. Si el contrato asume «un
fichero = una unidad», la familia flujo no cabe.
**CA** · Medición antes/después en el molde real · el contrato admite
representación empaquetada sin cambiar el catálogo.
Deuda declarada de O (T6).

| **WP-O35** | **P0** | T5: ¿el ancla sustituye al volumen o lo alimenta? |

**BRIEF** · **Deuda mía con la mesa** (compromiso R4 §1). Con el firehose
siendo *flujo* y no artefacto, hay que fijar **unidad de anclaje antes de
tocar transporte**. Requiere el contrato de import de Z.
**CA** · Respuesta con las tres familias contrastadas · declara qué se
ancla (unidad) antes de decidir por dónde viaja.
Dep: contrato de import (Z).

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
Dueño tentativo: V + mesa. O aporta el lado de storage.

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
el contenedor no ve material de identidad.

| **WP-O51** | **P1** | Cristalización L2→L1 como rito |

**BRIEF** · El único camino de la sesión al registro permanente. O está al
otro lado de esa puerta, recibiendo — no la abre, la sostiene.
**CA** · Un solo verbo de entrada a L1 · nada cristaliza por efecto
colateral · lo cristalizado declara su origen.

| **WP-O52** | **P1** | Panel: quitar el poder que no necesita |

**BRIEF** · El panel monta el socket de Docker en lectura-escritura y corre
como root: quien controle ese proceso puede crear un contenedor
privilegiado. No es «una API de restart».
**CA** · El proceso ya no ve el socket crudo · control: intento de crear
contenedor privilegiado → denegado · la capacidad se reduce, no se
documenta.

| **WP-O53** | **P1** | Invites sin coste por visita |

**BRIEF** · Un GET anónimo dispara una operación cara contra el pub y el
fallo no se cachea; además el resultado cacheado no expira nunca.
**CA** · N peticiones anónimas → 1 operación · caché negativa con
caducidad · invite muerto detectado, no servido.

| **WP-O54** | **P2** | Salud y métricas del nodo |

**BRIEF** · Señal observable `OK/DEGRADED/FAIL`; sin señal trazada **no** se
declara OK.
**CA** · Cada estado con su evidencia · ausencia de señal ≠ salud.

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

| **WP-O94** | **P2** | Segundo nodo (prueba de que no somos el centro) |

**BRIEF** · La prueba definitiva del modelo: un nodo hermano que federa en
horizontal. Si al apagar el nuestro dos partes dejan de hablarse, el modelo
está mal.
**CA** · Dos nodos federados · apagar cualquiera no aísla a los demás ·
`CA-ANTI-AUTORIDAD` punto 1 verificado **en vivo**, no en papel.

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

## Conteo

| prioridad | WPs |
| --------- | --- |
| **P0** | 11 |
| **P1** | 32 |
| **P2** | 21 |
| **total** | **64** |

**P0 (11)**: `WP-O01` fundar plan · `WP-O10` modelo de nodo · `WP-O11`
CA-anti-autoridad · `WP-O12` entrada al grafo (A2) · `WP-O13` U93 (⛔ Z) ·
`WP-O20` env único · `WP-O22` compose del lab · `WP-O30` contrato de
montaje · `WP-O31` separación física · `WP-O35` T5 (deuda mía) · `WP-O70`
gate de claves.

Distribución por lane: L0 6 · L1 9 · L2 7 · L3 10 · L4 6 · L5 5 · L6 6 ·
L7 6 · L8 4 · L9 5.

De ellos: 2 con `BLOQUEA:` (WP-O10, WP-O70) · 2 con ⛔ (WP-O13 dependencia
de Z · WP-O73 bloqueado por el custodio).

— **O**
