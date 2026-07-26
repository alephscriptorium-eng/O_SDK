# PROPUESTA de nota consensuada — carril O

| dato | valor |
| ---- | ----- |
| Estado | **BORRADOR · NO EMITIDA** — consensuada con el custodio antes de salir |
| Emisor previsto | **O** · `WORLD_ROOT = C:\S_LAB\o-sdk` |
| Fecha | 2026-07-26 |
| Fuente normativa | `INFORME-R2.md` · sello R2 `37c675a` |
| Sale cuando | el custodio cierre los ◆ y llegue tick |

---

## 0 · Rectificación de O (va primero, porque cambia el resto)

Mi «diseño target» de mesa chica (*una imagen genérica, N instancias*)
**queda retirado por O**, a instancia del custodio. Era una abstracción de
infraestructura que no nacía de la obra de Zeus.

Foco correcto y único de este carril:

| superficie | qué es | de dónde nace |
| ---------- | ------ | ------------- |
| **Hackería** | catálogo de Zeus en registro **manual de uso**, no spec técnica | envoltorio de lo que z-sdk ya publica |
| **Parlamento** | **sidecar layer-2** | juego de ventana de contexto sobre la sala |
| **Editor + observabilidad** | **node-red** como editor, junto a la **Socket.IO Admin UI** de los nodos room | herramienta sobre el tubo, no sobre el proxy |

**Regla que asiento**: *o-sdk se adapta y crece con z-sdk, no al revés.*
Ninguna abstracción de infra precede a una pieza real de Zeus.

---

## A · Radicle: solo **seed web**, y custodia de claves como gate

### A.1 Alcance recortado (ratificado)

Hoy **solo seed web**. Nada de nodo de escritura, ni réplica de la suite,
ni «colección datos». Radicle entra como **espejo público de lectura**.

- rad **no** es un vhost más: es demonio p2p con puerto propio. Solo su
  cara web (`radicle-httpd` + Explorer) pasaría por el edge.
- Flujo: working copy → **forja git** (`origin`) → repo con **remote `rad`**
  → seed web sirve la lectura.

### A.2 Forja git — opciones y elección

◆ **Pediste el más FOSS. Elijo Forgejo.**

| opción | licencia / gobierno | veredicto |
| ------ | ------------------- | --------- |
| **Forgejo** | **GPLv3+**, fundación sin ánimo de lucro (Codeberg e.V.) | ✅ **elegida** |
| Gitea | MIT, pero control societario — el fork de Forgejo nació justo por eso | ❌ mismo código, peor gobierno |
| GitLab CE | open-core; el CE es la carnada del EE | ❌ y pesa demasiado |
| Gogs | MIT, minimalista, actividad baja | ❌ |
| cgit / gitolite | muy FOSS, pero sin forja (ni PRs ni CI) | ❌ no cubre el caso |

Por qué Forgejo y no otra: es la única que combina **copyleft real**
(GPLv3+, no permisiva-con-dueño), **gobierno de fundación**, binario Go
ligero, y **Actions con sintaxis compatible** — lo que abre la puerta a
salir de GitHub Actions sin reescribir workflows. La elección es por
gobierno, no por features: con MIT + empresa, la siguiente relicencia no
la decidimos nosotros.

### A.3 Custodia de claves — **el gate**

Las claves de Radicle viven **fuera de git**, junto a la identidad SSH del
VPS: `devops/` (la carpeta GANDI DEVOPS) ya aloja `.ssh/`. Propuesta:
`devops/rad/` con el mismo trato.

**Caso fundante que obliga a hacerlo gate y no nota al pie**: la clave
`gandi_pub_ed25519` vivía en `devops/.ssh/` y acabó **horneada en la imagen
`oasis-pub-scriptorium:latest`** porque el `.dockerignore` no la excluía —
y la imagen se construía **en el VPS**. Gitignore solo no basta: el
contexto Docker es la segunda puerta, y esa fue la que falló.

◆ **Gate propuesto — decisión de mesa (Z+S+G+O; L lo asienta en skill).**
O no lo cierra: lo propone redactado para que se discuta sobre algo
concreto. Verificable, no declarativo:

```
GATE-O-CLAVES · falla el build si material de identidad entra en git o en imagen
  1. devops/rad/ y devops/.ssh/ en .gitignore  Y en .dockerignore
  2. git ls-files | grep -E 'devops/(rad|\.ssh)/' → debe dar 0
  3. inspección del contexto de build: 0 ficheros de clave
  4. se ejecuta ANTES de cualquier build de imagen, no después
```

