# Oasis para el nodo · manual de bienvenida · 1 de 2

*Parte {k} de {n}.* *Guía práctica para el nodo: instala Oasis en tu móvil, únete a la red del campamento y mantente en contacto con toda la plaza — incluso sin internet.
Traducción directa del original en inglés (`onboarding-sol-en.md`); las
correcciones se hacen primero allí.*

> **RELLENAR ANTES DE IMPRIMIR**
> Nombre del Wi-Fi de el nodo: `________________`
> Contraseña del Wi-Fi: `________________`
> Ubicación de la mesa técnica / hacklab: `________________`
> Dónde conseguir la app hoy (persona / QR): `________________`

---

## Qué es Oasis (y por qué lo usamos en la plaza)

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

La ventana pública de nuestra red es **https://<dominio>/c** —
cualquiera con un navegador puede leer allí lo que publica el campamento
(solo lectura, sin cuenta, sin app).

---

## Qué necesitas

- **Móvil** · Android. (El iPhone no puede ejecutar Oasis en sí — ver §11.)
- **Espacio** · Unos cientos de MB libres para la app, más sitio para tu contenido — con 1 GB vas con margen.
- **Internet** · Solo para descargar la app; mejor por Wi-Fi. Después, Oasis funciona sin conexión.
- **Tiempo** · 10–15 minutos la primera vez.

**No** necesitas: correo electrónico, número de teléfono, datos personales de
ningún tipo, ni permisos de root en el móvil.

---

## Instala la app de Oasis en tu Android

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

## Únete a la red de la base

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

## Conecta con toda la gente de la base

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

## Tribus — cómo se organiza el nodo (comisiones, grupos de trabajo)

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

Siguiente: [[Oasis para el nodo · manual de bienvenida · 2 de 2]]
