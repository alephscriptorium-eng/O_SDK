# Guion de activación · Acampada26S

Plantilla `acampada26s.json` (Oasis 1.2.3, workflow `activists`). Generado por `pub/tools/template-seed.js --guion`.
Cada paso lo ejecuta **una persona desde su Oasis**; lo que publica queda en SSB para siempre (`docs/AGENTES.md` §3).
Quién crea cada objeto es decisión del colectivo: **<DECISIÓN del colectivo: qué identidad crea cada tribu; solo el autor la borra o reestructura>**.

## 0. Antes de empezar

- Cada cliente: **Settings → Workflows → activists**. El workflow es un ajuste local de cada cliente (Settings → Workflows → Activists). Ningún mensaje SSB lo transporta: el pub no puede imponerlo. Va en el guion y en el manual.
- La mesa técnica crea el invite de la asamblea: `./oasis.sh invite 500` (el código no se escribe en ningún documento).
- Quien vaya a crear tribus hace antes su copia de identidad (Tools → Backup → RECOVERY y EXPORT KEYS).
- Fechas: los `offsetDays` cuentan desde el día de activación; eventos y calendarios exigen fecha futura.

## 1. Tribus raíz (16) — `Menú → Tribes → Create Tribe`

### 1.1 Asamblea General  `origen: asamblea_general`
- Description: Órgano mayor de representación. Ratifica consensos (semáforo), espacio informativo, exposición de nodos y comisiones, lectura de comunicados.
- Tags: asamblea, acampada26s
- Status: **Pública** · Mode: **Abierta (cualquier miembro invita)**
- Tras crearla: **Open invitation → Create** (botón «Unirse a la tribu» + QR en la tarjeta). Imprimir el QR si es una tribu de calle.
- Dentro se usará: feed, forum
- Responsable del reparto: `asamblea_general`

### 1.2 Asamblea Internodos  `origen: asamblea_internodos`
- Description: Portavocías rotativas de los nodos territoriales. Pone en común las propuestas de los nodos y aglutina consensos para la Asamblea General. Sin poder de decisión.
- Tags: internodos, portavocias
- Status: **Privada** · Mode: **Estricto (solo el autor invita)**
- Dentro se usará: feed, forum
- Responsable del reparto: `asamblea_internodos`
- Nota: La membresía son las portavocías vigentes: rotar = salir + invitar (la clave de la tribu rota en cada salida).

### 1.3 Nodo Norte  `origen: nodo_norte`
- Description: Asamblea abierta de barrios y territorios del norte. Debate los temas de la Asamblea General, elabora propuestas y elige 2-3 portavoces rotativos.
- Tags: nodo, norte
- Status: **Pública** · Mode: **Abierta (cualquier miembro invita)**
- Tras crearla: **Open invitation → Create** (botón «Unirse a la tribu» + QR en la tarjeta). Imprimir el QR si es una tribu de calle.
- Dentro se usará: feed, forum, event
- Responsable del reparto: `nodo_norte`

### 1.4 Nodo Oeste  `origen: nodo_oeste`
- Description: Asamblea abierta de barrios y territorios del oeste. Debate los temas de la Asamblea General, elabora propuestas y elige 2-3 portavoces rotativos.
- Tags: nodo, oeste
- Status: **Pública** · Mode: **Abierta (cualquier miembro invita)**
- Tras crearla: **Open invitation → Create** (botón «Unirse a la tribu» + QR en la tarjeta). Imprimir el QR si es una tribu de calle.
- Dentro se usará: feed, forum, event
- Responsable del reparto: `nodo_oeste`

### 1.5 Nodo Centro  `origen: nodo_centro`
- Description: Asamblea abierta de barrios y territorios del centro. Debate los temas de la Asamblea General, elabora propuestas y elige 2-3 portavoces rotativos.
- Tags: nodo, centro
- Status: **Pública** · Mode: **Abierta (cualquier miembro invita)**
- Tras crearla: **Open invitation → Create** (botón «Unirse a la tribu» + QR en la tarjeta). Imprimir el QR si es una tribu de calle.
- Dentro se usará: feed, forum, event
- Responsable del reparto: `nodo_centro`

