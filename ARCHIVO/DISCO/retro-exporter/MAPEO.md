# Mapeo · organigrama de Acampada26S → infraestructura Oasis 1.2.3

Cómo se «parsea» el modelo organizativo de `entrada/acampada26s_organigrama.json` (transcripción de
`entrada/esquema.jpg`, publicado en `acampada26s.net/c`) a objetos de Oasis. La plantilla resultante
es `pub/templates/acampada26s.json`; el guion generado, `guion-acampada26s.md`; el método genérico,
`docs/PUB/TEMPLATE-PROTOCOL.md`. Cada fila cita el `id` del organigrama y la firma del modelo que
lo materializa (verificadas sobre `src/models/*` de 1.2.3 el 2026-10-07).

## 0. Las cinco reglas

| Regla | De qué a qué | Por qué |
|---|---|---|
| R1 | **órgano → tribu** | una tribu es un grupo con feed, foro, tareas, calendario y votaciones propios, cifrado si es privada; es la unidad de pertenencia de Oasis (`onboarding-nodo.md` §6 ya lo prescribe: «una tribu por comisión, una sub-tribu por grupo de trabajo») |
| R2 | **reunión periódica → calendario con intervalo + sala** | el calendario convoca; la sala (voz y texto, por el pub como centralita) es el sitio para quien no está en la plaza |
| R3 | **método de decisión → convención sobre un módulo**, no un objeto | el semáforo no es una cosa que se crea una vez: es cómo se crea cada votación |
| R4 | **canal externo (Telegram) → sub-tribu o lista** | sustituye pieza a pieza lo que hoy vive fuera, heredando la privacidad de la comisión |
| R5 | **espacio externo (otros colectivos) → federación de pubs** | en SSB, dos colectivos se articulan haciendo que sus pubs se sigan; no hace falta un órgano nuevo |

Todo cabe en el workflow `activists` (`src/models/workflows_model.js:74-82`): GOVERNANCE + OFFICE +
red + media + mapas, sin economía. Lo que queda fuera va a la addenda (§3).

## 1. Tabla de mapeo

