# Guía de reparto de accesos · Campamento

Libro del **operador** (la mesa técnica): a qué órgano le toca cada tribu, sala, calendario, lista o mapa, qué tipo de acceso lleva y dónde se obtiene. Generada por `pub/tools/template-seed.js --reparto` desde `campamento.json`; no se edita a mano.

> **Aquí no hay ningún código.** Los códigos los tiene la mesa técnica: los abiertos en la **hoja de códigos** que saca de la secretaría (con un QR por tribu, para imprimir); los de un uso, uno a uno, también de la secretaría. Esta guía dice *quién* y *dónde*, nunca *cuál*.

## 0. Cómo se entrega

- Mesa técnica: <pendiente: quién es la mesa técnica (la secretaría del pub ejecuta; la mesa entrega)>
- Modo de entrega: Cada órgano nombra a quién de los suyos le llega el acceso. Tribus abiertas: QR impreso o botón en la tarjeta. Tribus estrictas y listas cerradas: el autor invita en mano. Nunca por un canal que quede escrito.
- Quién ejecuta la plantilla: la secretaría del pub (bot de soporte), que crea los objetos y custodia las claves de las tribus privadas. Quién dentro de cada órgano recibe el acceso: <DECISIÓN del colectivo: qué identidad crea cada tribu; solo el autor la borra o reestructura>
- Dónde vive la secretaría y quién la opera: <DECISIÓN del colectivo: A, en el host junto al pub (mismo compose, perfil retro) | B, en otra máquina de la mesa técnica (secretaria.sh, unida al pub por invite)> · operador: la mesa técnica de Campamento clona el repo y ejecuta pub/scripts/secretaria.sh (docs/PUB/TEMPLATE-RUNBOOK.md) · custodia de su secret y de las claves de tribu: <DECISIÓN del colectivo: quién guarda el secret de la secretaría y las claves de tribu (oasis/keys), fuera de git>
- Lo público se lee sin cuenta en la web abierta del pub (`/c`): los enlaces aparecen al regenerar esta guía con `--ledger` tras la activación.

## 0 bis. Primer acceso: cómo entra la primera persona de cada órgano

La secretaría crea todas las tribus y es su autora; no tiene pantalla. Por eso en la tarjeta de una tribu nadie ve todavía un código ni un botón de unirse: el primer acceso de cada órgano lo reparte la mesa técnica.

- **Tribus abiertas con código multiuso.** La mesa técnica saca de la secretaría la hoja de códigos (`secretaria.sh <id> codigos sheet --out <carpeta>`; con `--brand marca.json` lleva la marca): una tarjeta por tribu con el código y su QR. Se imprime, se reparte donde deba llegar y se destruye la copia. Quien lo recibe: Menú → Tribus → INTRODUCIR INVITACIÓN → pega el código (o escanea el QR y copia el texto). El código es público para quien lo tenga: un QR en la calle abre la tribu a todo el que pase.
- **Tribus estrictas.** La secretaría da un código de un uso por persona, a petición del órgano (`secretaria.sh <id> codigos one-use <id de la tribu> --yes`: lo muestra una vez y no lo guarda), y la mesa técnica lo entrega en mano. Cada alta pasa por ahí: sin secretaría no entra nadie más. Si el órgano prefiere repartir él mismo, la tribu debe ser abierta: DECISIÓN del colectivo antes de sembrar.
- **Después del primero.** En una tribu abierta, cualquier miembro genera códigos desde la tarjeta de la tribu (Generar invitación): la mesa técnica deja de ser necesaria. Las salas, calendarios y mapas de una tribu se ven al entrar en ella.
- **Dónde se pega un código.** Menú → Tribus → INTRODUCIR INVITACIÓN (también en Menú → Invitaciones → Tribus). Un código de un uso se consume al usarse; el multiuso vale hasta que la secretaría lo retire.

## 1. Asamblea General  `responsable: asamblea_general`

