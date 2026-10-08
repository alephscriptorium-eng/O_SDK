# Plantilla de organización → infraestructura Oasis · contrato de campos

Una **plantilla** es un JSON que describe la estructura de un colectivo (órganos, reuniones, canales,
métodos de decisión) en objetos de Oasis 1.2.3. No es contenido de prueba ni un snapshot: es lo que
el colectivo ya tiene en papel, traducido. La lee `pub/tools/template-seed.js`; el método completo
está en [`docs/PUB/TEMPLATE-PROTOCOL.md`](../../docs/PUB/TEMPLATE-PROTOCOL.md).

Reglas que valen para todo el fichero:

- Cada entrada lleva **`origen`**: el `id` del organigrama de entrada del que sale. Con
  `--organigrama <json>` la herramienta comprueba que existe. Es la trazabilidad en los dos sentidos.
- **Sin fechas absolutas**: `offsetDays` desde el día de activación. Eventos y calendarios exigen fecha
  futura (`events_model.js:201`, `calendars_model.js:358`); las votaciones, ≥ 7 días
  (`votes_model.js:10`).
- **Sin secretos**: ni `secret`, ni códigos de invitación, ni direcciones de cartera. Los códigos los
  genera la activación en destino y no se escriben en ningún sitio (ley 4 de `AGENTS.md`).
- Lo que el colectivo aún no ha decidido va como `"<pendiente: …>"` o `"<DECISIÓN …>"`, nunca
  inventado. La herramienta los lista al final del guion.
- Las firmas de modelo citadas son las de `src/models/*` en Oasis 1.2.3 (`oasis-upstream/main`
  043f4634); al subir de versión se comprueban con `grep` antes de usar la plantilla.

## `meta`

| campo | tipo | para qué |
|---|---|---|
| `id` | slug | nombre de fichero del ledger y del guion |
| `nombre`, `descripcion` | texto | cabecera del guion |
| `pub` | host | el pub del colectivo (solo informativo) |
| `workflow` | clave de `WORKFLOWS` en `src/models/workflows_model.js` (`activists`, `social`, …) | lo que cada cliente activa en Settings → Workflows. **Local al cliente**: no se publica |
| `idioma` | `es`, `en`… | idioma del guion |
| `version_oasis` | `1.2.3` | la versión contra la que se verificaron las firmas |
| `organigrama` | ruta | el JSON de entrada (para `--organigrama`) |
| `autoria` | texto | quién crea cada objeto. Es la DECISIÓN del colectivo: solo el autor de una tribu la borra o reestructura (`tribes_model.js:567,625`) |

## `tribes[]` → `tribes_model.createTribe(title, description, image, location, tags, isAnonymous, inviteMode, parentTribeId, status, mapUrl)` (`tribes_model.js:315`)

| campo | valores | modelo |
|---|---|---|
| `id` | slug único | clave en el ledger |
| `origen` | id del organigrama | trazabilidad |
| `title`, `description`, `tags[]` | texto | argumentos 1, 2, 5 |
| `private` | `true` / `false` | `isAnonymous`: `true` = tribu privada, todo cifrado con su clave |
| `inviteMode` | `strict` (solo el autor invita) / `open` (cualquier miembro invita y puede haber invitación abierta) | argumento 7 |
| `openInvite` | `true` / `false` | si `true`, tras crearla: `generateOpenInvite(tribeId)` (`:621`; falla si ya existe). El QR lo pinta la vista `/tribes/:id` |
| `parent` | `id` de otra tribu de esta plantilla | sub-tribu: mismo `createTribe` con `parentTribeId`; **no existe `createSubTribe`**. Hereda la privacidad del padre |
| `content[]` | `feed`, `forum`, `event`, `task`, `report`, `votation`, `market`, `job`, `project`, `media`, `pixelia` | qué se publicará dentro con `tribes_content_model.create(tribeId, kind, data)` (`tribes_content_model.js:10`). En el guion: qué pestañas se usan |
| `nota` | texto | va al guion tal cual |

UI: `POST /tribes/create` (`Menú → Tribes → Create Tribe`); invitación abierta: `POST /tribes/open-invite/create`.

## `rooms[]` → `rooms_model.createRoom({ title, description, image, status, tags, tribeId })` (`rooms_model.js:416`)

| campo | valores |
|---|---|
| `status` | `OPEN` / `INVITE-ONLY` (`rooms_model.js:12`) |
| `tribe` | `id` de tribu de esta plantilla o `null` |

Atención: el token de la sala lo firma el sbot de quien la crea y el pub lo verifica contra el autor
(`phone_module.js:756,1262`). Las salas las crea la identidad que las va a presidir. Si al crearlas no
hay un pub conectado con `phone.roomHub`, la sala queda sin centralita (`rooms_model.js:339-345`).
UI: `POST /rooms/create`; invitación: `POST /rooms/open-invite/create/:id`.

