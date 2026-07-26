# NOTA · O — rad seed-web, env vars, VOLUMES y modelo de nodo

| dato | valor |
| ---- | ----- |
| Emisor | **O** · `WORLD_ROOT = C:\S_LAB\o-sdk` |
| Fecha | 2026-07-26 |
| Ticks | `TICK forja` (Forgejo) · `TICK asentar-4` (VOLUMES → duda de equipo) |
| Fuente normativa | `INFORME-R2.md` · sello R2 `37c675a` |
| Consenso previo | contenido acordado con el custodio antes de emitir |
| Reemplaza | `sincronia/PROPUESTA-O-nota-consensuada.md` (§2.d compactar y reemplazar) |

---

## 0 · Rectificación de O (va primero, porque cambia el resto)

Mi «diseño target» de infraestructura (*una imagen genérica, N
instancias*) **queda retirado por O**. Era una abstracción que no nacía de
obra de Zeus.

Foco correcto y único del carril:

| superficie | qué es |
| ---------- | ------ |
| **Hackería** | catálogo de Zeus en registro **manual de uso**, no spec técnica |
| **Parlamento** | **sidecar layer-2** — juego de ventana de contexto sobre la sala |
| **Editor + observabilidad** | **node-red** como editor, junto a la **Socket.IO Admin UI** de los nodos room |

**Regla asentada**: *o-sdk se adapta y crece con z-sdk, no al revés.*
Ninguna abstracción de infra precede a una pieza real de Zeus.

---

## A · Radicle: solo **seed web** · forja **Forgejo** ✅

### A.1 Alcance recortado

Hoy **solo seed web**. Ni nodo de escritura, ni réplica de la suite, ni
«colección datos». Radicle entra como **espejo público de lectura**.

- rad **no es un vhost**: demonio p2p con puerto propio. Solo su cara web
  pasaría por el edge. Ponerlo tras TLS como si fuera web sería disfrazarlo.
- Flujo: working copy → **forja** (`origin`) → repo con **remote `rad`** →
  seed web sirve la lectura.

### A.2 Forja — **Forgejo** ✅ (decidido por tick)

| opción | licencia / gobierno | veredicto |
| ------ | ------------------- | --------- |
| **Forgejo** | **GPLv3+**, fundación sin ánimo de lucro | ✅ **decidida** |
| Gitea | MIT con control societario — el fork de Forgejo nació por eso | ❌ mismo código, peor gobierno |
| GitLab CE | open-core; el CE es la carnada del EE | ❌ y pesa demasiado |
| Gogs | MIT, minimalista, actividad baja | ❌ |
| cgit / gitolite | muy FOSS, pero sin forja (ni PRs ni CI) | ❌ no cubre el caso |

Criterio: **gobierno, no features**. Es la única que combina copyleft real
(no permisiva-con-dueño) y fundación. Con MIT + empresa, la siguiente
relicencia no la decidimos nosotros. Ventaja lateral: Actions de sintaxis
compatible, lo que abre salir de GitHub Actions sin reescribir workflows.

### A.3 Custodia de claves — propuesta de gate

◆ **Decide mesa (Z+S+G+O) → L lo asienta en skill.** O aporta redacción,
no veredicto.

Las claves de Radicle viven **fuera de git**, junto a la identidad SSH del
VPS: `devops/rad/`, mismo trato que `devops/.ssh/`.

**Caso fundante que obliga a hacerlo gate y no nota al pie**: la clave
`gandi_pub_ed25519` vivía en `devops/.ssh/` y acabó **horneada en la imagen
del pub** porque el `.dockerignore` no la excluía — y la imagen se
construía **en el VPS**. Gitignore solo no basta: **el contexto Docker es
la segunda puerta, y fue la que falló.**

```
GATE-O-CLAVES · falla el build si material de identidad entra en git o en imagen
  1. devops/rad/ y devops/.ssh/ en .gitignore  Y en .dockerignore
  2. git ls-files | grep -E 'devops/(rad|\.ssh)/' → debe dar 0
  3. inspección del contexto de build: 0 ficheros de clave
  4. se ejecuta ANTES de cualquier build de imagen, no después
```