| Objeto | Tipo de acceso | Quién reparte | Dónde se obtiene | Público en /c |
|---|---|---|---|---|
| **Asamblea General** (tribes) | tribu abierta con código multiuso | la mesa técnica, con la hoja de códigos de la secretaría; después, cualquier miembro | Menú → Tribus → INTRODUCIR INVITACIÓN → pegar el código de la hoja de códigos (o escanear su QR impreso). Quien ya está dentro puede dar más desde la tarjeta de la tribu → Generar invitación. | cuando tenga contenido expuesto |
| **Sala · Asamblea General** (rooms) | sala abierta | nadie reparte: es de su tribu | La ven y entran los miembros de su tribu (Menú → Salas); sin tribu, cualquiera que la vea. | no |
| **Asamblea General** (calendars) | calendario suelto OPEN | nadie reparte: es abierto | Invitación pública en la tarjeta del calendario (Menú → Calendarios). | sí (tras la activación) |
| **Acuerdos de la Asamblea General** (mailing) | lista abierta | nadie | Quien escribe queda suscrito; nada que repartir. | no |
| **La plaza** (maps) | mapa SINGLE | el autor | El autor invita desde la tarjeta. | no |
| **Asamblea General · en la plaza** (events) | evento público | nadie | Menú → Eventos. Los públicos los ve cualquiera. | sí (tras la activación) |

## 2. Asamblea Internodos  `responsable: asamblea_internodos`

| Objeto | Tipo de acceso | Quién reparte | Dónde se obtiene | Público en /c |
|---|---|---|---|---|
| **Asamblea Internodos** (tribes) | tribu privada estricta | la secretaría, a petición del órgano | Solo la secretaría (autora) genera un código de un uso por persona, a petición del órgano, entregado en mano; se redime en Menú → Tribus → INTRODUCIR INVITACIÓN. Sin ella nadie más entra: cada alta pasa por la mesa técnica. | no (privada) |
| **Sala · Internodos** (rooms) | sala solo por invitación | el autor de la sala | Quien la preside: Menú → Salas → la sala → Generar invitación. Si la preside la secretaría, hoy no hay herramienta para ello: DECISIÓN (abrirla a su tribu). | no |
| **Asamblea Internodos** (calendars) | calendario de tribu | el de la tribu | Lo ven los miembros de la tribu; el acceso es el de la tribu. | no |

## 3. Nodo Norte  `responsable: nodo_norte`

| Objeto | Tipo de acceso | Quién reparte | Dónde se obtiene | Público en /c |
|---|---|---|---|---|
| **Nodo Norte** (tribes) | tribu abierta con código multiuso | la mesa técnica, con la hoja de códigos de la secretaría; después, cualquier miembro | Menú → Tribus → INTRODUCIR INVITACIÓN → pegar el código de la hoja de códigos (o escanear su QR impreso). Quien ya está dentro puede dar más desde la tarjeta de la tribu → Generar invitación. | cuando tenga contenido expuesto |
| **Sala · Nodo Norte** (rooms) | sala abierta | nadie reparte: es de su tribu | La ven y entran los miembros de su tribu (Menú → Salas); sin tribu, cualquiera que la vea. | no |
| **Nodo Norte** (calendars) | calendario de tribu | el de la tribu | Lo ven los miembros de la tribu; el acceso es el de la tribu. | no |

## 4. Nodo Oeste  `responsable: nodo_oeste`

| Objeto | Tipo de acceso | Quién reparte | Dónde se obtiene | Público en /c |
|---|---|---|---|---|
| **Nodo Oeste** (tribes) | tribu abierta con código multiuso | la mesa técnica, con la hoja de códigos de la secretaría; después, cualquier miembro | Menú → Tribus → INTRODUCIR INVITACIÓN → pegar el código de la hoja de códigos (o escanear su QR impreso). Quien ya está dentro puede dar más desde la tarjeta de la tribu → Generar invitación. | cuando tenga contenido expuesto |
| **Sala · Nodo Oeste** (rooms) | sala abierta | nadie reparte: es de su tribu | La ven y entran los miembros de su tribu (Menú → Salas); sin tribu, cualquiera que la vea. | no |
| **Nodo Oeste** (calendars) | calendario de tribu | el de la tribu | Lo ven los miembros de la tribu; el acceso es el de la tribu. | no |

## 5. Nodo Centro  `responsable: nodo_centro`