### 1.6 Nodo Este  `origen: nodo_este`
- Description: Asamblea abierta de barrios y territorios del este. Debate los temas de la Asamblea General, elabora propuestas y elige 2-3 portavoces rotativos.
- Tags: nodo, este
- Status: **Pública** · Mode: **Abierta (cualquier miembro invita)**
- Tras crearla: **Open invitation → Create** (botón «Unirse a la tribu» + QR en la tarjeta). Imprimir el QR si es una tribu de calle.
- Dentro se usará: feed, forum, event
- Responsable del reparto: `nodo_este`

### 1.7 Nodo Sur  `origen: nodo_sur`
- Description: Asamblea abierta de barrios y territorios del sur. Debate los temas de la Asamblea General, elabora propuestas y elige 2-3 portavoces rotativos.
- Tags: nodo, sur
- Status: **Pública** · Mode: **Abierta (cualquier miembro invita)**
- Tras crearla: **Open invitation → Create** (botón «Unirse a la tribu» + QR en la tarjeta). Imprimir el QR si es una tribu de calle.
- Dentro se usará: feed, forum, event
- Responsable del reparto: `nodo_sur`

### 1.8 Comisión de Comunicación  `origen: comision_comunicacion`
- Description: Comunicación interna y externa, redes, medios, diseño. Coordina con nodos, comisiones y Asamblea General.
- Tags: comision, comunicacion
- Status: **Pública** · Mode: **Abierta (cualquier miembro invita)**
- Tras crearla: **Open invitation → Create** (botón «Unirse a la tribu» + QR en la tarjeta). Imprimir el QR si es una tribu de calle.
- Dentro se usará: feed, forum, task
- Responsable del reparto: `comision_comunicacion`

### 1.9 Comisión de Urbanismo  `origen: comision_urbanismo`
- Description: Vivienda, ciudad, planificación.
- Tags: comision, urbanismo, vivienda
- Status: **Pública** · Mode: **Abierta (cualquier miembro invita)**
- Tras crearla: **Open invitation → Create** (botón «Unirse a la tribu» + QR en la tarjeta). Imprimir el QR si es una tribu de calle.
- Dentro se usará: feed, forum, task
- Responsable del reparto: `comision_urbanismo`

### 1.10 Comisión de Cuidados  `origen: comision_cuidados`
- Description: Bienestar, salud, primeros auxilios.
- Tags: comision, cuidados
- Status: **Pública** · Mode: **Abierta (cualquier miembro invita)**
- Tras crearla: **Open invitation → Create** (botón «Unirse a la tribu» + QR en la tarjeta). Imprimir el QR si es una tribu de calle.
- Dentro se usará: feed, forum, task
- Responsable del reparto: `comision_cuidados`

### 1.11 Comisión de Dinamización  `origen: comision_dinamizacion`
- Description: Facilita las asambleas y los procesos de decisión.
- Tags: comision, dinamizacion
- Status: **Pública** · Mode: **Abierta (cualquier miembro invita)**
- Tras crearla: **Open invitation → Create** (botón «Unirse a la tribu» + QR en la tarjeta). Imprimir el QR si es una tribu de calle.
- Dentro se usará: feed, forum, task
- Responsable del reparto: `comision_dinamizacion`

### 1.12 Comisión de Mediación  `origen: comision_mediacion`
- Description: Resolución de conflictos y convivencia.
- Tags: comision, mediacion
- Status: **Pública** · Mode: **Abierta (cualquier miembro invita)**
- Tras crearla: **Open invitation → Create** (botón «Unirse a la tribu» + QR en la tarjeta). Imprimir el QR si es una tribu de calle.
- Dentro se usará: feed, forum, task
- Responsable del reparto: `comision_mediacion`

### 1.13 Comisión de Limpieza  `origen: comision_limpieza`
- Description: Gestión de residuos y mantenimiento.
- Tags: comision, limpieza
- Status: **Pública** · Mode: **Abierta (cualquier miembro invita)**
- Tras crearla: **Open invitation → Create** (botón «Unirse a la tribu» + QR en la tarjeta). Imprimir el QR si es una tribu de calle.
- Dentro se usará: feed, forum, task
- Responsable del reparto: `comision_limpieza`

