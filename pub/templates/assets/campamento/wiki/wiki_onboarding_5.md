*Parte 5 de 5.*

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

Páginas: [[Oasis para el nodo · manual de bienvenida · 1 de 5]] · [[Oasis para el nodo · manual de bienvenida · 2 de 5]] · [[Oasis para el nodo · manual de bienvenida · 3 de 5]] · [[Oasis para el nodo · manual de bienvenida · 4 de 5]] · [[Oasis para el nodo · manual de bienvenida · 5 de 5]]