| Objeto | Tipo de acceso | Quién reparte | Dónde se obtiene | Público en /c |
|---|---|---|---|---|
| **Nodo Centro** (tribes) | tribu abierta con código multiuso | la mesa técnica, con la hoja de códigos de la secretaría; después, cualquier miembro | Menú → Tribus → INTRODUCIR INVITACIÓN → pegar el código de la hoja de códigos (o escanear su QR impreso). Quien ya está dentro puede dar más desde la tarjeta de la tribu → Generar invitación. | cuando tenga contenido expuesto |
| **Sala · Nodo Centro** (rooms) | sala abierta | nadie reparte: es de su tribu | La ven y entran los miembros de su tribu (Menú → Salas); sin tribu, cualquiera que la vea. | no |
| **Nodo Centro** (calendars) | calendario de tribu | el de la tribu | Lo ven los miembros de la tribu; el acceso es el de la tribu. | no |

## 6. Nodo Este  `responsable: nodo_este`

| Objeto | Tipo de acceso | Quién reparte | Dónde se obtiene | Público en /c |
|---|---|---|---|---|
| **Nodo Este** (tribes) | tribu abierta con código multiuso | la mesa técnica, con la hoja de códigos de la secretaría; después, cualquier miembro | Menú → Tribus → INTRODUCIR INVITACIÓN → pegar el código de la hoja de códigos (o escanear su QR impreso). Quien ya está dentro puede dar más desde la tarjeta de la tribu → Generar invitación. | cuando tenga contenido expuesto |
| **Sala · Nodo Este** (rooms) | sala abierta | nadie reparte: es de su tribu | La ven y entran los miembros de su tribu (Menú → Salas); sin tribu, cualquiera que la vea. | no |
| **Nodo Este** (calendars) | calendario de tribu | el de la tribu | Lo ven los miembros de la tribu; el acceso es el de la tribu. | no |

## 7. Nodo Sur  `responsable: nodo_sur`

| Objeto | Tipo de acceso | Quién reparte | Dónde se obtiene | Público en /c |
|---|---|---|---|---|
| **Nodo Sur** (tribes) | tribu abierta con código multiuso | la mesa técnica, con la hoja de códigos de la secretaría; después, cualquier miembro | Menú → Tribus → INTRODUCIR INVITACIÓN → pegar el código de la hoja de códigos (o escanear su QR impreso). Quien ya está dentro puede dar más desde la tarjeta de la tribu → Generar invitación. | cuando tenga contenido expuesto |
| **Sala · Nodo Sur** (rooms) | sala abierta | nadie reparte: es de su tribu | La ven y entran los miembros de su tribu (Menú → Salas); sin tribu, cualquiera que la vea. | no |
| **Nodo Sur** (calendars) | calendario de tribu | el de la tribu | Lo ven los miembros de la tribu; el acceso es el de la tribu. | no |

## 8. Comunicación  `responsable: comision_comunicacion`

| Objeto | Tipo de acceso | Quién reparte | Dónde se obtiene | Público en /c |
|---|---|---|---|---|
| **Comisión de Comunicación** (tribes) | tribu abierta con código multiuso | la mesa técnica, con la hoja de códigos de la secretaría; después, cualquier miembro | Menú → Tribus → INTRODUCIR INVITACIÓN → pegar el código de la hoja de códigos (o escanear su QR impreso). Quien ya está dentro puede dar más desde la tarjeta de la tribu → Generar invitación. | cuando tenga contenido expuesto |

## 9. Urbanismo  `responsable: comision_urbanismo`

| Objeto | Tipo de acceso | Quién reparte | Dónde se obtiene | Público en /c |
|---|---|---|---|---|
| **Comisión de Urbanismo** (tribes) | tribu abierta con código multiuso | la mesa técnica, con la hoja de códigos de la secretaría; después, cualquier miembro | Menú → Tribus → INTRODUCIR INVITACIÓN → pegar el código de la hoja de códigos (o escanear su QR impreso). Quien ya está dentro puede dar más desde la tarjeta de la tribu → Generar invitación. | cuando tenga contenido expuesto |

## 10. Cuidados  `responsable: comision_cuidados`