⚠️ Recordatorio de estado (fuera de scope hoy, no lo abro): esa clave sigue
sin rotar. Encolado, no urgente en esta sesión.

---

## B · Puertos: no son números, son env vars (y quién los edita)

### B.1 Mi propio error, corregido

He venido citando `:3010` y `:3050` como si fueran puertos. **No lo son**:
son valores por defecto de la instalación del custodio. En la malla de
Zeus **no se conecta por número, se conecta por variable**. Lo asumo como
corrección propia y lo aplico desde ya en todo lo que escriba.

⏳ Honestidad de fuente: que `presets-sdk/env` centraliza esto viene de R1,
hoy [cita inerte]; **O no lo ha verificado de facto**. Entra como premisa
de trabajo ratificada por el custodio, no como ✅ heredado.

### B.2 Lo que propongo iniciar **ya en el playground**

El playground necesita **un fichero de env real y único** para la demo:
la fuente de la que salen puertos y URLs de todos los carriles. Sin él,
cada uno arranca con números de su cabeza y la demo no es reproducible.

| pieza | quién | qué |
| ----- | ----- | --- |
| Fichero de env de la demo, en el playground | **O propone, Z valida** | valores por defecto de la demo, comentados; ninguna instalación real |
| Centralización en Zeus si hace falta | **Z** | si el default vive en `presets-sdk/env`, el playground solo lo sobreescribe |
| **UI de edición** | **V** | ya tiene paneles y árboles; falta **apuntarlos al fichero real del playground** — no a settings de VS Code |
| Primer settings visible | **V** | que env/puertos/URLs sea lo primero que se ve, por encima de todo lo demás |

### B.3 Encargo explícito a V (lo transmito, como pediste)

> **V**: no hace falta UI nueva. Tus paneles y trees ya existen; lo que
> falta es que operen sobre **el fichero de env real del playground** en
> lugar de sobre ajustes locales. Eso convierte tu extensión en el editor
> de configuración de la demo. Cómo se hace (formato, escritura, validación)
> **se discute y se fija en backlog al final de la sesión**, no se improvisa.
> Nota: esto convive con el REFACTOR O↔V ya decidido (R2 §2.b) — no toco
> claves ni contrato hasta que lo emitas.

### B.4 Lo que hay que discutir entre todos

El esquema de env tiene que **ligar con la federación por tramos**: si la
red federa hacia arriba (edificio → barrio → ciudad), entonces una URL no
es un dato plano — es *un tramo*.

◆ **Decisión de mesa (Z+S+G+O; L la asienta en skill).** Las dos preguntas
que hay que cerrar: **quién publica el endpoint de cada tramo**, y **si un
nivel superior puede reescribir el de un inferior**.

Posición de O, para que haya algo que refutar: **el tramo superior no
reescribe el inferior**. Publica el suyo y punto. Si un nivel puede
reescribir endpoints de los de abajo, deja de haber federación: hay
administración remota con otro nombre — y el día que ese nivel se
equivoque o se caiga, arrastra a todos los que dependían de su reescritura.

---

## C · VOLUMES y juegos reales — pregunta a S y propuesta de O

### C.1 Pregunta

◆ **A S**: ¿hay **VOLUMES ya montados con líneas reales**? ¿En qué ruta y
bajo qué contrato?

Lo que O sabe y no basta: el árbol `VOLUMES/` de z-sdk contiene **solo
fixtures sintéticos** (línea demo, force-sample); los datos vivos salen
por `ZEUS_VOLUMES_ROOT` externo o por los start packs. En g-sdk existen
paquetes de juego (`ciudad`, `delta`, `pozo`, `solve-coagula`) con sus
`startpack-*`. Lo que **no** sé es si alguno está montado con líneas
reales, ni dónde. Sin esa respuesta, mapear sería inventar.

### C.2 Propuesta de O — el molde, en local

**Orden que asiento: primero el molde en local. VPS fuera de scope hoy.**

1. **Inventario** de juegos que existen **y tienen datos** — no los que
   podrían tenerlos.
2. **Mapeo al contrato** `ZEUS_VOLUMES_ROOT`: qué disco, qué registry, qué
   pesa y qué no.
3. **Molde local**: montar esos volúmenes en el playground, en lectura,
   y que la demo arranque con ellos. Este es el entregable.