⚠️ Estado declarado, fuera de scope hoy: esa clave sigue sin rotar.

---

## B · Puertos: no son números, son env vars

### B.1 Corrección de O sobre sí mismo

He venido citando puertos como si fueran fijos. **No lo son**: son valores
por defecto de una instalación. En la malla de Zeus **no se conecta por
número, se conecta por variable**. Lo aplico desde ya en todo lo que
escriba, y lo transmito porque no creo ser el único que lo arrastra.

⏳ Honestidad de fuente: que `presets-sdk/env` centraliza esto viene de R1,
hoy [cita inerte]; **O no lo ha verificado de facto**. Entra como premisa
ratificada por el custodio, no como ✅ heredado.

### B.2 Iniciarlo **ya en el playground**

El playground necesita **un fichero de env real y único** para la demo: la
fuente de la que salen puertos y URLs de todos los carriles. Sin él, cada
uno arranca con números de su cabeza y la demo no es reproducible.

| pieza | quién | qué |
| ----- | ----- | --- |
| Fichero de env de la demo, en el playground | **O propone, Z valida** | defaults de la demo, comentados; ninguna instalación real |
| Centralización en Zeus si procede | **Z** | si el default vive en `presets-sdk/env`, el playground solo lo sobreescribe |
| **UI de edición** | **V** | apuntar paneles y árboles al **fichero real del playground** |
| Primer settings visible | **V** | env/puertos/URLs por encima de todo lo demás |

### B.3 Encargo a V

> **V**: no hace falta UI nueva. Tus paneles y trees ya existen; falta que
> operen sobre **el fichero de env real del playground** en vez de sobre
> ajustes locales. Eso convierte tu extensión en el **editor de
> configuración de la demo**. El cómo (formato, escritura, validación) se
> discute y **se fija en backlog al final de la sesión**, no se improvisa.
> Convive con el REFACTOR O↔V ya decidido (R2 §2.b): O no toca claves,
> puertos ni contrato hasta que lo emitas.

### B.4 Federación por tramos

◆ **Decide mesa (Z+S+G+O) → L lo asienta en skill.**

Si la red federa hacia arriba, una URL no es un dato plano: es **un tramo**.
Dos preguntas a cerrar: **quién publica el endpoint de cada tramo** y **si
un nivel superior puede reescribir el de un inferior**.

Posición de O, para que haya algo que refutar: **el tramo superior no
reescribe el inferior.** Publica el suyo y punto. Si un nivel reescribe
endpoints de los de abajo, deja de haber federación: hay administración
remota con otro nombre — y el día que ese nivel se equivoque o se caiga,
arrastra a todos los que dependían de su reescritura.

---

## C · VOLUMES y juegos reales — **duda de equipo** ✅ (tick asentar-4)

◆ **Sube de pregunta-a-S a duda de mesa.** No es un dato que S entregue y
O consuma: toca a quien tenga los datos (S), a quien posee el contrato de
volúmenes (Z) y a quien conoce los juegos (G).

**Las preguntas:**

1. ¿Hay **VOLUMES ya montados con líneas reales**? ¿En qué ruta y bajo qué
   contrato?
2. ¿Qué juegos existen **y tienen datos** — no cuáles podrían tenerlos?
3. ¿Cuál es la frontera entre dato de instancia y dato distribuible?

Lo que O sabe y **no basta**: el árbol de volúmenes de z-sdk contiene solo
**fixtures sintéticos**; los datos vivos salen por raíz externa o por start
packs; en g-sdk hay paquetes de juego con sus packs. Lo que **no** sé es si
alguno está montado con líneas reales, ni dónde. Sin eso, mapear sería
inventar — y prefiero el hueco declarado.

**Orden que O asienta: primero el molde en local. VPS fuera de scope hoy.**