| Objeto | Tipo de acceso | Quién reparte | Dónde se obtiene | Público en /c |
|---|---|---|---|---|
| **Comisión de Cuidados** (tribes) | tribu abierta con código multiuso | la mesa técnica, con la hoja de códigos de la secretaría; después, cualquier miembro | Menú → Tribus → INTRODUCIR INVITACIÓN → pegar el código de la hoja de códigos (o escanear su QR impreso). Quien ya está dentro puede dar más desde la tarjeta de la tribu → Generar invitación. | cuando tenga contenido expuesto |

## 11. Dinamización  `responsable: comision_dinamizacion`

| Objeto | Tipo de acceso | Quién reparte | Dónde se obtiene | Público en /c |
|---|---|---|---|---|
| **Comisión de Dinamización** (tribes) | tribu abierta con código multiuso | la mesa técnica, con la hoja de códigos de la secretaría; después, cualquier miembro | Menú → Tribus → INTRODUCIR INVITACIÓN → pegar el código de la hoja de códigos (o escanear su QR impreso). Quien ya está dentro puede dar más desde la tarjeta de la tribu → Generar invitación. | cuando tenga contenido expuesto |

## 12. Mediación  `responsable: comision_mediacion`

| Objeto | Tipo de acceso | Quién reparte | Dónde se obtiene | Público en /c |
|---|---|---|---|---|
| **Comisión de Mediación** (tribes) | tribu abierta con código multiuso | la mesa técnica, con la hoja de códigos de la secretaría; después, cualquier miembro | Menú → Tribus → INTRODUCIR INVITACIÓN → pegar el código de la hoja de códigos (o escanear su QR impreso). Quien ya está dentro puede dar más desde la tarjeta de la tribu → Generar invitación. | cuando tenga contenido expuesto |

## 13. Limpieza  `responsable: comision_limpieza`

| Objeto | Tipo de acceso | Quién reparte | Dónde se obtiene | Público en /c |
|---|---|---|---|---|
| **Comisión de Limpieza** (tribes) | tribu abierta con código multiuso | la mesa técnica, con la hoja de códigos de la secretaría; después, cualquier miembro | Menú → Tribus → INTRODUCIR INVITACIÓN → pegar el código de la hoja de códigos (o escanear su QR impreso). Quien ya está dentro puede dar más desde la tarjeta de la tribu → Generar invitación. | cuando tenga contenido expuesto |

## 14. Abastecimiento  `responsable: comision_abastecimiento`

| Objeto | Tipo de acceso | Quién reparte | Dónde se obtiene | Público en /c |
|---|---|---|---|---|
| **Comisión de Abastecimiento** (tribes) | tribu abierta con código multiuso | la mesa técnica, con la hoja de códigos de la secretaría; después, cualquier miembro | Menú → Tribus → INTRODUCIR INVITACIÓN → pegar el código de la hoja de códigos (o escanear su QR impreso). Quien ya está dentro puede dar más desde la tarjeta de la tribu → Generar invitación. | cuando tenga contenido expuesto |

## 15. Comisión de Comunicación  `responsable: comision_de_comunicacion`