| Organigrama (`id`) | Oasis | Firma / ruta | Plantilla |
|---|---|---|---|
| `documento` (movimiento, objetivo) | identidad del pub, su `about`, wiki «Organigrama y funcionamiento», ventana `/c` | ya existe en `acampada26s.net/c` | `wiki_organigrama` |
| `asamblea_general` · diaria 20:00 · Sol 14 · nivel 1 | tribu **pública, abierta, con invitación abierta + QR** · calendario «Asamblea General» · sala `OPEN` · mapa `SINGLE` en Sol 14 · evento recurrente visible en `/c` · actas con `logs` | `createTribe` (`tribes_model.js:315`) · `createCalendar` (`calendars_model.js:352`) · `createRoom` (`rooms_model.js:416`) · `createMap(...,'SINGLE')` (`maps_model.js:474`) · `createEvent` (`events_model.js:196`) · `createManual` (`logs_model.js:330`) | `asamblea_general`, `cal_asamblea_general`, `sala_asamblea_general`, `mapa_sol`, `evento_asamblea_general` |
| `tecnica_semaforo` (verde / amarillo / rojo) | **convención**: cada propuesta que llega a la AG es una votación con opciones `VERDE`, `AMARILLO`, `ROJO`, plazo ≥ 7 días | `createVote(question, deadline, options)` admite opciones libres (`votes_model.js:181`); la votación interna de Parliament **no** (YES/NO/ABSTENTION fija, `parliament_model.js:911`) | `votes.convencion`, `wiki_semaforo` |
| `asamblea_internodos` · diaria 19:00 · nivel 2 | tribu **privada, estricta** (miembros = portavocías vigentes) · calendario 19:00 · sala `INVITE-ONLY` | `createTribe(..., isAnonymous=true, inviteMode='strict')`; solo el autor invita (`tribes_model.js:567`) | `asamblea_internodos`, `cal_internodos`, `sala_internodos` |
| `portavocias_rotativas` (2-3 por nodo, sin poder de decisión) | ser portavoz = **ser miembro de la tribu Internodos durante el turno**; al terminar sale y entra la siguiente (la clave de la tribu rota en cada salida) · turnos en `tasks`/`agenda` | `leaveTribe` / `generateInvite` (`tribes_model.js:563`) | `wiki_portavocias` |
| `nodos_territoriales` · 5 nodos · nivel 3 · periodicidad variable | **5 tribus públicas, abiertas, con QR** · dentro: feed, foro, eventos · calendario propio (fecha única; cada reunión se añade a mano) · sala `OPEN` · mapa `OPEN` compartido donde cada nodo marca dónde se reúne | `createTribe` ×5 · `tribes_content_model.create(tribeId, 'feed'\|'forum'\|'event')` (`tribes_content_model.js:10`) · `createCalendar` ×5 · `createRoom` ×5 · `createMap(...,'OPEN')` + `addMarker` (`maps_model.js:628`) | `nodo_*`, `cal_nodo_*`, `sala_nodo_*`, `mapa_nodos` |
| `flujo_de_decision.ascendente` (personas → nodo → internodos → AG) | debate y propuesta en el **foro de la tribu del nodo** → la portavocía la lleva al **foro de Internodos** → en la AG, **votación semáforo** | foro: `tribesContent.create(id,'forum')`; votación: `createVote` | — (es uso, no estructura) |
| `flujo_de_decision.descendente` (AG → nodos → personas) | lista de correo **«Acuerdos de la Asamblea General»** (`OPEN`: cualquiera se suscribe) + feed del pub + `campaigns` para consignas; lo público sale además por `/c` y RSS | `createList({listType:'OPEN'})` (`mailing_model.js:242`) | `lista_acuerdos` |
| `secuencia_diaria` (19:00 → 20:00) | dos calendarios con **siete fechas semanales cada uno** (el modelo no tiene intervalo diario) | `calendars_model.js:352-362`: intervalos `weekly/monthly/yearly` | `cal_internodos`, `cal_asamblea_general` |
| `personas` · nivel 4 | habitantes: identidad propia, `about`, entran con el invite del pub (`./oasis.sh invite 500` por asamblea), siguen a quien quieren; manual de bienvenida en la wiki | `invite.create` (`scripts/oasis-pub.js`) | `wiki_onboarding`, `guion.invite_asamblea` |
| `comisiones_de_trabajo` · 7 · «abiertas a toda la población» | **7 tribus públicas, abiertas, con QR impreso** · dentro: feed, foro, tareas | `createTribe` ×7 · `tribesContent.create(id,'task')` | `comision_*` |
| `comision_de_comunicacion.subgrupos` · 9 grupos de Telegram | **9 sub-tribus** de «Comisión de Comunicación» (heredan privacidad) · lista «Comunicados» · audiovisual → `images/videos/audios/podcasts` · diseño → `images/docs` · cultura → `events` · PIAR → `blogs` + lista · gabinete de crisis → `emergencies` · corrección → `pads` | sub-tribu = `createTribe(..., parentTribeId)` (no existe `createSubTribe`) | `com_*`, `lista_comunicados` |
| `comision_mediacion` | además de su tribu: **tribunales** con método `MEDIATION` | `openCase({method:'MEDIATION'})` (`courts_model.js:132-140`) | `courts.convencion` |
| `comision_cuidados` | además: **emergencias** categoría `HEALTH` | `createEmergency` (`emergencies_model.js:7`: categorías cerradas) | `emergencies.convencion` |
| `comision_urbanismo` (vivienda, ciudad) | además: wiki + mapas colaborativos; **`housing` queda fuera del workflow** | — | addenda |
| `comision_limpieza`, `comision_abastecimiento` | `tasks` por turnos · `logistics` (viajes y envíos; está en `activists`); `market` y `transfers` fuera | — | addenda |
| `comision_dinamizacion` | `polls` (sondeos rápidos), `votes`, salas | — | — |
| `otros_espacios_de_articulacion` · InterCSOs · Asamblea de Colectivos | **federación de pubs** (cada colectivo con pub: follow mutuo + announce) · tribu pública de enlace (estricta) · lista `CLOSED` (cifrada) | `contact` por `./oasis.sh follow` (irreversible); precedente `devops/scripts/pub-federation.sh` · `createList({listType:'CLOSED'})` cifra con `private.publish` (`mailing_model.js:41-50`) | `intercsos`, `asamblea_colectivos`, `lista_*`, `federation[]` |
| `relaciones[]` (flechas del esquema) | pertenencia a tribu (quién está dentro) · listas (hacia quién baja) · foros y votaciones (hacia dónde sube) | — | implícito en lo anterior |
| `nivel_jerarquico` 1-4 | **no existe en SSB.** Se emula con la autoría de cada tribu (solo el autor la borra o reestructura, `onboarding-nodo.md` §6) y la custodia de las claves | `tribes_model.js:567,625` | `meta.autoria` = DECISIÓN |