### 1.14 Comisión de Abastecimiento  `origen: comision_abastecimiento`
- Description: Alimentación, materiales y suministros.
- Tags: comision, abastecimiento
- Status: **Pública** · Mode: **Abierta (cualquier miembro invita)**
- Tras crearla: **Open invitation → Create** (botón «Unirse a la tribu» + QR en la tarjeta). Imprimir el QR si es una tribu de calle.
- Dentro se usará: feed, forum, task
- Responsable del reparto: `comision_abastecimiento`

### 1.15 InterCSOs  `origen: intercsos`
- Description: Relación con entidades y actores de la sociedad civil (ámbito estatal e internacional). Tribu de enlace.
- Tags: articulacion, intercsos
- Status: **Pública** · Mode: **Estricto (solo el autor invita)**
- Dentro se usará: feed, forum
- Responsable del reparto: `intercsos`

### 1.16 Asamblea de Colectivos  `origen: asamblea_de_colectivos`
- Description: Encuentro con otros colectivos, movimientos y organizaciones. Coordinación y alianzas. Tribu de enlace.
- Tags: articulacion, colectivos
- Status: **Pública** · Mode: **Estricto (solo el autor invita)**
- Dentro se usará: feed, forum
- Responsable del reparto: `asamblea_de_colectivos`

## 2. Sub-tribus (9) — abrir la tribu madre → Create sub-tribe

### 2.1 Comunicación · General  `origen: comision_de_comunicacion` · dentro de «Comisión de Comunicación»
- Description: Grupo general de la comisión (antes: grupo de Telegram).
- Mode: **open** · privacidad heredada de la madre · Open invitation → Create
- Dentro se usará: feed, forum

### 2.2 Comunicación · Redes y contenido digital  `origen: comision_de_comunicacion` · dentro de «Comisión de Comunicación»
- Description: Redes sociales y contenido digital.
- Mode: **open** · privacidad heredada de la madre · Open invitation → Create
- Dentro se usará: feed, forum, task

### 2.3 Comunicación · Interna  `origen: comision_de_comunicacion` · dentro de «Comisión de Comunicación»
- Description: Comunicación interna de la acampada.
- Mode: **open** · privacidad heredada de la madre · Open invitation → Create
- Dentro se usará: feed, forum

### 2.4 Comunicación · Audiovisual  `origen: comision_de_comunicacion` · dentro de «Comisión de Comunicación»
- Description: Foto y vídeo. Lo publicado va a Images, Videos, Audios y Podcasts.
- Mode: **open** · privacidad heredada de la madre · Open invitation → Create
- Dentro se usará: feed, media

### 2.5 Comunicación · Diseño y branding  `origen: comision_de_comunicacion` · dentro de «Comisión de Comunicación»
- Description: Diseño gráfico e identidad visual. Lo publicado va a Images y Docs.
- Mode: **open** · privacidad heredada de la madre · Open invitation → Create
- Dentro se usará: feed, media

### 2.6 Comunicación · Cultura y eventos  `origen: comision_de_comunicacion` · dentro de «Comisión de Comunicación»
- Description: Programación cultural. Los actos se publican como Events.
- Mode: **open** · privacidad heredada de la madre · Open invitation → Create
- Dentro se usará: feed, event

### 2.7 Comunicación · Relaciones públicas (PIAR)  `origen: comision_de_comunicacion` · dentro de «Comisión de Comunicación»
- Description: Relación con medios y entidades. Los comunicados salen por Blogs y la lista «Comunicados».
- Mode: **open** · privacidad heredada de la madre · Open invitation → Create
- Dentro se usará: feed, forum

### 2.8 Comunicación · Coordinación y gabinete de crisis  `origen: comision_de_comunicacion` · dentro de «Comisión de Comunicación»
- Description: Coordinación y respuesta rápida. Los avisos urgentes van a Emergencies.
- Mode: **open** · privacidad heredada de la madre · Open invitation → Create
- Dentro se usará: feed, forum

