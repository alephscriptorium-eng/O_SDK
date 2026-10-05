---
title: Manual de bienvenida a la red
outline: [2, 2]
---

::: info Manual de la red · materiales oficiales de Oasis
Este manual es **el de la red**, no el de este SDK: vale para cualquier pub de Oasis, lo monte
quien lo monte. Está hecho con los materiales del propio proyecto Oasis (las fuentes van al final)
y aquí se publica tal cual, como plantilla: los huecos de la primera caja y `<dominio>` los
rellena cada pub.

Lo que cambia si tu pub corre con este SDK está aparte, en la puerta
[Habitante](/roles/habitante#si-tu-pub-corre-con-este-sdk). Lo que esta página añade al texto
original va siempre en cajas como esta, tituladas «Nota del portal».
:::

# Oasis para Nodo — Manual de bienvenida y uso (español)

*Guía práctica para el nodo: instala Oasis en tu móvil, únete a la red del campamento y mantente en contacto con toda la plaza — incluso sin internet.*

> **RELLENAR ANTES DE IMPRIMIR**
> Nombre del Wi-Fi de el nodo: `________________`
> Contraseña del Wi-Fi: `________________`
> Ubicación de la mesa técnica / hacklab: `________________`
> Dónde conseguir la app hoy (persona / QR): `________________`

---

## 1. Qué es Oasis (y por qué lo usamos en la plaza)

Oasis es una **red social libre, cifrada y entre iguales (P2P)**. No hay:

- **Ningún servidor central** que alguien pueda apagar, incautar o pedir por
  orden judicial.
- **Ninguna cuenta** que te puedan cerrar: sin usuario, sin contraseña, sin
  correo, sin número de teléfono. Tu identidad es una clave secreta que se
  genera en tu dispositivo.
- **Ninguna empresa** con tus datos: todo lo que publicas vive en tu
  dispositivo y en los de la gente que te sigue — y sigue funcionando
  **sin conexión**.

Cuando la red móvil está saturada, interferida o caída, Oasis en el Wi-Fi de
el nodo sigue sincronizando: los móviles se encuentran en la misma red
**automáticamente**, sin tocar internet. Cuando dos de vosotros os cruzáis
después, vuestros Oasis intercambian todo lo que se perdieron. Los mensajes
saltan de móvil en móvil hasta llegar a todos — por eso se llama red de
*cotilleo* (*gossip*).

La ventana pública de nuestra red es **`https://<dominio>/c`** —
cualquiera con un navegador puede leer allí lo que publica el campamento
(solo lectura, sin cuenta, sin app).

---

## 2. Qué necesitas

| | |
|---|---|
| **Móvil** | Android. (El iPhone no puede ejecutar Oasis en sí — ver §11.) |
| **Espacio** | Unos cientos de MB libres para la app, más sitio para tu contenido — con 1 GB vas con margen. |
| **Internet** | Solo para descargar la app; mejor por Wi-Fi. Después, Oasis funciona sin conexión. |
| **Tiempo** | 10–15 minutos la primera vez. |

**No** necesitas: correo electrónico, número de teléfono, datos personales de
ningún tipo, ni permisos de root en el móvil.

---

## 3. Instala la app de Oasis en tu Android

Oasis para Android es una app normal (un archivo **APK**). **No** necesitas
Termux, ni un terminal, ni ningún paso técnico: consigue el archivo, ábrelo
y listo. No se crea ninguna cuenta en ningún sitio — tu identidad se genera
después, dentro del propio Oasis.

### Paso 1 — Consigue la app (elige una; es la misma app)

1. **En el nodo — recomendado.** La mesa técnica, o cualquier compañero
   que ya la tenga, te comparte el archivo APK: Nearby Share, un código QR,
   cable o tarjeta SD. Nada pasa por Google, y funciona aunque lo único que
   tengamos sea el Wi-Fi del campamento.
2. **Desde las *releases* del proyecto.** Abre
   `https://code.03c8.net/KrakensLab/oasis/releases` y descarga el
   `oasis-v….apk` más reciente. Cada versión publica al lado su *checksum*
   — la mesa técnica puede verificar tu copia.
3. **Desde Google Play.** Busca **«Oasis Social Network»**
   (`com.solarnethub.oasis`). La misma app libre, sin publicidad ni
   rastreadores — pero Google se entera de que la instalaste.

### Paso 2 — Instala el APK (2 min)

1. Toca el archivo (normalmente está en **Descargas**).
2. La primera vez, Android pide permiso para instalar desde esa app —
   concédeselo solo para esta instalación (*Instalar aplicaciones
   desconocidas* → tu app de Archivos → *Permitir desde esta fuente*).
3. Si **Play Protect** se queja, elige *Más detalles → Instalar de todas
   formas*. Se queja de toda app que no venga de su tienda; este es el APK
   oficial, verificable contra el *checksum* de la página de *releases*.
4. Pulsa **Instalar**. (Desde Google Play, nada de esto ocurre.)

### Paso 3 — Ábrela y déjala a punto (5 min)

- En el primer arranque, Oasis **genera tu identidad sola**: un par de
  claves. Sin registro, nada que rellenar. Ya eres un *habitante*.
- Ve a **Settings**: elige tu **idioma** (español incluido — los menús se
  traducen solos; en este manual los nombres de menú aparecen en inglés) y
  el tema **Mobile** — la interfaz está pensada para pantallas pequeñas.
- Ponte un nombre público y, si quieres, un avatar. Ese es el único
  «perfil» que existe: ni edad, ni ubicación, ni género — nada más se
  pregunta jamás.
- Las fotos que publiques se limpian **automáticamente**: las coordenadas
  GPS y otros metadatos (EXIF) se eliminan antes de que nada salga de tu
  móvil.
- Para que la app siga sincronizando mientras el móvil duerme: Ajustes de
  Android → Aplicaciones → Oasis → Batería → **Sin restricciones** (o
  *Permitir actividad en segundo plano*). Un minuto; hazlo ahora.

**Oasis también funciona en portátiles** — y, para perfiles avanzados,
dentro de Termux en cualquier Android. Misma red, mismas invitaciones.
Pregunta en la mesa técnica, o mira el §10.

---

## 4. Únete a la red de la base

Oasis es una red de *confianza*: nadie se registra en un formulario —
alguien te abre la puerta.

1. **Consigue un código de invitación.** Acércate a la **mesa técnica** de
   el nodo (ubicación al principio de esta guía) o pídeselo a quien ya
   esté dentro. Los códigos son una cadena larga; puede ser de un solo uso o
   compartido para toda una asamblea.
2. En la app, abre la página **Invites** (menú → **Invites**).
3. Pega el código y confirma.

Lo que pasa después, solo: tu Oasis se conecta al PUB de el nodo (un
Oasis encendido 24/7 que retransmite para todos — ver §10), empieza a
**seguirte**, y te entrega una instantánea (*snapshot*) del contenido
reciente del campamento — estarás leyendo el feed de hoy **en segundos**,
mientras el historial más antiguo se rellena en segundo plano.

Si la invitación falla («ya usada»): los códigos tienen usos limitados. Pide
otro — no cuestan nada; alguien de la mesa técnica teclea un comando.

---

## 5. Conecta con toda la gente de la base

Tres caminos, todos automáticos una vez montados:

1. **El mismo Wi-Fi (la red del campamento).** Conéctate al Wi-Fi de la
   acampada (nombre y contraseña al principio de esta guía). Cada Oasis de
   esa red descubre a los demás **automáticamente por la red local** — sin
   internet, sin configurar nada, sin escribir nada. Es el sistema nervioso
   de la plaza: aunque caiga internet entero, el nodo sigue hablando.
2. **A través del PUB.** El PUB del campamento (la máquina detrás de
   `<dominio>`) está siempre encendido. Tu móvil se sincroniza con él
   en cuanto tienes cualquier internet, y hace de relevo entre gente que
   nunca coincide conectada a la vez.
3. **De persona a persona, donde sea.** Dos Oasis que se cruzan (el Wi-Fi de
   un grupo de trabajo, un punto de acceso compartido en un bus…)
   intercambian todo lo que a ambos les falte. Tu móvil guarda lo que
   publicas **tú**, lo que publica la gente que sigues, y sus contactos —
   dos saltos a tu alrededor. Sigue generosamente y las noticias viajan.

**Para encontrar gente:** abre **Graphos** para ver el nodo como un mapa
de pares, o **Trending** para ver qué lee la plaza ahora mismo. Sigue a
alguien y su feed empieza a replicarse hacia ti.

**¿En una acción sin datos en absoluto?** Todo lo que ya está en tu móvil
sigue funcionando — leer **y escribir**. Tus publicaciones esperan en tu
dispositivo y se extienden la próxima vez que te cruces con otro Oasis. (A
la versión de portátil se le puede decir que no toque internet en absoluto
con `--offline`; la app simplemente usa la conexión que exista.)

---

## 6. Tribus — cómo se organiza el nodo (comisiones, grupos de trabajo)

Las comisiones, los grupos de trabajo, la cocina, el equipo legal… en Oasis
son **Tribus**: grupos con su propio espacio — feed, foro, encuestas,
tareas, calendario, tesorería y votaciones internas — **cifrados con una
clave que solo tienen los miembros** (es lo habitual; una tribu también
puede ser pública).

**Sí: cualquiera puede crear una tribu.** Nadie lo aprueba ni lo autoriza;
para eso es. Menú → **Tribus** → **Crear Tribu**, y rellena:

- **Título** y **Descripción** (obligatorios). Ubicación, etiquetas e imagen
  son opcionales.
- **Estado**: *Privada* (por defecto — la tribu y todo lo que hay dentro va
  cifrado) o *Pública*.
- **Modo**: *Estricto* — solo tú generas códigos de invitación; o *Abierta*
  — cualquier miembro puede invitar, y la tribu puede mantener además una
  invitación abierta permanente (botón Unirse + QR para todo el mundo).

Al crearla eres el primer miembro y el **autor** de la tribu: solo el autor
puede borrarla o cambiar su estructura. **Grupos de trabajo dentro de una
comisión:** abre la tribu de la comisión y crea una **sub-tribu** desde
dentro — las sub-tribus heredan su privacidad.

**Cómo unirse a una tribu** (una comisión, un grupo de trabajo…), tres
caminos:

1. **Con un código.** Pídeselo a su autor (modo estricto) o a cualquier
   miembro (modo abierto); abre menú → **Invites** → sección **Tribus**,
   pega el código y únete. Un código de un solo uso se consume al usarlo.
2. **Con el botón UNIRSE A LA TRIBU.** Las tribus con invitación abierta
   muestran el código y el botón **UNIRSE A LA TRIBU** en su propia tarjeta.
   Un toque.
3. **Con un QR.** Toda invitación abierta tiene su código QR: la mesa
   técnica puede imprimir un QR por comisión — lo escaneas con la cámara,
   confirmas, y estás dentro.

Tras unirse, todo ocurre solo: tu Oasis importa la clave de la tribu, te
añade a la lista de miembros y sigue a los demás para que empecéis a
sincronizar.

**Salir o ser expulsado:** cualquier miembro puede irse (botón Leave; el
autor no puede abandonar su propia tribu mientras exista). Cada salida rota
la clave de la tribu, así que quien queda fuera ya no puede leer lo
*nuevo*. Lo que alguien ya leyó, leído está.

**Para el nodo:** una tribu por comisión, una sub-tribu por grupo de
trabajo. *Estricto* para grupos cerrados (legal, prensa); *Abierta* más un
QR impreso para los abiertos (punto de información, cocina, turnos).

---

## 7. Uso diario — los módulos que importan en la plaza

Todo está en el menú. Los que usarás a diario:

| Módulo | Para qué sirve |
|---|---|
| **Feed** | Mensajes cortos, tipo línea de tiempo. El pulso de el nodo. |
| **Chats** | Conversaciones directas, cifradas de extremo a extremo. |
| **Forums** | Debate por temas e hilos — comisiones, grupos de trabajo. |
| **Tribes (Tribus)** | Las comisiones y grupos privados de el nodo. Cualquiera puede crear una — ver §6. |
| **Wikis** | Páginas de conocimiento compartido, con versiones. El cuaderno de el nodo (este manual también vive allí). |
| **Emergencies** | Levantar, confirmar y seguir emergencias. Aprende este **antes** de necesitarlo. |
| **Calendars / Events** | Asambleas, comisiones, turnos. |
| **Maps** | Mapas **offline** y colaborativos de el nodo y la ciudad. |
| **Polls / Opinions / Governance** | Preguntar a la red, contar respuestas, votar. |
| **Market** | Dar, pedir, intercambiar bienes y servicios (ECOin, la moneda de el nodo). |
| **Cipher** | Cifrar cualquier texto con una contraseña compartida — para mensajes que tengan que viajar fuera de Oasis. |
| **Backup** | Protege tu identidad. Ver §9 — hazlo hoy, no algún día. |

::: tip Nota del portal · Phone y Rooms (Oasis 1.2.2)
Desde Oasis 1.2.2 la red tiene además **Phone** (llamadas de voz) y **Rooms** (salas de voz),
cifradas de extremo a extremo; cuando dos habitantes no se alcanzan directamente, la llamada pasa
por un PUB, que la retransmite sin poder escucharla. Usan el micrófono y los altavoces del
dispositivo donde corre Oasis. La guía es la de upstream:
[Phone & Rooms](https://code.03c8.net/KrakensLab/oasis/src/master/docs/phone/README.md). En este portal no se ha medido si funcionan en la
app de Android.
:::

---

## 8. Mantente a salvo

Oasis es fuerte, pero ten claro qué hace y qué no hace:

- **Los mensajes públicos van firmados, no cifrados.** Cualquiera que te
  replique puede leerlos, guardarlos, capturarlos. Público es público — di
  en público solo lo que pondrías en una pancarta.
- **Los mensajes privados van sellados** para sus destinatarios — ni
  siquiera el PUB que los transporta puede abrirlos. Las **Tribes** (grupos
  privados) añaden su propia clave, compartida solo entre miembros.
- **Tu dirección IP la ven los pares con los que conectas directamente.**
  En el Wi-Fi de el nodo, es el nodo; en internet, quien conecte
  contigo.
- **No confíes en tu smartphone.** Si te quitan o desbloquean el móvil, se
  van con él tu identidad, tus mensajes privados y tus claves. Usa un
  bloqueo de pantalla fuerte; lleva el móvil encima; valora un aparato
  dedicado para lo sensible.
- **Borrado de emergencia.** La app tiene una opción **Panic** que borra
  todo lo que Oasis guarda en el dispositivo — identidad, mensajes, ajustes.
  Aprende dónde está antes del día que la necesites. No se puede deshacer:
  mantén al día tus copias del §9.
- Las fotos se limpian de GPS automáticamente — pero una cara o una
  pancarta reconocible sigue siendo reconocible.
- Oasis es **software experimental**. En palabras del propio proyecto:
  *por favor, no le confíes tu vida.* Para lo que pueda poner a alguien en
  peligro, piensa dos veces dónde va a vivir, para siempre.

---

## 9. Copia de seguridad de tu identidad (hoy)

Tu identidad es una clave secreta que la app guarda en su almacenamiento
privado de tu móvil. **Si la pierdes, nadie en la Tierra puede recuperarla**
— ni la mesa técnica, ni el PUB, nadie. Tu nombre desaparecería y tendrías
que entrar de nuevo como alguien nuevo.

Abre **Tools → Backup** y haz estas dos cosas **ya**:

1. **RECOVERY** — muestra tu clave secreta como texto y como código QR.
   Imprímela o guarda el PDF en un sitio offline y seguro. Quien la lea
   puede ser tú: trátala como si fuera efectivo.
2. **EXPORT KEYS** — descarga la clave cifrada con una contraseña de al
   menos 32 caracteres (la página propone una aleatoria). Guarda el archivo
   y la contraseña en sitios *distintos* (p. ej. el archivo en un USB, la
   contraseña apuntada en tu libreta).

Y cada semana, o antes de un día grande: **FULL BACKUP → alcance ONLY MY
CONTENT** — un archivo cifrado pequeño con tus propias publicaciones, del
tamaño justo para un móvil. Sácalo del teléfono (cable, SD; la mesa técnica
ayuda).

**Cambiar a un móvil nuevo — el orden importa:** instala Oasis y ábrela una
vez → restaura **primero el archivo de la copia** → **después** importa la
clave → reinicia. La copia entra *antes* que la clave, nunca después, o tu
feed se bifurca y el historial ya no se puede fusionar. Tras cualquier
restauración, comprueba **Settings → Verification**: sin huecos, sin
bifurcaciones, sin enlaces rotos.

---

## 10. Para la mesa técnica (referencia rápida para quien organiza)

- **El PUB de el nodo** es un Oasis siempre encendido
  (`./oasis.sh server`) con una ventana web de solo lectura en
  `https://<dominio>/c`. Guía completa de despliegue:
  [`docs/PUB/deploy.md`](https://code.03c8.net/KrakensLab/oasis/src/master/docs/PUB/deploy.md).
- **Reparte la app:** conserva el APK más reciente (`oasis-v….apk`) en el
  servidor del campamento, un pendrive y el móvil de alguien; compártelo por
  Nearby, QR, cable o el Wi-Fi de el nodo. Las versiones nuevas salen en
  `https://code.03c8.net/KrakensLab/oasis/releases` con su *checksum* —
  instalar encima de la anterior conserva la identidad y el contenido de
  todos. Google Play también la tiene (`com.solarnethub.oasis`) para quien
  la prefiera.
- **Crea invitaciones para la asamblea:**

  ```
  ./oasis.sh invite        # un solo uso
  ./oasis.sh invite 500    # código abierto para toda una asamblea
  ```

- **Vigila la red:** `./oasis.sh status` (pares/replicación),
  `./oasis.sh gossip` (pares conocidos).
- **Reparte Wi-Fi + este manual** juntos: la invitación mete a la gente
  *dentro*; el Wi-Fi de el nodo los mantiene *sincronizados* cuando
  falla internet.
- Gente nueva con portátil (Linux/Mac/Windows): instalar
  [Node.js 22+](https://nodejs.org), luego `git clone
  https://code.03c8.net/KrakensLab/oasis`, `./install.sh`, `./oasis.sh` —
  y se abre en su navegador.

::: tip Nota del portal · si el PUB corre con este SDK
Los comandos de esta sección (`./oasis.sh …`) son los de una instalación directa de Oasis. Un
pub desplegado con este SDK corre en contenedores y la mesa técnica usa otros: están en la puerta
[Habitante](/roles/habitante#si-tu-pub-corre-con-este-sdk).
:::

---

## 11. Para quien usa iPhone

iOS no puede ejecutar Oasis (Apple no lo permite). Aun así puedes:

- **Leer todo lo público** de el nodo en
  **`https://<dominio>/c`** con Safari — solo lectura, sin instalar
  nada, sin rastreo.
- **Publicar a través de otra persona:** escríbelo, pásaselo a alguien de
  confianza que tenga Oasis, y lo publica.
- La respuesta a largo plazo es un Android de repuesto; la mesa técnica
  deja uno listo en media hora.

---

## 12. Problemas y soluciones

| Problema | Solución |
|---|---|
| Android bloquea el APK («apps desconocidas») | Ajustes → Aplicaciones → Acceso especial → Instalar apps desconocidas → permite tu app de Archivos, y vuelve a tocar el APK. |
| Play Protect avisa y quiere cancelar | Más detalles → Instalar de todas formas. Se opone a todo lo que no viene de su tienda; el *checksum* de la página de *releases* demuestra que el archivo es oficial. |
| La app parece congelada por la noche / deja de sincronizar | Android la durmió: Ajustes → Aplicaciones → Oasis → Batería → Sin restricciones, y sácala de cualquier lista de «apps en reposo». |
| Oasis parece vacío tras entrar | La primera sincronización tarda unos minutos; la instantánea trae primero el feed reciente. Dale un momento, mantén la app abierta. |
| El feed no se actualiza en la calle | Normal sin internet — no se pierde nada. Se sincroniza todo al volver al Wi-Fi de el nodo o a cualquier internet. |
| Código de invitación rechazado | Se agotó. Pide otro en la mesa técnica (`./oasis.sh invite`). |
| Actualizar la app | Instala el APK nuevo encima del viejo (o actualiza desde Play). Tu identidad y tu contenido se quedan; no hay que rehacer nada. |
| Móvil perdido o roto | Tu clave estaba ahí. Restaura desde tu impresión RECOVERY o tu `oasis.enc` (§9) en un móvil nuevo. Si nunca hiciste copia: identidad nueva en la mesa técnica — y esta vez haz el §9 el primer día. |
| Portátil: Oasis no arranca | Necesita Node.js 22+ — ver §10. Si ya funcionaba en esa máquina, copia `~/.ssb` a un lado antes de tocar nada. |
| Oasis viejo sobre una copia vieja | Nunca arranques un Oasis más antiguo sobre datos migrados por uno nuevo — se niega a propósito. Pregunta en la mesa técnica. |

---

## 13. Palabras que oirás en la plaza

| Palabra | Significado |
|---|---|
| **Habitante** | Una persona en Oasis. Tú, en cuanto la abres. |
| **Feed** | Tu historial personal de mensajes, que solo puede crecer. |
| **PUB** | Un Oasis siempre encendido que hace de relevo entre todos. El nuestro está detrás de `<dominio>`. |
| **Código de invitación** | El código que te mete (a ti, y solo a gente de confianza) en la red. |
| **APK** | El archivo de la app Android. Un archivo como otro cualquiera: cópialo, compártelo, instálalo — sin tienda. |
| **Panic** | La opción dentro de la app que borra al instante todo lo que Oasis guarda en tu dispositivo. |
| **Tribu (Tribe)** | Un grupo privado con su propia clave compartida. Cualquiera puede crear una — ver §6. |
| **Saltos (hops)** | Hasta dónde replica tu dispositivo a tu alrededor: tú, a quien sigues, a quien siguen ellos (dos saltos por defecto). |
| **Cotilleo (gossip)** | Cómo se extienden los mensajes de móvil en móvil, como las noticias en una plaza. |
| **Clearnet** | La web normal. Nuestra ventana de solo lectura: `<dominio>/c`. |
| **ECOin** | La moneda de la red, para el Market. Los PUB que se apuntan pagan una renta básica semanal a los habitantes activos. |

---

*Fuentes: todo lo de este manual viene de los materiales del propio
proyecto — [README](https://code.03c8.net/KrakensLab/oasis/src/master/README.md), [install](https://code.03c8.net/KrakensLab/oasis/src/master/docs/install/install.md),
[backups](https://code.03c8.net/KrakensLab/oasis/src/master/docs/backups/README.md), [PUB deploy](https://code.03c8.net/KrakensLab/oasis/src/master/docs/PUB/deploy.md),
[security](https://code.03c8.net/KrakensLab/oasis/src/master/docs/security.md), las [releases](https://code.03c8.net/KrakensLab/oasis/releases)
oficiales de la app Android y su ficha en Google Play, y la wiki «Cómo
funciona Oasis» publicada en el HUB de el nodo. Las correcciones van a
la mesa técnica o a la propia wiki.*