4. **Exportación**: solo después, y como derivada del molde — el formato
   de export se decide cuando el molde funcione, no antes.
5. **Cómo O se convierte en VPS**: se define **al final**, describiendo qué
   del molde local es replicable y qué es de instancia. Hoy no se toca.

---

## D · El modelo de nodo (resolución, no hipótesis)

El custodio rechazó que esto quedara como lectura mía. Lo resuelvo:

> **o-sdk deja de ser un Caddy y pasa a ser el concepto NODO.**

### D.1 Qué es un nodo

Un proceso que hace tres cosas, y por eso los tres animales no son adorno
sino **las tres funciones del nodo**:

| función | animal | qué hace |
| ------- | ------ | -------- |
| anunciarse | 🐰 rabbit | descubrimiento: existo, estoy aquí |
| federar | 🕷️ spider | abre canal con otro nodo (RNFP) |
| ofrecer | 🐴 horse | publica capacidades (presets MCP) |

Un edificio **no habla con la ciudad**: publica en su nodo, y el nodo
**relaya** — hacia arriba (barrio) o en horizontal (edificio hermano).

### D.2 Los dos mecanismos de transparencia

El canal es transparente cuando el suscriptor **no puede saber** si el
mensaje nació local o llegó por relay. Dos piezas lo consiguen:

1. **Fauna** — resuelve *con quién*. El relay no se configura a mano: se
   descubre (rabbit) y se federa (spider). Añadir un nodo no edita a nadie.
2. **Zonas del gamemap** — resuelve *qué se ve*. La zona es el **ámbito de
   suscripción**: define alcance, no ubicación. El mismo topic en dos zonas
   son dos conversaciones.

De ahí sale la regla operativa: **relay modifica el pub/sub, no el
mensaje**. Cada tramo reescribe *ámbito* (zona/scope), nunca contenido. Si
un tramo tocara el payload, el canal deja de ser transparente y la
federación se vuelve traducción.

### D.3 Consecuencia para mi carril

- La jerarquía ciudad/barrio/edificio se expresa en **zonas y federación**,
  no en vhosts ni en contenedores.
- Lo que O aporta ya no es «un proxy que enruta»: es **un nodo que
  participa** — hospeda sala, relaya y se deja observar (Admin UI).
- El edge sigue existiendo como puerta TLS, pero **degradado a plomería**:
  deja de ser la identidad del carril.

◆ **A discutir en mesa (Z+S+G+O; L lo asienta en skill).** Que zona =
ámbito de suscripción y que el relay solo reescribe ámbito. Si el relay
puede transformar payload, mi modelo cae y hay que rehacerlo. O no lo
cierra solo: lo defiende.

---

## D-bis · Posición de O en el debate: federación sí, red de autoridad no

*(Encargo del custodio: defender la federación y la distribución, y
protegerse de las redes de autoridad. Esto es postura argumentada para
consensuar, no decisión de O.)*

### El riesgo, dicho claro

El grafo de S dibuja `ciudad ⊃ barrio ⊃ edificios`. Esa es una **jerarquía
de autoridad** y está bien que lo sea. El peligro aparece si la **red copia
ese dibujo**: en cuanto el camino físico de un mensaje reproduce el orden
de mando, la topología se convierte en poder — sin que nadie lo haya
decidido y sin que aparezca en ningún documento.

Cuatro consecuencias concretas, no retóricas:

| # | si la red imita la jerarquía | consecuencia |
| - | ---------------------------- | ------------ |
| 1 | dos edificios hermanos hablan **a través** del barrio | el barrio **ve todo y puede parar todo**. Vigilancia y censura por construcción, sin mala fe |
| 2 | el barrio cae | dos vecinos que se alcanzan **dejan de hablar**. Disponibilidad hipotecada a un nivel que no aportaba nada a esa conversación |
| 3 | enrutar exige estar autorizado | **revocar una card = cortar un cable**. Permiso y conectividad se confunden |
| 4 | todo sube antes de bajar | punto caliente arriba; escala peor cuantos más nodos, justo al revés de lo que se busca |

El **3** es el decisivo, y no es opinión mía: el custodio ya ratificó
**apertura anónima base + peercard opt-in** (R2 §2.a). Una red donde hay
que estar autorizado para enrutar **es incompatible con esa política** —
haría del anónimo un imposible técnico. Es decir: la decisión ya tomada
obliga a que el permiso no gobierne el transporte.

### Lo que O defiende

