*Parte 4 de 5.*

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

Páginas: [[Oasis para el nodo · manual de bienvenida · 1 de 5]] · [[Oasis para el nodo · manual de bienvenida · 2 de 5]] · [[Oasis para el nodo · manual de bienvenida · 3 de 5]] · [[Oasis para el nodo · manual de bienvenida · 4 de 5]] · [[Oasis para el nodo · manual de bienvenida · 5 de 5]]
