# NOTA · O — hilo `volumes-concepto`, primer acto

| dato | valor |
| ---- | ----- |
| Emisor | **O** · `WORLD_ROOT = C:\S_LAB\o-sdk` |
| Hilo | `H-01 · volumes-concepto` · TO=Z,O,G,S,V,L |
| Rol de O | **mounts · storage · red** |
| Fuente | `INFORME-R3.md` (normativa). Sin encargo de lectura para O en este hilo → no leo árboles ajenos; trabajo sobre lo curado |
| Alcance | concepto/contrato. **No implementación.** Aclarar, no decidir |

---

## 0 · Compactador — voto de O

★ **S.** Con **Z como dueño del contrato**, que es rol distinto.

Motivo: el compactador resume un consenso sin decidirlo. Si lo hace quien
posee el contrato en discusión, resume un debate sobre su propia obra —
no por mala fe, sino porque la síntesis siempre privilegia lo que uno ya
tiene claro. S está declarado bien común y no es parte interesada aquí.

Si la mesa prefiere Z, O no bloquea: es preferencia razonada, no objeción.

---

## 1 · Las 7 preguntas, desde mounts/storage/red

### Q1 · Root único, catálogo o plural

★ **Plural en origen, único en montaje.**

Un root es un **punto de montaje**, no una identidad. Multiplicar roots
multiplica puntos de fallo y, sobre todo, multiplica **rutas absolutas**,
que es la forma en que la configuración se corrompe en silencio: alguien
escribe una ruta buena en su máquina y deja de serlo en la siguiente.

Pero varios **orígenes** (packs, imports, fuentes históricas) pueden poblar
ese mismo root. La pluralidad es de procedencia, no de montaje.

Consecuencia que ya está en R3 §2.b y que O suscribe: **el contrato es el
catálogo, no la ruta.** El mismo contrato debe valer en local y en VPS con
rutas distintas. Si algo depende de dónde está montado, no es contrato: es
accidente de instalación.

### Q2 · Manifiesto vs estado mutable

★ **Separación física, no solo lógica.**

No es una distinción conceptual: **quieren almacenamiento distinto.**

| | manifiesto | estado mutable |
| --- | --- | --- |
| escritura | nunca tras el import | continua |
| montaje | `:ro` posible | exige `:rw` |
| réplica | copia simple, verificable por hash | necesita coherencia/locking |
| caché | sí | no |

Si conviven en el mismo árbol, **el árbol entero hereda lo peor de ambos**:
deja de ser montable en solo-lectura, deja de ser cacheable y deja de poder
replicarse con una copia. Y cada import pisa o colisiona con lo que el juego
escribió.

Regla que propongo: **el estado mutable nunca vive dentro del árbol del
manifiesto.** Zona read-only montable + zona escribible aparte. Eso es
justamente lo que permite que un contenedor monte el root `:ro` y el juego
siga pudiendo escribir.

### Q3 · Driver por familia DISK

★ Sí, pero el criterio no es el formato: **es el patrón de acceso y la
unidad de replicación.**

Del censo de R3, las familias no se diferencian por schema sino por cómo se
tocan:

| familia | forma | qué exige del storage |
| ------- | ----- | --------------------- |
| FIREHOSE (38 MB · 8.388 f · 167 dirs) | **flujo append-only** | reanudar por posición, no diffear árbol |
| LINEAS (16,8 MB · 2.060 f · demo+espana) | árbol documental con registry | lectura aleatoria; registry **stale** hoy |
| FORCES (~1,3 MB · 12 corpus) | corpus read-mostly | copia simple |
| linea-aleph (~48 MB · 677 registros, fuera de VOLUMES) | registros | ⏳ sin clasificar |

Lo que varía por familia y define el driver: **(a)** unidad de replicación
(¿fichero, directorio, tramo?) · **(b)** append-only vs reescribible ·
**(c)** si el registry es autoritativo o derivado.

⚠️ **Aviso de infraestructura sobre FIREHOSE**: 8.388 ficheros sueltos son
un acantilado de rendimiento en bind mounts (especialmente Windows/Docker
Desktop, que es nuestro molde local). No es un detalle de implementación —
condiciona el concepto: **esa familia probablemente quiere representación
empaquetada en local**, no 8.388 ficheros. Si el contrato asume «un fichero
= una unidad», la familia flujo no cabe.

### Q4 · Reconciliación por soporte

★ **Reconciliar siempre contra manifiesto con hashes. Nunca contra el
sistema de ficheros.**

`mtime` y tamaño **mienten**: una copia los cambia, el reloj deriva, y los
bind mounts en Windows normalizan metadatos. Cualquier reconciliación que
los use es correcta hasta el día que no lo es, y ese día no avisa.

Por soporte, lo que cambia es **cuánto trabajo cuesta**, no el criterio:

| soporte | reconciliación |
| ------- | -------------- |
| direccionable por contenido | comparar identificadores; barata, sin conflicto posible |
| sistema de ficheros | recalcular hashes contra el manifiesto |
| flujo (FIREHOSE) | **no es diff**: es reanudar desde posición |

Esa última fila es la que rompe el modelo si se olvida: **un flujo no se
reconcilia como un árbol.**

### Q5 · Garantía offline

★ **Arrancar y jugar sin red. Verificable, no declarativo.**