### 2.9 Comunicación · Corrección de textos  `origen: comision_de_comunicacion` · dentro de «Comisión de Comunicación»
- Description: Revisión de textos antes de publicar. Se trabaja en Pads.
- Mode: **open** · privacidad heredada de la madre · Open invitation → Create
- Dentro se usará: feed

## 3. Salas (7) — `Menú → Rooms → Create Room`

Las crea la identidad que las vaya a presidir: el token de la sala se firma con sus claves. Crearlas con el pub conectado, si no quedan sin centralita.

### 3.1 Sala · Asamblea General  `origen: asamblea_general`
- Description: Sala abierta de la Asamblea General (voz y texto). Para quien no puede estar en Sol a las 20:00.
- Status: **OPEN** · Tribe: «Asamblea General»

### 3.2 Sala · Internodos  `origen: asamblea_internodos`
- Description: Sala de las portavocías, solo por invitación.
- Status: **INVITE-ONLY** · Tribe: «Asamblea Internodos»
- Después: Generate invite por cada persona que deba entrar.

### 3.3 Sala · Nodo Norte  `origen: nodo_norte`
- Description: Sala abierta del nodo.
- Status: **OPEN** · Tribe: «Nodo Norte»

### 3.4 Sala · Nodo Oeste  `origen: nodo_oeste`
- Description: Sala abierta del nodo.
- Status: **OPEN** · Tribe: «Nodo Oeste»

### 3.5 Sala · Nodo Centro  `origen: nodo_centro`
- Description: Sala abierta del nodo.
- Status: **OPEN** · Tribe: «Nodo Centro»

### 3.6 Sala · Nodo Este  `origen: nodo_este`
- Description: Sala abierta del nodo.
- Status: **OPEN** · Tribe: «Nodo Este»

### 3.7 Sala · Nodo Sur  `origen: nodo_sur`
- Description: Sala abierta del nodo.
- Status: **OPEN** · Tribe: «Nodo Sur»

## 4. Calendarios (7) — `Menú → Calendars → Create`

### 4.1 Asamblea General  `origen: asamblea_general`
- Status: OPEN · Tribe: ninguna
- Fecha: día +1 a las 20:00 · label «Asamblea General» · **diaria** → el modelo no tiene intervalo diario: crea **7 fechas**, una por día (lunes, martes, miércoles, jueves, viernes, sábado, domingo), cada una con *intervalo semanal* · nota: Puerta del Sol nº 14. Ratifica consensos con la técnica del semáforo.

### 4.2 Asamblea Internodos  `origen: asamblea_internodos`
- Status: OPEN · Tribe: «Asamblea Internodos»
- Fecha: día +1 a las 19:00 · label «Asamblea Internodos» · **diaria** → el modelo no tiene intervalo diario: crea **7 fechas**, una por día (lunes, martes, miércoles, jueves, viernes, sábado, domingo), cada una con *intervalo semanal* · nota: Previa a la Asamblea General.

### 4.3 Nodo Norte  `origen: nodo_norte`
- Status: OPEN · Tribe: «Nodo Norte»
- Fecha: día +2 a las <pendiente> · label «Asamblea del nodo» · sin intervalo (**variable**): cada reunión se añade a mano con «Add date» · nota: Periodicidad según cada nodo.

### 4.4 Nodo Oeste  `origen: nodo_oeste`
- Status: OPEN · Tribe: «Nodo Oeste»
- Fecha: día +2 a las <pendiente> · label «Asamblea del nodo» · sin intervalo (**variable**): cada reunión se añade a mano con «Add date» · nota: Periodicidad según cada nodo.

### 4.5 Nodo Centro  `origen: nodo_centro`
- Status: OPEN · Tribe: «Nodo Centro»
- Fecha: día +2 a las <pendiente> · label «Asamblea del nodo» · sin intervalo (**variable**): cada reunión se añade a mano con «Add date» · nota: Periodicidad según cada nodo.

### 4.6 Nodo Este  `origen: nodo_este`
- Status: OPEN · Tribe: «Nodo Este»
- Fecha: día +2 a las <pendiente> · label «Asamblea del nodo» · sin intervalo (**variable**): cada reunión se añade a mano con «Add date» · nota: Periodicidad según cada nodo.