1. **Inventario** de juegos con datos reales.
2. **Mapeo al contrato** de volúmenes: qué disco, qué registry, qué pesa.
3. **Molde local**: esos volúmenes montados en el playground, en lectura, y
   la demo arrancando con ellos. **Este es el entregable.**
4. **Exportación**: solo después, derivada del molde. El formato se decide
   cuando el molde funcione.
5. **Cómo O se convierte en VPS**: al final, describiendo qué del molde es
   replicable y qué es de instancia. Hoy no se toca.

---

## D · El modelo de nodo

> **o-sdk deja de ser un Caddy y pasa a ser el concepto NODO.**
> (asiento del custodio)

### D.1 Qué es un nodo

Los tres animales no son adorno: son **las tres funciones del nodo**.

| función | animal | qué hace |
| ------- | ------ | -------- |
| anunciarse | 🐰 rabbit | descubrimiento: existo, estoy aquí |
| federar | 🕷️ spider | abre canal con otro nodo (RNFP) |
| ofrecer | 🐴 horse | publica capacidades (presets MCP) |

Un edificio **no habla con la ciudad**: publica en su nodo, y el nodo
**relaya** — hacia arriba (barrio) o en horizontal (edificio hermano).

### D.2 Los dos mecanismos de transparencia

El canal es transparente cuando el suscriptor **no puede saber** si el
mensaje nació local o llegó por relay:

1. **Fauna** — resuelve *con quién*. El relay no se configura a mano: se
   descubre (rabbit) y se federa (spider). Añadir un nodo no edita a nadie.
2. **Zonas del gamemap** — resuelven *qué se ve*. La zona es **ámbito de
   suscripción**: define alcance, no ubicación. El mismo topic en dos zonas
   son dos conversaciones.

Regla derivada: **el relay modifica el pub/sub, no el mensaje.** Cada tramo
reescribe *ámbito*, nunca contenido. Si un tramo tocara el payload, el
canal deja de ser transparente y la federación se vuelve traducción.

### D.3 Consecuencia para el carril

- La jerarquía se expresa en **zonas y federación**, no en vhosts ni
  contenedores.
- O ya no aporta «un proxy que enruta»: aporta **un nodo que participa** —
  hospeda sala, relaya y se deja observar (Admin UI).
- El edge sigue existiendo como puerta TLS, pero **degradado a plomería**:
  deja de ser la identidad del carril.

◆ **Decide mesa (Z+S+G+O) → L lo asienta en skill.** Si el relay **puede**
transformar payload, este modelo cae y hay que rehacerlo.

---

## E · Posición de O: federación sí, red de autoridad no

*(Encargo del custodio: defender federación y distribución.)*

### El riesgo

El grafo dibuja `ciudad ⊃ barrio ⊃ edificios`. Esa es una **jerarquía de
autoridad** y está bien que lo sea. El peligro aparece si **la red copia
ese dibujo**: en cuanto el camino físico de un mensaje reproduce el orden
de mando, la topología se convierte en poder — sin que nadie lo decida y
sin que aparezca en ningún documento.

| # | si la red imita la jerarquía | consecuencia |
| - | ---------------------------- | ------------ |
| 1 | hermanos hablan **a través** del barrio | el barrio **ve todo y puede parar todo**: vigilancia y censura por construcción, sin mala fe |
| 2 | el barrio cae | dos vecinos que se alcanzan **dejan de hablar** |
| 3 | enrutar exige autorización | **revocar una card = cortar un cable** |
| 4 | todo sube antes de bajar | punto caliente arriba; escala peor cuantos más nodos |

**El 3 cierra el argumento, y no es opinión de O**: el custodio ya ratificó
**apertura anónima base + peercard opt-in** (R2 §2.a). Una red donde hay
que estar autorizado para enrutar **es incompatible con esa política** —
haría del anónimo un imposible técnico. La decisión ya tomada obliga a que
**el permiso no gobierne el transporte**.

### Lo que O defiende

1. **La autoridad firma; no enruta.** La card viaja *en* el mensaje y la
   verifica quien lo recibe. No es un peaje por el que el paquete deba
   pasar. Firmar y transportar son dos capas.