| Objeto | Tipo de acceso | Quién reparte | Dónde se obtiene | Público en /c |
|---|---|---|---|---|
| **Comunicación · General** (sub-tribu) | tribu abierta con código multiuso | la mesa técnica, con la hoja de códigos de la secretaría; después, cualquier miembro | Menú → Tribus → INTRODUCIR INVITACIÓN → pegar el código de la hoja de códigos (o escanear su QR impreso). Quien ya está dentro puede dar más desde la tarjeta de la tribu → Generar invitación. | cuando tenga contenido expuesto |
| **Comunicación · Redes y contenido digital** (sub-tribu) | tribu abierta con código multiuso | la mesa técnica, con la hoja de códigos de la secretaría; después, cualquier miembro | Menú → Tribus → INTRODUCIR INVITACIÓN → pegar el código de la hoja de códigos (o escanear su QR impreso). Quien ya está dentro puede dar más desde la tarjeta de la tribu → Generar invitación. | cuando tenga contenido expuesto |
| **Comunicación · Interna** (sub-tribu) | tribu abierta con código multiuso | la mesa técnica, con la hoja de códigos de la secretaría; después, cualquier miembro | Menú → Tribus → INTRODUCIR INVITACIÓN → pegar el código de la hoja de códigos (o escanear su QR impreso). Quien ya está dentro puede dar más desde la tarjeta de la tribu → Generar invitación. | cuando tenga contenido expuesto |
| **Comunicación · Audiovisual** (sub-tribu) | tribu abierta con código multiuso | la mesa técnica, con la hoja de códigos de la secretaría; después, cualquier miembro | Menú → Tribus → INTRODUCIR INVITACIÓN → pegar el código de la hoja de códigos (o escanear su QR impreso). Quien ya está dentro puede dar más desde la tarjeta de la tribu → Generar invitación. | cuando tenga contenido expuesto |
| **Comunicación · Diseño y branding** (sub-tribu) | tribu abierta con código multiuso | la mesa técnica, con la hoja de códigos de la secretaría; después, cualquier miembro | Menú → Tribus → INTRODUCIR INVITACIÓN → pegar el código de la hoja de códigos (o escanear su QR impreso). Quien ya está dentro puede dar más desde la tarjeta de la tribu → Generar invitación. | cuando tenga contenido expuesto |
| **Comunicación · Cultura y eventos** (sub-tribu) | tribu abierta con código multiuso | la mesa técnica, con la hoja de códigos de la secretaría; después, cualquier miembro | Menú → Tribus → INTRODUCIR INVITACIÓN → pegar el código de la hoja de códigos (o escanear su QR impreso). Quien ya está dentro puede dar más desde la tarjeta de la tribu → Generar invitación. | cuando tenga contenido expuesto |
| **Comunicación · Relaciones públicas (PIAR)** (sub-tribu) | tribu abierta con código multiuso | la mesa técnica, con la hoja de códigos de la secretaría; después, cualquier miembro | Menú → Tribus → INTRODUCIR INVITACIÓN → pegar el código de la hoja de códigos (o escanear su QR impreso). Quien ya está dentro puede dar más desde la tarjeta de la tribu → Generar invitación. | cuando tenga contenido expuesto |
| **Comunicación · Coordinación y gabinete de crisis** (sub-tribu) | tribu abierta con código multiuso | la mesa técnica, con la hoja de códigos de la secretaría; después, cualquier miembro | Menú → Tribus → INTRODUCIR INVITACIÓN → pegar el código de la hoja de códigos (o escanear su QR impreso). Quien ya está dentro puede dar más desde la tarjeta de la tribu → Generar invitación. | cuando tenga contenido expuesto |
| **Comunicación · Corrección de textos** (sub-tribu) | tribu abierta con código multiuso | la mesa técnica, con la hoja de códigos de la secretaría; después, cualquier miembro | Menú → Tribus → INTRODUCIR INVITACIÓN → pegar el código de la hoja de códigos (o escanear su QR impreso). Quien ya está dentro puede dar más desde la tarjeta de la tribu → Generar invitación. | cuando tenga contenido expuesto |
| **Comunicados** (mailing) | lista abierta | nadie | Quien escribe queda suscrito; nada que repartir. | no |

## 16. InterCSOs  `responsable: intercsos`

| Objeto | Tipo de acceso | Quién reparte | Dónde se obtiene | Público en /c |
|---|---|---|---|---|
| **InterCSOs** (tribes) | tribu pública estricta | la secretaría, a petición del órgano | Solo la secretaría (autora) genera un código de un uso por persona, a petición del órgano, entregado en mano; se redime en Menú → Tribus → INTRODUCIR INVITACIÓN. Sin ella nadie más entra: cada alta pasa por la mesa técnica. | cuando tenga contenido expuesto |
| **InterCSOs** (mailing) | lista cerrada (cifrada) | el autor de la lista | El autor añade miembros: Menú → Listas de correo → la lista → Miembros. Si la autora es la secretaría, hoy no hay herramienta: DECISIÓN. | no |

## 17. Asamblea de Colectivos  `responsable: asamblea_de_colectivos`