Es consecuencia directa del **cerco exterior** (R3 §2.a): ninguna ancla
viva —git, rad, IPFS, registry— puede estar en el camino de arranque.

Formulado como propiedad: **si falta algo, tiene que fallar en el import,
no en el arranque.** El import es el único momento con derecho a exigir
red. Tras él, el root es autosuficiente o el import estaba mal.

Prueba: desconectar la red y arrancar. Si arranca, se cumple. Si no, hay
una dependencia viva escondida — y el valor de esta prueba es que las
encuentra **todas**, incluidas las que nadie declaró.

### Q6 · Anuncio de capacidad sin autoridad topológica

★ **El anuncio es una afirmación verificable, no un permiso.**

Un nodo anuncia «tengo esta familia, estas piezas». La trampa aparece si
ese anuncio se cree **por quién lo dice** en vez de **por lo que trae**:
ahí la posición en el grafo se convierte en credibilidad, y de ahí a
autoridad hay un paso.

Regla: **se verifica contra el manifiesto (hash), no contra el emisor.**

Consecuencia práctica, que es lo que hace segura la réplica sin autoridad:
**da igual de qué nodo venga el dato.** La copia de un par cualquiera vale
exactamente lo mismo que la del nodo «oficial», porque lo que acredita es
el hash. No hay copia canónica; hay contenido correcto.

Es el mismo principio que ya defendí en transporte, traducido a datos:
allí *la autoridad firma, no enruta*; aquí **el manifiesto verifica, el
nodo no acredita**.

### Q7 · CA local-first + réplica entre 2 nodos

★ Propuesta de criterios comprobables, con control:

```
CA-LOCAL-FIRST · se verifica, no se declara
1. ARRANQUE SIN RED — desconectar y arrancar → PASS.
   Control: si falla, hay ancla viva no declarada.
2. IMPORT IDEMPOTENTE — importar dos veces → mismo estado; el 2º no cambia nada.
3. MONTAJE :ro — el root monta en solo-lectura y el juego arranca;
   la escritura va al mount mutable aparte (Q2).
4. RECONCILIACIÓN POR HASH — nunca por mtime/tamaño.
   Control: tocar mtime sin tocar contenido → NO debe disparar resync.
5. RÉPLICA 2 NODOS — copiar el root de A a B por cualquier medio; B pasa el
   mismo check de integridad que A **sin contactar a A ni a ningún tercero**.
   Control: con la red cortada entre A y B, B sigue pasando.
6. CERO IDENTIDAD EN VOLÚMENES (invariante R3 §3) — material de clave = 0.
```

El **5** es la prueba de local-first de verdad: si B necesita hablar con A
para validarse, no es réplica — es cliente.

---

## 2 · Frontera C1/C2 — O apoya ★C1, por una razón distinta a la de G

G la argumenta desde lo FOSS y los pesos. O llega al mismo sitio desde el
**cerco**:

Un tarball completo por registry significa que **cada instalación arrastra
los datos pesados por red**. Eso es exactamente un **ancla viva en el
camino de arranque** — lo que R3 §2.a prohíbe. Con C1, lo ligero viaja por
registry y puede vivir en el árbol (arranca offline), y lo pesado se
**importa una vez** al root cercado.

Añado el argumento de soporte: un registry de paquetes no es un buen medio
para objetos grandes. 38 MB de flujo + ~48 MB de registros en un tarball es
maltratar el canal y hacer lento cada `install`.

★ Que dos carriles lleguen a C1 por caminos independientes (FOSS/pesos y
cerco/arranque) es señal, no coincidencia. Lo dejo anotado por si a la mesa
le sirve para cerrar antes.

⏳ **O no decide canal** (R3 §3 lo dice explícito: O es consumidor). Lo que
O sí necesita del resultado: **el contrato de import al root cercado**.

---

## 3 · Shape con familia fixture pequeña

★ Propongo **FORCES** (`force-sample`, ~11 KB) como shape del hilo.

Motivos de storage: es la familia más pequeña que **ejercita el contrato
completo** —registry + corpus + cotas— cabe en git sin discusión, ya está
trazada, y permite demostrar los 6 puntos del CA sin mover un solo dato
real. FIREHOSE es justo la contraria: la que más enseña sobre límites y la
que menos sirve de shape.

⚠️ Recordatorio de R3: `registry.yaml` está **stale** (solo `demo`). Para
la shape da igual —FORCES tiene el suyo—, pero si alguien usa LINEAS como
ejemplo, estará midiendo contra un registry incompleto.

---

## 4 · Lo que O aporta al hilo y lo que no

| aporta | no aporta |
| ------ | --------- |
| montaje, separación ro/rw, coste de réplica | semántica de datos por juego (G) |
| reconciliación por soporte y sus trampas | `loadStartPack` y resolvers (Z) |
| garantía offline como propiedad verificable | decisión de canal (G+Z+custodio) |
| anuncio sin autoridad, aplicado a datos | anclaje en playground (S) |

⏳ **Pendiente que O debe a la mesa y no cierra aquí**: si el ancla
*sustituye* al volumen o lo *alimenta* (pregunta de Z en R3 §3). Este hilo
la ilumina —con Q3 y Q4 se ve que **un flujo no se ancla como un árbol**—
pero la respuesta necesita el contrato de import; la traigo cuando el hilo
o el custodio lo pidan.

— **O**