## `calendars[]` → `calendars_model.createCalendar({ title, status, deadline, tags, firstDate, firstDateLabel, firstNote, intervalWeekly, intervalMonthly, intervalYearly, intervalDeadline, mapUrl, tribeId })` (`calendars_model.js:352`) + `addDate(calendarId, date, label, intervalWeekly, intervalMonthly, intervalYearly, intervalDeadline)` (`:609`)

| campo | valores |
|---|---|
| `status` | `OPEN` / `CLOSED` |
| `tribe` | tribu o `null` (un calendario `OPEN` suelto crea su propia clave e invitación pública, `:383-440`) |
| `dates[].label`, `.hora`, `.nota` | texto; la hora se concatena a `firstDate` |
| `dates[].offsetDays` | entero ≥ 1 |
| `dates[].recurrencia` | `diaria`, `semanal`, `mensual`, `anual`, `variable` |

**Hallazgo**: el modelo solo tiene intervalos semanal / mensual / anual. `diaria` se expresa como
**siete fechas con intervalo semanal**, una por día de la semana (la herramienta lo expande en el guion).
`variable` = una sola fecha sin intervalo; cada reunión se añade a mano con `addDate`.
UI: `POST /calendars/create`.

## `events[]` → `events_model.createEvent(title, description, date, location, price, url, attendees, tags, isPublic, mapUrl, clearnetPublic, media, recurrence)` (`events_model.js:196`)

| campo | valores |
|---|---|
| `offsetDays`, `hora` | fecha futura obligatoria |
| `isPublic` | `true` / `false` |
| `clearnetPublic` | `true` = visible en `/c` |
| `recurrencia` | como en calendarios; `recurrence = { weekly, monthly, yearly, until }` (`:230-233`, `recurrence.js`). `diaria` → 7 eventos semanales |

UI: `POST /events/create`.

## `mailing[]` → `mailing_model.createList({ title, description, listType, members, tags })` (`mailing_model.js:242`)

| campo | valores |
|---|---|
| `listType` | `OPEN` (pública; suscripción al escribir) / `CLOSED` (cifrada con `private.publish`, `:41-50`) |

UI: `POST /mailing/create`.

## `wiki[]` → `wiki_model.createPage({ title, body, tags, aliases, editPolicy, license, tribeId })` (`wiki_model.js:291`)

| campo | valores |
|---|---|
| `body` **o** `file` | texto, o ruta a un markdown del repo que la activación lee |
| `editPolicy` | `open` / `author` / `tribe` (`:45`; `closed` se normaliza a `author`, `:67`) |

Idempotente por slug: si la página existe devuelve `existing` (`:298-300`). UI: `POST /wiki/create`.

## `maps[]` → `maps_model.createMap(lat, lng, description, mapType, tags, title, tribeId, markerLabel, image)` (`maps_model.js:474`) + `addMarker(mapId, lat, lng, label, image)` (`:628`)

| campo | valores |
|---|---|
| `mapType` | `SINGLE` (un punto; rechaza marcadores, `:649`) / `OPEN` (colaborativo) / `CLOSED` |
| `markers[]` | `{ lat, lng, label }`; vacío si el colectivo no ha dado coordenadas |

UI: `POST /maps/create`.

## `votes` → `votes_model.createVote(question, deadlineISO, options, tags)` (`votes_model.js:181`)

No se siembran votaciones: se fija la **convención** (`convencion.options`, p. ej. `VERDE AMARILLO
ROJO`; las opciones son libres) y un `ejemplo` que el guion muestra como «cómo se crea una».
`offsetDays ≥ 7` (`:10`). UI: `POST /votes/create`.

## `emergencies` → `emergencies_model.createEmergency({ title, text, category, mapUrl, tags, expiresIn })`

Solo convención: `category` ∈ `WEATHER INFRASTRUCTURE HEALTH SECURITY LOST NEIGHBORHOOD`
(`emergencies_model.js:7`; otra cae a `NEIGHBORHOOD`); `expiresIn` ∈ `1d 3d 7d 30d`.

## `courts` → `courts_model.openCase({ titleBase, respondentInput, method })` (`courts_model.js:132`)

Solo convención: `method` ∈ `JUDGE DICTATOR POPULAR MEDIATION KARMATOCRACY`.

## `federation[]`

No hay modelo: son otros pubs. El guion emite `./oasis.sh follow <feedId>` y `announce` por cada uno
con `pub` conocido (precedente `devops/scripts/pub-federation.sh`). `contact` es irreversible.

## `addenda[]`

`{ modulo, origen, porQue }`: módulos fuera del workflow elegido que resolverían algo del organigrama.
Solo informa: va a la última sección del guion y a la presentación.