### 4.7 Nodo Sur  `origen: nodo_sur`
- Status: OPEN · Tribe: «Nodo Sur»
- Fecha: día +2 a las <pendiente> · label «Asamblea del nodo» · sin intervalo (**variable**): cada reunión se añade a mano con «Add date» · nota: Periodicidad según cada nodo.

## 5. Eventos (1) — `Menú → Events → Create`

### 5.1 Asamblea General · Puerta del Sol  `origen: asamblea_general`
- Description: Cada día a las 20:00 en Puerta del Sol nº 14. Espacio informativo y de consenso; ratificación con la técnica del semáforo.
- Fecha: día +1 a las 20:00 · Location: Puerta del Sol nº 14, Madrid
- Público: sí · Visible en /c: sí · Recurrencia: **diaria** → el modelo no tiene intervalo diario: crea **7 fechas**, una por día (lunes, martes, miércoles, jueves, viernes, sábado, domingo), cada una con *intervalo semanal*

## 6. Listas de correo (4) — `Menú → Mailing → Create list`

### 6.1 Acuerdos de la Asamblea General  `origen: asamblea_general`
- Description: Flujo descendente: temas y acuerdos para trabajar en los nodos. Solo publica quien la Asamblea decida; cualquiera se suscribe.
- Type: **OPEN** (pública: quien escribe queda suscrito)

### 6.2 Comunicados  `origen: comision_de_comunicacion`
- Description: Comunicados oficiales de la acampada hacia dentro y hacia fuera.
- Type: **OPEN** (pública: quien escribe queda suscrito)

### 6.3 Asamblea de Colectivos  `origen: asamblea_de_colectivos`
- Description: Coordinación con otros colectivos. Cifrada: solo miembros.
- Type: **CLOSED** (cifrada: añadir miembros al crearla)

### 6.4 InterCSOs  `origen: intercsos`
- Description: Relación con entidades de la sociedad civil. Cifrada: solo miembros.
- Type: **CLOSED** (cifrada: añadir miembros al crearla)

## 7. Wikis (4) — `Menú → Wiki → Create page`

### 7.1 Organigrama y funcionamiento  `origen: documento`
- Edit policy: **open** · Tags: organigrama
- Cuerpo: <pendiente: texto del organigrama redactado por el colectivo a partir del JSON de entrada>

### 7.2 Técnica del semáforo  `origen: tecnica_semaforo`
- Edit policy: **author** · Tags: metodo
- Cuerpo: Método de consenso para valorar las propuestas en la Asamblea General. Verde: acuerdo / a favor. Amarillo: dudas / a revisar. Rojo: en contra. En Oasis: una votación (Votes) con las tres opciones VERDE, AMARILLO, ROJO por cada propuesta.

### 7.3 Portavocías rotativas  `origen: portavocias_rotativas`
- Edit policy: **author** · Tags: metodo
- Cuerpo: 2-3 portavoces por nodo, rotativas, sin poder de decisión: transmiten las propuestas de su nodo a la Asamblea Internodos. En Oasis: ser portavoz = ser miembro de la tribu Asamblea Internodos durante el turno; al terminar, se sale de la tribu y entra la siguiente portavocía.

### 7.4 Oasis para el nodo · manual de bienvenida  `origen: personas`
- Edit policy: **open** · Tags: manual
- Cuerpo: pegar `ARCHIVO/DISCO/retro-exporter/onboarding-nodo.md`

## 8. Mapas (2) — `Menú → Maps → Create`

### 8.1 Puerta del Sol nº 14  `origen: asamblea_general`
- Type: **SINGLE** · centro 40.4169, -3.7035 · Lugar de la Asamblea General, cada día a las 20:00.

### 8.2 Nodos territoriales  `origen: nodos_territoriales`
- Type: **OPEN** · centro 40.4169, -3.7035 · Mapa colaborativo: cada nodo marca dónde se reúne.
- Nota: Los marcadores los pone cada nodo; no se inventan coordenadas.

