*Parte 1 de 5.*

*Guía práctica para el nodo: instala Oasis en tu móvil, únete a la red del campamento y mantente en contacto con toda la plaza — incluso sin internet.
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

Páginas: [[Oasis para el nodo · manual de bienvenida · 1 de 5]] · [[Oasis para el nodo · manual de bienvenida · 2 de 5]] · [[Oasis para el nodo · manual de bienvenida · 3 de 5]] · [[Oasis para el nodo · manual de bienvenida · 4 de 5]] · [[Oasis para el nodo · manual de bienvenida · 5 de 5]]