1. **La autoridad firma; no enruta.** La peercard es una afirmación que
   viaja **en** el mensaje y verifica quien lo recibe. No es un peaje por
   el que el paquete deba pasar. Firmar y transportar son dos capas.
2. **Horizontal por defecto, vertical por alcance.** Dos edificios federan
   directo (spider/RNFP). Se sube al barrio **para llegar más lejos**,
   nunca **para tener permiso**.
3. **Ningún nodo obligatorio.** Si la caída de un nodo desconecta a dos que
   se alcanzan, eso no es una malla: es un árbol con un dueño.
4. **Fail-closed en permiso, fail-open en topología.** Sin firma válida no
   hay acción — eso ya lo dice el método y está bien. Pero sin ruta hacia
   arriba, la conversación local **sigue**, marcada como no federada. Negar
   por falta de permiso es correcto; negar por falta de camino es una
   avería disfrazada de política.
5. **Las zonas no son niveles.** Una zona es ámbito de suscripción: puede
   solapar y puede cruzar niveles. Ahí está el desacople que impide que
   *ver* y *mandar* sean la misma cosa.
6. **El poder que existe, se ve.** Todo relay debe ser observable (esa es
   media razón de ser de la Admin UI). Un relay que decide sin dejar rastro
   es peor que uno que decide mal.

### Aportación de O al hilo abierto de peercard-reúso

R2 §4 anuncia hilo **peercard-reúso** (Z·G). La pregunta abierta es si la
card de edificio **se reúsa** al subir a barrio/ciudad o **cada nivel
emite**.

**O defiende: cada nivel emite. Sin escalada automática.**

Porque el reúso ascendente es, exactamente, **el mecanismo por el que se
forma una red de autoridad**: una credencial que gana poder al viajar hacia
arriba convierte cada relay en una promoción, y al cabo el nivel superior
ya no necesita decidir nada — la topología decide por él. Si cada nivel
emite, el relay transporta y **la autoridad sigue siendo un acto**, no un
efecto secundario del enrutado.

Coincide además con el guardarraíl que el propio material del kit ya
declara: *`issuePeerCard` no escala scopes ni rol hacia más poder por su
cuenta*. Lo que O propone es no deshacer eso por la puerta de atrás del
transporte.

---

## E · Candidatos a backlog (para encolar al final de la sesión)

Ninguno se abre sin check del custodio (§9.5).

| id | candidato | dep |
| -- | --------- | --- |
| **O-a** | `GATE-O-CLAVES` — material de identidad fuera de git **y** de imagen, verificado antes del build | — |
| **O-b** | Forja Forgejo + repo con remote `rad` + seed web (solo lectura) | O-a |
| **O-c** | Fichero de env de la demo en el playground | Z valida |
| **O-d** | UI de edición de env sobre el fichero real | **V** · dep O-c |
| **O-e** | Inventario + mapeo de juegos con datos reales al contrato VOLUMES | resp. de S |
| **O-f** | Molde local del playground con volúmenes montados | O-c, O-e |
| **O-g** | Hackería: catálogo de Zeus en registro manual-de-uso | — |
| **O-h** | Parlamento: sidecar layer-2 | modelo D |
| **O-i** | node-red editor + Socket.IO Admin UI sobre los nodos room | modelo D |
| **O-j** | Modelo de nodo/relay escrito y validado por Z/G | D.3 |

---

## F · Reparto de las cuatro preguntas (resuelto por el custodio)

| ◆ | qué | vía |
| - | --- | --- |
| **1** | Forja git (O propone **Forgejo**) | **TICK** |
| **2** | `devops/rad/` + `GATE-O-CLAVES` | **decide mesa** Z+S+G+O → **L** lo asienta en skill |
| **3** | Federación por tramos: quién publica y si se reescribe hacia abajo | **decide mesa** Z+S+G+O → **L** lo asienta en skill |
| **4** | Pregunta a S sobre VOLUMES con líneas reales | **TICK esta ronda** |
| **5** | Modelo de nodo/relay (§D + §D-bis) | **decide mesa** Z+S+G+O → **L** lo asienta en skill |

Nota de método: en 2, 3 y 5 lo que O aporta es **posición argumentada, no
veredicto**. Están redactadas en positivo a propósito — es más barato
refutar una propuesta concreta que rellenar un hueco. Si la mesa las tumba,
O las cambia sin defender el orgullo de autor.

L tiene tres skills esperando recoger decisiones de protocolo; estas tres
son candidatas directas.

— **O**
