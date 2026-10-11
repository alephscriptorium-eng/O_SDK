*Parte 1 de 5.*

Libro del **operador** (la mesa técnica): a qué órgano le toca cada tribu, sala, calendario, lista o mapa, qué tipo de acceso lleva y dónde se obtiene. Generada por `pub/tools/template-seed.js --reparto` desde `campamento.json`; no se edita a mano.

> **Aquí no hay ningún código.** Los códigos los tiene la mesa técnica: los abiertos en la **hoja de códigos** que saca de la secretaría (con un QR por tribu, para imprimir); los de un uso, uno a uno, también de la secretaría. Esta guía dice *quién* y *dónde*, nunca *cuál*.

## Cómo se entrega

- Mesa técnica: <pendiente: quién es la mesa técnica (la secretaría del pub ejecuta; la mesa entrega)>
- Modo de entrega: Cada órgano nombra a quién de los suyos le llega el acceso. Tribus abiertas: QR impreso o botón en la tarjeta. Tribus estrictas y listas cerradas: el autor invita en mano. Nunca por un canal que quede escrito.
- Quién ejecuta la plantilla: la secretaría del pub (bot de soporte), que crea los objetos y custodia las claves de las tribus privadas. Quién dentro de cada órgano recibe el acceso: <DECISIÓN del colectivo: qué identidad crea cada tribu; solo el autor la borra o reestructura>
- Dónde vive la secretaría y quién la opera: <DECISIÓN del colectivo: A, en el host junto al pub (mismo compose, perfil retro) | B, en otra máquina de la mesa técnica (secretaria.sh, unida al pub por invite)> · operador: la mesa técnica de Campamento clona el repo y ejecuta pub/scripts/secretaria.sh (docs/PUB/TEMPLATE-RUNBOOK.md) · custodia de su secret y de las claves de tribu: <DECISIÓN del colectivo: quién guarda el secret de la secretaría y las claves de tribu (oasis/keys), fuera de git>
- Lo público se lee sin cuenta en la web abierta del pub (`/c`): los enlaces aparecen al regenerar esta guía con `--ledger` tras la activación.

## Primer acceso

La secretaría crea todas las tribus y es su autora; no tiene pantalla. Por eso en la tarjeta de una tribu nadie ve todavía un código ni un botón de unirse: el primer acceso de cada órgano lo reparte la mesa técnica.

- **Tribus abiertas con código multiuso.** La mesa técnica saca de la secretaría la hoja de códigos: una tarjeta por tribu con el código y su QR. Se imprime, se reparte donde deba llegar y se destruye la copia. Quien lo recibe: Menú → Tribus → INTRODUCIR INVITACIÓN → pega el código (o escanea el QR y copia el texto). El código es público para quien lo tenga: un QR en la calle abre la tribu a todo el que pase.
- **Tribus estrictas.** La secretaría da un código de un uso por persona, a petición del órgano, y la mesa técnica lo entrega en mano. Cada alta pasa por ahí: sin secretaría no entra nadie más. Si el órgano prefiere repartir él mismo, la tribu debe ser abierta: DECISIÓN del colectivo antes de sembrar.
- **Después del primero.** En una tribu abierta, cualquier miembro genera códigos desde la tarjeta de la tribu (Generar invitación): la mesa técnica deja de ser necesaria. Las salas, calendarios y mapas de una tribu se ven al entrar en ella.
- **Dónde se pega un código.** Menú → Tribus → INTRODUCIR INVITACIÓN (también en Menú → Invitaciones → Tribus). Un código de un uso se consume al usarse; el multiuso vale hasta que la secretaría lo retire.

## Asamblea General

Responsable del reparto: `asamblea_general`. Un ítem por objeto: tipo de acceso · quién reparte · dónde se obtiene · si se ve en la web (`/c`).

- **Asamblea General** (tribes) · tribu abierta con código multiuso · reparte: la mesa técnica, con la hoja de códigos de la secretaría; después, cualquier miembro · dónde: Menú → Tribus → INTRODUCIR INVITACIÓN → pegar el código de la hoja de códigos (o escanear su QR impreso). Quien ya está dentro puede dar más desde la tarjeta de la tribu → Generar invitación. · web: cuando tenga contenido expuesto
- **Sala · Asamblea General** (rooms) · sala abierta · reparte: nadie reparte: es de su tribu · dónde: La ven y entran los miembros de su tribu (Menú → Salas); sin tribu, cualquiera que la vea. · web: no
- **Asamblea General** (calendars) · calendario suelto OPEN · reparte: nadie reparte: es abierto · dónde: Invitación pública en la tarjeta del calendario (Menú → Calendarios). · web: sí (tras la activación)
- **Acuerdos de la Asamblea General** (mailing) · lista abierta · reparte: nadie · dónde: Quien escribe queda suscrito; nada que repartir. · web: no
- **La plaza** (maps) · mapa SINGLE · reparte: el autor · dónde: El autor invita desde la tarjeta. · web: no
- **Asamblea General · en la plaza** (events) · evento público · reparte: nadie · dónde: Menú → Eventos. Los públicos los ve cualquiera. · web: sí (tras la activación)

Páginas: [[Guía de reparto de accesos · 1 de 5]] · [[Guía de reparto de accesos · 2 de 5]] · [[Guía de reparto de accesos · 3 de 5]] · [[Guía de reparto de accesos · 4 de 5]] · [[Guía de reparto de accesos · 5 de 5]]