Recuento de la plantilla: 16 tribus raíz + 9 sub-tribus, 7 salas, 7 calendarios, 1 evento, 4 listas,
4 wikis, 2 mapas, 2 federaciones, 6 addenda; 24 `origen` resueltos contra el organigrama; 8 campos
pendientes del colectivo (autoría, horas de los nodos, texto del organigrama, pubs aliados).

## 2. Lo que Oasis no modela y el protocolo deja explícito

| Hueco | Qué pasa | Qué se hace |
|---|---|---|
| Jerarquía (`nivel_jerarquico`) | SSB no tiene órganos «por encima» de otros: solo autores, miembros y claves | la autoría de cada tribu es la DECISIÓN del colectivo; va en `meta.autoria` y en la cabecera del guion |
| Workflow `activists` | es un ajuste **local** de cada cliente (`workflows_model.js:111-118` escribe `oasis-config.json`); ningún mensaje SSB lo transporta; el pub no puede imponerlo | va en el guion §0 y en el manual |
| Recurrencia diaria | calendarios y eventos solo tienen intervalo semanal / mensual / anual | 7 fechas semanales (el guion las expande) |
| Portavocía «sin poder de decisión» | no hay roles: todo miembro de una tribu vota dentro de ella | las votaciones de ratificación se crean **fuera** de la tribu Internodos (en la AG), así las portavocías votan como personas |
| Semáforo en Parliament | su votación es sí/no/abstención; además exige legislatura activa (`parliament_model.js:896`) | el semáforo vive en `votes`; Parliament queda en la addenda |
| Categorías de emergencia | lista cerrada de 6 | tabla de uso por comisión (`emergencies.convencion`) |
| Salas | el token se firma con las claves de quien crea la sala; sin pub conectado al crearla, sin centralita | las crea quien la preside, con el pub conectado |

## 3. Addenda · roadmap fuera de `activists`

| Módulo | Para qué del organigrama | Qué cambia | Coste |
|---|---|---|---|
| `housing` | **vivienda** (la demanda central; `comision_urbanismo`) | alquiler, venta y acogida con disponibilidad y precio; visible en `/c` desde 1.2.3 | un clic por cliente (Settings → Modules) |
| `market` | `comision_abastecimiento`: dar, pedir, intercambiar | tipo `exchange` sin dinero, o con ECOin | idem |
| `transfers` | banco de **tiempo** y de **confianza** (categorías TIME / TRUST) además de ECONOMIC | reconocer trabajo de comisiones sin moneda | idem |
| `parliament` | ratificación formal (`asamblea_general`) | legislaturas, propuestas, leyes; voto interno sí/no | abrir legislatura; el semáforo sigue en `votes` |
| `school` (ya dentro) | formar portavocías y mesa técnica | cursos y lecciones (acampada26s ya tiene uno) | — |
| `banking` + `wallet` | economía interna | un pub con cartera paga renta básica a los activos (`ECOIN-PROTOCOL.md`) | nodo de cartera: decisión del colectivo |

## 4. Trazabilidad inversa (Oasis → organigrama)

Todo objeto de la plantilla lleva `origen`; `template-seed.js --organigrama` comprueba que cada uno
existe. Para la pregunta contraria («¿de dónde sale esta tribu?») basta `grep '"origen": "<id>"'
pub/templates/acampada26s.json`.