## 9. Votaciones — convención «semaforo»  `origen: tecnica_semaforo`

- Cada propuesta que llega a ratificación es **una votación** (`Menú → Votes → Create`) con las opciones **VERDE / AMARILLO / ROJO** y plazo ≥ 7 días.
- Una votación por propuesta que llega a la Asamblea General. El módulo Votes admite opciones libres; la votación interna de Parliament no (YES/NO/ABSTENTION).
- Ejemplo: «¿Ratifica la Asamblea General la propuesta «…» del Nodo …?», plazo día +7.

## 10. Emergencias — quién usa qué categoría

- `origen: comision_cuidados` → **HEALTH**: Salud y primeros auxilios en la plaza.
- `origen: comision_de_comunicacion` → **SECURITY**: Gabinete de crisis: avisos de seguridad.
- `origen: comision_abastecimiento` → **INFRASTRUCTURE**: Cortes de suministro, materiales críticos.
- `origen: nodos_territoriales` → **NEIGHBORHOOD**: Avisos de barrio desde cada nodo.

## 11. Tribunales — convención  `origen: comision_mediacion`

- Método **MEDIATION**: Conflictos de convivencia: la Comisión de Mediación abre el caso con método MEDIATION.

## 12. Federación (2) — otros pubs

Un `follow` entre pubs es un `contact` irreversible: PERMISO expreso cada vez.

- **InterCSOs** `origen: intercsos` · pub: <pendiente: pub de la entidad, si lo tiene> · Cada entidad con pub propio: follow mutuo entre pubs y announce. Sin pub: tribu de enlace + lista CLOSED.
-   cuando se conozca: `./oasis.sh follow <feedId del pub>` y, si procede, `./oasis.sh announce <host>`
- **Asamblea de Colectivos** `origen: asamblea_de_colectivos` · pub: <pendiente: pubs de los colectivos aliados> · Una federación de pubs es la forma nativa de «asamblea de colectivos» en SSB.
-   cuando se conozca: `./oasis.sh follow <feedId del pub>` y, si procede, `./oasis.sh announce <host>`

## 13. Addenda · fuera del workflow `activists` (roadmap)

- **housing** `origen: comision_urbanismo`: Vivienda es la demanda central del movimiento: Housing publica alquiler, venta y acogida (couchsurfing) con disponibilidad. Fuera del workflow activists; encenderlo es un clic por cliente.
- **market** `origen: comision_abastecimiento`: Dar, pedir e intercambiar bienes y servicios sin dinero (exchange) o con ECOin. Complementa a Logistics (ya dentro).
- **transfers** `origen: comision_abastecimiento`: Transferencias de TIEMPO y CONFIANZA entre habitantes, además de económicas: banco de tiempo de la plaza.
- **parliament** `origen: asamblea_general`: Ratificación formal con legislaturas, propuestas y leyes. Requiere abrir una legislatura; su votación interna es sí/no, por eso el semáforo vive en Votes.
- **school** `origen: portavocias_rotativas`: Ya dentro de activists: cursos y lecciones para formar portavocías y mesa técnica.
- **banking** `origen: documento`: ECOin: un pub con cartera paga renta básica a los habitantes activos. Economía interna opcional; protocolo ECOIN-PROTOCOL.md.

## 14. Pendiente de decidir por el colectivo (9)

- meta.autoria: <DECISIÓN del colectivo: qué identidad crea cada tribu; solo el autor la borra o reestructura>
- calendars[2] cal_nodo_norte.dates[0].hora: <pendiente>
- calendars[3] cal_nodo_oeste.dates[0].hora: <pendiente>
- calendars[4] cal_nodo_centro.dates[0].hora: <pendiente>
- calendars[5] cal_nodo_este.dates[0].hora: <pendiente>
- calendars[6] cal_nodo_sur.dates[0].hora: <pendiente>
- wiki[0] wiki_organigrama: <pendiente: texto del organigrama redactado por el colectivo a partir del JSON de entrada>
- federation[0].pub: <pendiente: pub de la entidad, si lo tiene>
- federation[1].pub: <pendiente: pubs de los colectivos aliados>