## `guion`

`workflow` (repite `meta.workflow`), `nota_workflow`, `invite_asamblea` (el comando con el que la mesa
técnica crea un invite de muchos usos). Lo que no se puede automatizar y siempre va al guion.

## Bloques y orden de activación

`tribes` (raíz) → `tribes` (con `parent`) → invitaciones abiertas → `rooms` → `calendars` → `events` →
`mailing` → `wiki` → `maps` → `votes` (solo guion) → `emergencies` (solo guion) → `courts` (solo guion)
→ `federation` (solo guion). Cada bloque es una unidad de permiso (`--yes <bloque>`).

## Imágenes, visibilidad en `/c` y reparto (desde WP-O131)

Tres campos transversales. Los tres son opcionales en la plantilla salvo donde se indica; la herramienta
los valida y `--hot` los ejecuta.

| campo | dónde | valores | qué hace |
|---|---|---|---|
| `image` | `tribes[]`, `rooms[]`, `maps[]`, `events[]`, `wiki[]` | nombre de fichero (sin ruta) bajo `--assets <dir>`; **png/jpg/webp** | `--hot` lo sube como blob (`blobs.add` + `blobs.push`) y pasa el id: tribu/sala/mapa en `image` (`tribes_model.js:319`, `rooms_model.js:427`, `maps_model.js:494`), evento en `media.images` (`events_model.js:228`), wiki como portada `![image:<título>](&blob)` al inicio del cuerpo (`wiki_model.js:49,182`). **SVG no**: `/c/blob/:id` no lo reconoce y `serveBlob` lo sirve como adjunto (`blobHandler.js:305-313`). Techo 50 MB; recomendado ≤ 1 MB. Calendarios y listas no tienen imagen |
| `clearnetPublic` | `rooms[]`, `calendars[]`, `maps[]`, `wiki[]` (eventos ya lo tenían) | `true` / `false` | `true` → el bloque `clearnet` de `--hot` publica `{type:'clearnetItem', target, kind, on:true}` (`backend.js:751`), que es lo que hace que el objeto salga en `/c` y en `sitemap.xml`. **Error** si el objeto lleva `tribe`: lo que tiene tribu nunca sale en `/c` (`backend.js:655-751`). Las tribus no llevan este campo: salen en `/c/tribe/:id` solo cuando tienen contenido expuesto |
| `responsable` | `tribes[]`, `rooms[]`, `calendars[]`, `mailing[]`, `maps[]` (**obligatorio**), `events[]`, `wiki[]` (opcional) | `id` de órgano del organigrama o `<pendiente: …>` | A qué órgano le toca repartir el acceso. Es un hecho del organigrama (no se inventa); **quién dentro del órgano** lo recibe es DECISIÓN del colectivo y va en `meta.reparto`. Lo lee `--reparto` |
| `meta.reparto` | `meta` | `{ mesa_tecnica, entrega }` | Cabecera de la guía de reparto: quién entrega y por qué canal (QR impreso, en mano…). Nunca el canal que deje el código escrito |

El kit visual que produce esos ficheros: `pub/tools/template-kit.py` (PNG 512×512 por objeto, determinista,
`manifest.json` con el blob id previsto `&<base64(sha256)>.sha256`); contrato en `pub/templates/assets/README.md`.

### Bloque `clearnet` (nuevo, último del orden de activación)

`tribes` → `subtribes` → `invites` → `rooms` → `calendars` → `events` → `mailing` → `wiki` → `maps` → **`clearnet`**.
Un `clearnetItem` por objeto con `clearnetPublic: true` y sin `tribe`; `kind` ∈ `rooms | calendars | maps | wiki | events`.
Es una unidad de permiso como las demás (`--yes clearnet`): hace público en la web abierta lo que antes solo
veían los habitantes.

### Guía de reparto (`--reparto`)

Libro del **operador**: una sección por `responsable` con sus objetos, el tipo de acceso (tribu abierta →
botón/QR en la tarjeta; estricta → códigos del autor; lista `CLOSED` → alta por el autor; sala `INVITE-ONLY`
→ invitación de sala; calendario/mapa suelto `OPEN` → invitación pública en la tarjeta) y **dónde se obtiene**
en la UI. Con `--ledger` (tras `--hot`) añade el enlace `/c/…` de cada objeto público (`/c/tribe/:id`,
`/c/calendars/:id`, `/c/rooms/:id`, `/c/maps/:id`, `/c/wiki/:id`, `/c/events/:eventId`). **Nunca** códigos ni
semillas. Misma fuente para tres salidas: markdown del dosier, wiki en Oasis (`wiki[]` con `file:`) y página
del sitio (`--html <plantilla poster>`).
