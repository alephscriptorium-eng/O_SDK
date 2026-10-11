# Oasis para el nodo · manual de bienvenida · 2 de 2

*Parte {k} de {n}.* ## Uso diario — los módulos que importan en la plaza

Todo está en el menú. Los que usarás a diario:

*Módulo · Para qué sirve*
- **Feed** · Mensajes cortos, tipo línea de tiempo. El pulso de el nodo.
- **Chats** · Conversaciones directas, cifradas de extremo a extremo.
- **Forums** · Debate por temas e hilos — comisiones, grupos de trabajo.
- **Tribes (Tribus)** · Las comisiones y grupos privados de el nodo. Cualquiera puede crear una — ver §6.
- **Wikis** · Páginas de conocimiento compartido, con versiones. El cuaderno de el nodo (este manual también vive allí).
- **Emergencies** · Levantar, confirmar y seguir emergencias. Aprende este **antes** de necesitarlo.
- **Calendars / Events** · Asambleas, comisiones, turnos.
- **Maps** · Mapas **offline** y colaborativos de el nodo y la ciudad.
- **Polls / Opinions / Governance** · Preguntar a la red, contar respuestas, votar.
- **Market** · Dar, pedir, intercambiar bienes y servicios (ECOin, la moneda de el nodo).
- **Cipher** · Cifrar cualquier texto con una contraseña compartida — para mensajes que tengan que viajar fuera de Oasis.
- **Backup** · Protege tu identidad. Ver §9 — hazlo hoy, no algún día.

---

## Mantente a salvo

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

## Copia de seguridad de tu identidad (hoy)

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

## Para la mesa técnica (referencia rápida para quien organiza)

- **El PUB de el nodo** es un Oasis siempre encendido
  (`./oasis.sh server`) con una ventana web de solo lectura en
  `https://<dominio>/c`. Guía completa de despliegue:
  [`docs/PUB/deploy.md`](../PUB/deploy.md).
- **Reparte la app:** conserva el APK actual (hoy `oasis-v1.2.1.apk`) en el
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

---

## Para quien usa iPhone

iOS no puede ejecutar Oasis (Apple no lo permite). Aun así puedes:

- **Leer todo lo público** de el nodo en
  **https://<dominio>/c** con Safari — solo lectura, sin instalar
  nada, sin rastreo.
- **Publicar a través de otra persona:** escríbelo, pásaselo a alguien de
  confianza que tenga Oasis, y lo publica.
- La respuesta a largo plazo es un Android de repuesto; la mesa técnica
  deja uno listo en media hora.

---

## Problemas y soluciones

*Problema · Solución*
- **Android bloquea el APK («apps desconocidas»)** · Ajustes → Aplicaciones → Acceso especial → Instalar apps desconocidas → permite tu app de Archivos, y vuelve a tocar el APK.
- **Play Protect avisa y quiere cancelar** · Más detalles → Instalar de todas formas. Se opone a todo lo que no viene de su tienda; el *checksum* de la página de *releases* demuestra que el archivo es oficial.
- **La app parece congelada por la noche / deja de sincronizar** · Android la durmió: Ajustes → Aplicaciones → Oasis → Batería → Sin restricciones, y sácala de cualquier lista de «apps en reposo».
- **Oasis parece vacío tras entrar** · La primera sincronización tarda unos minutos; la instantánea trae primero el feed reciente. Dale un momento, mantén la app abierta.
- **El feed no se actualiza en la calle** · Normal sin internet — no se pierde nada. Se sincroniza todo al volver al Wi-Fi de el nodo o a cualquier internet.
- **Código de invitación rechazado** · Se agotó. Pide otro en la mesa técnica (`./oasis.sh invite`).
- **Actualizar la app** · Instala el APK nuevo encima del viejo (o actualiza desde Play). Tu identidad y tu contenido se quedan; no hay que rehacer nada.
- **Móvil perdido o roto** · Tu clave estaba ahí. Restaura desde tu impresión RECOVERY o tu `oasis.enc` (§9) en un móvil nuevo. Si nunca hiciste copia: identidad nueva en la mesa técnica — y esta vez haz el §9 el primer día.
- **Portátil: Oasis no arranca** · Necesita Node.js 22+ — ver §10. Si ya funcionaba en esa máquina, copia `~/.ssb` a un lado antes de tocar nada.
- **Oasis viejo sobre una copia vieja** · Nunca arranques un Oasis más antiguo sobre datos migrados por uno nuevo — se niega a propósito. Pregunta en la mesa técnica.

---

## Palabras que oirás en la plaza

*Palabra · Significado*
- **Habitante** · Una persona en Oasis. Tú, en cuanto la abres.
- **Feed** · Tu historial personal de mensajes, que solo puede crecer.
- **PUB** · Un Oasis siempre encendido que hace de relevo entre todos. El nuestro está detrás de `<dominio>`.
- **Código de invitación** · El código que te mete (a ti, y solo a gente de confianza) en la red.
- **APK** · El archivo de la app Android. Un archivo como otro cualquiera: cópialo, compártelo, instálalo — sin tienda.
- **Panic** · La opción dentro de la app que borra al instante todo lo que Oasis guarda en tu dispositivo.
- **Tribu (Tribe)** · Un grupo privado con su propia clave compartida. Cualquiera puede crear una — ver §6.
- **Saltos (hops)** · Hasta dónde replica tu dispositivo a tu alrededor: tú, a quien sigues, a quien siguen ellos (dos saltos por defecto).
- **Cotilleo (gossip)** · Cómo se extienden los mensajes de móvil en móvil, como las noticias en una plaza.
- **Clearnet** · La web normal. Nuestra ventana de solo lectura: `<dominio>/c`.
- **ECOin** · La moneda de la red, para el Market. Los PUB que se apuntan pagan una renta básica semanal a los habitantes activos.

---

*Fuentes: todo lo de este manual viene de los materiales del propio
proyecto — [README](../../README.md), [install](../install/install.md),
[backups](../backups/README.md), [PUB deploy](../PUB/deploy.md),
[security](../security.md), las [releases](https://code.03c8.net/KrakensLab/oasis/releases)
oficiales de la app Android y su ficha en Google Play, y la wiki «Cómo
funciona Oasis» publicada en el HUB de el nodo. Las correcciones van a
la mesa técnica o a la propia wiki; este archivo es la traducción directa
del original en inglés (`onboarding-sol-en.md`) — corrige primero allí.*

Anterior: [[Oasis para el nodo · manual de bienvenida · 1 de 2]]
