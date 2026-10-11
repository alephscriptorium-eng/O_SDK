*Parte 4 de 5.*

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

Páginas: [[Oasis para el nodo · manual de bienvenida · 1 de 5]] · [[Oasis para el nodo · manual de bienvenida · 2 de 5]] · [[Oasis para el nodo · manual de bienvenida · 3 de 5]] · [[Oasis para el nodo · manual de bienvenida · 4 de 5]] · [[Oasis para el nodo · manual de bienvenida · 5 de 5]]