| Objeto | Tipo de acceso | Quién reparte | Dónde se obtiene | Público en /c |
|---|---|---|---|---|
| **Asamblea de Colectivos** (tribes) | tribu pública estricta | la secretaría, a petición del órgano | Solo la secretaría (autora) genera un código de un uso por persona, a petición del órgano, entregado en mano; se redime en Menú → Tribus → INTRODUCIR INVITACIÓN. Sin ella nadie más entra: cada alta pasa por la mesa técnica. | cuando tenga contenido expuesto |
| **Asamblea de Colectivos** (mailing) | lista cerrada (cifrada) | el autor de la lista | El autor añade miembros: Menú → Listas de correo → la lista → Miembros. Si la autora es la secretaría, hoy no hay herramienta: DECISIÓN. | no |

## 18. Nodos territoriales  `responsable: nodos_territoriales`

| Objeto | Tipo de acceso | Quién reparte | Dónde se obtiene | Público en /c |
|---|---|---|---|---|
| **Nodos territoriales** (maps) | mapa colaborativo | nadie reparte: es abierto | Invitación pública en la tarjeta del mapa (Menú → Mapas); cualquiera añade marcadores. | sí (tras la activación) |

## 19. documento  `responsable: documento`

| Objeto | Tipo de acceso | Quién reparte | Dónde se obtiene | Público en /c |
|---|---|---|---|---|
| **Organigrama y funcionamiento** (wiki) | wiki (open) | nadie | Menú → Wiki. Edita según la política de la página. | sí (tras la activación) |
| **Guía de reparto de accesos · 1 de 5** (wiki) | wiki (author) | nadie | Menú → Wiki. Edita según la política de la página. | sí (tras la activación) |

## 20. Técnica del semáforo  `responsable: tecnica_semaforo`

| Objeto | Tipo de acceso | Quién reparte | Dónde se obtiene | Público en /c |
|---|---|---|---|---|
| **Técnica del semáforo** (wiki) | wiki (author) | nadie | Menú → Wiki. Edita según la política de la página. | sí (tras la activación) |

## 21. Portavocías rotativas  `responsable: portavocias_rotativas`

| Objeto | Tipo de acceso | Quién reparte | Dónde se obtiene | Público en /c |
|---|---|---|---|---|
| **Portavocías rotativas** (wiki) | wiki (author) | nadie | Menú → Wiki. Edita según la política de la página. | sí (tras la activación) |

## 22. Personas  `responsable: personas`

| Objeto | Tipo de acceso | Quién reparte | Dónde se obtiene | Público en /c |
|---|---|---|---|---|
| **Oasis para el nodo · manual de bienvenida · 1 de 5** (wiki) | wiki (open) | nadie | Menú → Wiki. Edita según la política de la página. | sí (tras la activación) |

## Reglas que no cambian

- Un acceso entregado no se retira: en una tribu privada, sacar a alguien rota la clave y lo publicado antes ya está leído.
- Los códigos de un solo uso se consumen al usarse; los multiuso valen hasta que la secretaría los retira (hoy no hay herramienta para retirarlos: pedirlo a la mesa técnica, que lo anota como pendiente).
- Nada de esta guía se pega en un canal que deje el código escrito (listas, chats de terceros).
- El manual del habitante (cómo entrar con el móvil) es otro documento: la mesa técnica reparte los dos juntos.

## Pendiente de decidir por el colectivo (10)

- meta.pub: <pendiente: pub del colectivo>
- meta.autoria: <DECISIÓN del colectivo: qué identidad crea cada tribu; solo el autor la borra o reestructura>
- calendars[2] cal_nodo_norte.dates[0].hora: <pendiente: hora de la asamblea del nodo>
- calendars[3] cal_nodo_oeste.dates[0].hora: <pendiente: hora de la asamblea del nodo>
- calendars[4] cal_nodo_centro.dates[0].hora: <pendiente: hora de la asamblea del nodo>
- calendars[5] cal_nodo_este.dates[0].hora: <pendiente: hora de la asamblea del nodo>
- calendars[6] cal_nodo_sur.dates[0].hora: <pendiente: hora de la asamblea del nodo>
- maps[0] mapa_plaza.nota: <pendiente: confirmar coordenadas (aproximadas, puestas en la plantilla WP-O129 el 2026-10-07)> <pendiente: coordenadas de la plaza; 0,0 es el valor sin decidir, no una ubicación>
- federation[0].pub: <pendiente: pub de la entidad, si lo tiene>
- federation[1].pub: <pendiente: pubs de los colectivos aliados>