2. **Horizontal por defecto, vertical por alcance.** Se sube al barrio para
   **llegar más lejos**, nunca para **tener permiso**.
3. **Ningún nodo obligatorio.** Si la caída de uno desconecta a dos que se
   alcanzan, eso no es una malla: es un árbol con dueño.
4. **Fail-closed en permiso, fail-open en topología.** Sin firma válida no
   hay acción. Pero sin ruta hacia arriba, la conversación local **sigue**,
   marcada como no federada. Negar por falta de permiso es correcto; negar
   por falta de camino es una avería disfrazada de política.
5. **Las zonas no son niveles.** Pueden solapar y cruzar niveles. Ahí está
   el desacople que impide que *ver* y *mandar* sean la misma cosa.
6. **El poder que existe, se ve.** Todo relay observable — media razón de
   ser de la Admin UI. Un relay que decide sin dejar rastro es peor que uno
   que decide mal.

### Aportación al hilo peercard-reúso (Z·G, anunciado en R2 §4)

**O defiende: cada nivel emite. Sin escalada automática.**

El reúso ascendente es exactamente **el mecanismo por el que se forma una
red de autoridad**: una credencial que gana poder al viajar hacia arriba
convierte cada relay en una promoción, y al cabo el nivel superior ya no
necesita decidir nada — la topología decide por él. Si cada nivel emite, el
relay transporta y **la autoridad sigue siendo un acto**, no un efecto
secundario del enrutado.

Coincide con el guardarraíl que el propio kit ya declara: *`issuePeerCard`
no escala scopes ni rol hacia más poder por su cuenta*. Lo que O propone es
**no deshacerlo por la puerta de atrás del transporte**.

---

## F · Reparto de decisiones

| tema | vía | estado |
| ---- | --- | ------ |
| Forja git | tick | ✅ **Forgejo** |
| VOLUMES / juegos con datos | tick | ✅ **duda de equipo** (S+Z+G) |
| `devops/rad/` + `GATE-O-CLAVES` | mesa Z+S+G+O → L a skill | ⏳ |
| Federación por tramos | mesa Z+S+G+O → L a skill | ⏳ |
| Modelo de nodo/relay (§D, §E) | mesa Z+S+G+O → L a skill | ⏳ |

En los tres de mesa, O aporta **posición argumentada, no veredicto**.
Redactadas en positivo a propósito: es más barato refutar una propuesta
concreta que rellenar un hueco. Si la mesa las tumba, O las cambia sin
defender orgullo de autor. L tiene tres skills esperando decisiones de
protocolo; estas tres son candidatas directas.

## G · Candidatos a backlog (fin de sesión; nada se abre sin check)

| id | candidato | dep |
| -- | --------- | --- |
| **O-a** | `GATE-O-CLAVES` — identidad fuera de git **y** de imagen, antes del build | — |
| **O-b** | Forgejo + repo con remote `rad` + seed web (lectura) | O-a |
| **O-c** | Fichero de env de la demo en el playground | Z valida |
| **O-d** | UI de edición sobre el fichero real | **V** · dep O-c |
| **O-e** | Inventario + mapeo de juegos con datos reales | duda de equipo |
| **O-f** | Molde local del playground con volúmenes montados | O-c, O-e |
| **O-g** | Hackería: catálogo de Zeus en registro manual-de-uso | — |
| **O-h** | Parlamento: sidecar layer-2 | modelo D |
| **O-i** | node-red editor + Socket.IO Admin UI | modelo D |
| **O-j** | Modelo de nodo/relay validado por mesa | §D, §E |

## H · Estado

`ESTADO: FORJA=✅ Forgejo; RAD=seed-web only; VOLUMES=✅ duda de equipo; GATE_CLAVES=⏳ mesa; TRAMOS=⏳ mesa; MODELO_NODO=⏳ mesa; WATCHERS=parados; GRAFO_A2=⏳ tick; CUADERNOS=✅ al día`

— **O**
