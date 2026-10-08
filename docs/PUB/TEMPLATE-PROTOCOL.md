# Protocolo de plantilla · del organigrama de un colectivo a la infraestructura de su pub

> **Estado · EN OBRAS 2026-10-08** (WP-O129 → WP-O131, rama `dev/scriptorium-exported`). Existen las vías
> **guion** (`--guion`), **reparto** (`--reparto`, la guía del operador) y **caliente** (`--hot`, desde el bot
> secretaría; **drill local ejecutado el 2026-10-08**, G0-G10 en verde con 12 hallazgos medidos:
> `plan/REPORTES/WP-O131-retro-bot-via-caliente.md`; alta en el VPS pendiente de GO). La vía
> **fría** (WP-O130) tiene contrato y no código: el custodio adelantó la caliente. Demos: Acampada26S
> (`ARCHIVO/DISCO/retro-exporter/`, vía guion) y la plantilla genérica **Campamento** con kit visual y bot
> retro (`ARCHIVO/DISCO/scriptorium-exported/`).

Método para convertir lo que un colectivo ya tiene en papel (asambleas, nodos, comisiones, canales,
métodos de decisión) en objetos de Oasis 1.2.3 (tribus, salas, calendarios, listas, wikis, mapas,
convenciones de voto) y **activarlo en un pub** sin publicar nada que nadie haya pedido. Es genérico:
sirve a cualquier colectivo y a cualquier pub; la instancia que lo ejercita es Acampada26S
(`acampada26s.net`, Oasis 1.2.3 upstream).

> **Modelo mental.** Una *plantilla* no son datos de prueba ni un snapshot: es **estructura**. Se
> genera una vez a partir del organigrama, se revisa con el colectivo y se activa por una de tres
> vías. Lo que se activa en un pub vivo es **permanente** (`AGENTES.md` §3): por eso el guion humano
> es la vía por defecto, y las automáticas piden permiso por bloque y nunca publican con la identidad
> del pub.

## 0. Qué es una plantilla y qué no

| Es | No es |
|---|---|
| Un JSON (`pub/templates/<org>.json`, contrato en [`pub/templates/SCHEMA.md`](https://github.com/alephscriptorium-eng/O_SDK/blob/main/pub/templates/SCHEMA.md)) con tribus, salas, calendarios, eventos, listas, wikis, mapas y convenciones | Contenido de prueba (`test/seed.js` de upstream llena un directorio de mentira; esto llena uno de verdad con lo que el colectivo decidió) |
| Trazable: cada entrada lleva `origen` = `id` del organigrama | Un snapshot `.oasissn` (`HUB-PROTOCOL.md` §13): aquello replica mensajes ya publicados; esto los crea |
| Sin fechas absolutas (`offsetDays`) y **sin secretos** | Un `.ssb` para copiar (las identidades nacen en destino, ley 4) |

## 1. Entrada: el organigrama

Contrato mínimo del JSON de entrada (el de Acampada: `ARCHIVO/DISCO/retro-exporter/entrada/acampada26s_organigrama.json`):

- `organos[]` con `id`, `nombre`, `tipo` (`asamblea`, `grupo_de_asambleas`, `comision`, `base`, …), `funciones[]`,
  `periodicidad`/`hora`/`lugar` si se reúne, `miembros[]` (con `id`) si agrupa, `subgrupos` si tiene canales.
- `relaciones[]` con `origen`, `destino`, `direccion`, `sentido` (`ascendente`/`descendente`).
- `flujo_de_decision` (`ascendente[]`, `descendente[]`, `secuencia_diaria[]`).
- `metodos_y_conceptos[]` con `id` y `aplicado_en`.

Se transcribe de lo que el colectivo publica (imagen, texto); lo que no esté, no se inventa
(`<pendiente: …>`).

## 2. Mapeo: cinco reglas

| Regla | De → a | Modelo |
|---|---|---|
| R1 | órgano → **tribu** (pública si es abierta; privada y estricta si es de portavocías); agrupación → sub-tribus | `createTribe(..., parentTribeId)` |
| R2 | reunión periódica → **calendario** con intervalo + **sala** | `createCalendar`/`addDate`, `createRoom` |
| R3 | método de decisión → **convención** sobre un módulo (semáforo = `votes` con 3 opciones) | `createVote(q, deadline, options)` |
| R4 | canal externo (Telegram, lista) → **sub-tribu** o **lista de correo** | `createTribe(parent)`, `createList` |
| R5 | espacio externo (otros colectivos) → **federación de pubs** + tribu de enlace + lista cifrada | `follow`/`announce`, `createList({CLOSED})` |

Lo que SSB no modela y se deja explícito en la plantilla: **jerarquía** (no hay órganos «encima»;
hay autores y claves → `meta.autoria` es DECISIÓN del colectivo), **workflow** (ajuste local de cada
cliente, `src/models/workflows_model.js:111-118`; el pub no puede imponerlo → va al guion),
**recurrencia diaria** (solo semanal/mensual/anual → 7 fechas semanales), **roles sin voto** (todo
miembro vota en su tribu → las ratificaciones se votan fuera de la tribu de portavocías). Tabla
completa en el mapeo de la demo: `ARCHIVO/DISCO/retro-exporter/MAPEO.md` §2.

## 3. Plantilla

Formato y firma de modelo de cada campo: [`pub/templates/SCHEMA.md`](https://github.com/alephscriptorium-eng/O_SDK/blob/main/pub/templates/SCHEMA.md).
Dos reglas que no se negocian: **sin fechas absolutas** y **sin secretos** (ni `secret`, ni códigos de
invitación, ni carteras). Lo no decidido va como `<pendiente: …>` y la herramienta lo lista al final.

Validación: `node pub/tools/template-seed.js --template <json> --organigrama <entrada> --guion`
termina con exit 0 y todos los `origen` resueltos; cada firma citada en SCHEMA existe en
`src/models/*` de la versión declarada en `meta.version_oasis` (al subir de versión: `grep` antes).

## 4. Activación

### 4.1 Las tres vías

| Vía | Qué hace | Dónde | Reversible | Estado |
|---|---|---|---|---|
| **Guion** (`--guion`) | emite un markdown paso a paso: menú de la UI, campos, quién lo crea; incluye lo que no se automatiza (workflow por cliente, invite de asamblea, federación) | cualquier Node, sin SSB | no publica nada | **disponible** (WP-O129) |
| **Fría** (`--cold`) | siembra con el sbot embebido (`src/client/gui.js`, como `test/seed.js:17-22` de upstream) en un `ssb_path` aislado con la red pausada | contenedor (`src/server/node_modules` es un enlace que solo existe en la imagen) | sí: se borra el directorio | contrato aquí; código en WP-O130 |
| **Caliente** (`--hot`) | siembra desde una identidad **«secretaría»**: sbot propio (patrón bots de soporte, `HUB-PROTOCOL.md` §3 y §11) que redime un invite del pub y publica como ella; el seeder corre dentro, por su socket unix | contenedor del bot en modo `server` (`oasis-retro-bot`, §4.5) o segundo sbot a mano en una instalación upstream (`ssb_path=<dir> node src/server/SSB_server.js start`) | el feed de la secretaría se puede dejar de seguir o bloquear; lo publicado no desaparece | **ensayada en local** (WP-O131: 146 mensajes, 10 bloques, una parada por delta y reejecución sin duplicados); VPS pendiente de GO |
| **Reparto** (`--reparto`) | emite la **guía de reparto de accesos**: por órgano responsable, qué objetos le tocan, qué tipo de acceso y dónde se obtiene; con ledger, los enlaces `/c/…` | cualquier Node, sin SSB | no publica nada | **disponible** (WP-O131, §4.6) |

**Descartado y por qué**: publicar desde una «identidad proxy» por el socket del pub. Los modelos
publican siempre como la identidad del sbot (`tribes_model.js:318`, `rooms_model.js:418`), el token de
las salas se firma con sus claves (`phone_module.js:1262`), `add` no está en el manifest top-level
(`ssb-db2/compat/db.js:11-15`) y `db.create({keys})` pasaría una clave privada por el socket (ley 4).
Publicar como el pub mismo también se descarta: todas las tribus serían del pub y sus claves quedarían
en un nodo que solo replica.

### 4.2 Qué vía en cada escenario

| Escenario | Vía | Permisos (cada uno expreso, cada vez) |
|---|---|---|
| Ensayo, formación de la mesa técnica, capturas para presentar | fría | ninguno |
| Pub nuevo, antes de `announce` | fría sobre el `ssb_path` definitivo con la red pausada; luego se anuncia | tribus, `about` |
| Pub vivo, autoría humana (hoy Acampada) | **guion** | los que ejerza cada persona desde su UI |
| Pub vivo, autoría delegable a un bot | caliente | `about` de la secretaría, invite redimida, cada bloque de tribus |

### 4.3 Contrato de la herramienta

```
node pub/tools/template-seed.js --template <json> (--guion | --reparto | --hot | --cold | --verify)
     [--organigrama <json>] [--assets <dir>] [--out <md|html>] [--html <plantilla>]
     [--yes <bloque>]... [--pub-id <feed>] [--ledger <json>] [--evidence <json>] [--reconcile]
```

- **Dry-run por defecto** en `--hot`: lista por bloque las llamadas, el número de mensajes previstos
  (`pub/tools/lib/seed-plan.js`, planificador puro, medido por llamada en los modelos) y las imágenes a
  subir; solo publica el bloque que lleve su `--yes`. Bloques, en este orden: `tribes` → `subtribes` →
  `invites` → `rooms` → `calendars` → `events` → `mailing` → `wiki` → `maps` → **`clearnet`** (§4.4).
  `votes`, `emergencies`, `courts` y `federation` son convenciones: solo guion.
- **Gates** (exit 3): `--hot` para si `whoami` = `--pub-id`/`OASIS_PUB_ID` (obligatorio: el id del pub de
  la ficha de instancia) o si el `ssb-config` del nodo lleva `pub: true` — nunca con la identidad del pub;
  `rooms` se niega sin un pub `connected` (la sala quedaría sin centralita, `rooms_model.js:339-345`);
  un `plantilla-<id>.json.lock` presente para la siembra (el keyring de tribus se reescribe entero,
  `crypto.js:60-65`: dos seeders a la vez se pisan). `--cold` parará si `ssb_path` es `~/.ssb` o
  `OASIS_NETWORK_PAUSED` ≠ `1` (WP-O130).
- **Cómo habla con el sbot**: `pub/tools/lib/seed-hot.js` NO usa `src/client/gui.js` (su `cooler.open()`
  siempre intenta un sbot embebido sobre el mismo `.ssb` y, con el `server` vivo, muere por LOCK,
  `gui.js:113-145`). Conecta con `ssb-client` por el socket unix `noauth` (permisos master, misma vía que
  `ssb-admin.js`), construye un `cooler` mínimo y carga los modelos de `src/models/*` como los carga
  `backend.js:1922-2065`. Corre **dentro del contenedor** (las dependencias solo existen en la imagen):
  `pub/scripts/retro-seed.sh` envuelve el `docker exec -u oasis -e HOME=/home/oasis`.
- **Evidencia**: antes y después de cada bloque, `createUserStream({id, reverse:true, limit:1}).value.sequence`
  y recuento por tipo (`messagesByType` filtrado por autor); una línea JSON por evento a stdout y, con
  `--evidence`, al fichero (en `/app/logs` del bot = su `logs/` fuera). Si el delta de `sequence` no es el
  previsto: **parada dura**, nada más se siembra. Los cifrados (tribus privadas, listas `CLOSED`) solo se
  miden por `sequence`; el JSON lo declara.
- **Ledger** `<keysDir>/plantilla-<id>.json` (`~/.ssb/oasis/keys/`, 0600; entidad → clave de mensaje y
  nombre de imagen → blob id), escrito **tras cada publicación**: reejecutar salta lo hecho; las wikis
  además son idempotentes por slug (`wiki_model.js:298-300`). Los códigos de invitación abierta que
  devuelve `generateOpenInvite` **no se guardan ni se imprimen**.
- **Trampas conocidas**: el stream vivo de tribus obliga a `process.exit`; `parliament` exige legislatura
  activa; eventos y calendarios exigen fecha futura; votaciones ≥ 7 días; `diaria` no existe (7 fechas
  semanales); una `hora` `<pendiente>` siembra a las 12:00 y queda listada como pendiente. Medidas en el
  drill: una `nota` en la primera fecha de un calendario es un mensaje más (`calendarNote`,
  `calendars_model.js:452-467`); el cuerpo de una wiki > 6000 B va a un `bodyBlob` que el modelo añade sin
  `push` (el seeder lo empuja: sin eso la página sale vacía en el HUB).
- **Secretaría** (`--hot`): el bot `oasis-retro-bot` (§4.5). Las claves de tribu quedan en su keyring
  (`oasis/keys/tribes-keys.json`): quién lo custodia es DECISIÓN del colectivo y entra en el backup del volumen.

### 4.4 Kit visual y visibilidad en `/c`

Todo lo que se crea debe **lucir**: cada tribu, sala, mapa, evento y wiki lleva una imagen propia, generada
desde la plantilla, con el branding del colectivo. Contrato de campos en `pub/templates/SCHEMA.md`
(«Imágenes, visibilidad en `/c` y reparto»); generador `pub/tools/template-kit.py` (Python + PIL,
determinista: misma plantilla y misma fuente → mismos bytes; `manifest.json` con sha256 y blob id previsto);
contrato del directorio en `pub/templates/assets/README.md`. Medido en 1.2.3:

- `image` de tribu/sala/mapa es un blob id; evento, `media.images[]`; wiki, portada `![image:…](&blob)` en el
  cuerpo. Calendarios y listas no tienen imagen.
- **Solo PNG/JPG/WebP**: `/c/blob/:id` no reconoce SVG y `serveBlob` lo sirve como adjunto (`blobHandler.js:305-313`).
- Tras `blobs.add`, el seeder hace `blobs.push(id)` para que el pub (y tras él el HUB) lo traigan sin esperar
  a un `want`. Que el HUB sirva `/c/blob/<id>` con `image/png` es un gate del drill, no una suposición.
- **Nada sale en `/c` por existir**: salas, calendarios, mapas, wikis y eventos de un autor solo aparecen con
  `about.visibilityPrefs.clearnet*` del autor o con un mensaje `{type:'clearnetItem', target, kind, on:true}`
  por objeto (`backend.js:655-751`; para eventos también, `backend.js:1019`: su propio `clearnetPublic` **no
  basta**, medido); lo que lleva `tribe` **nunca**; y tampoco lo que el modelo **cifra para sí** aunque esté
  suelto: mapa `SINGLE`/`CLOSED` (`maps_model.js:500-507`), calendario `CLOSED`, sala `INVITE-ONLY` (la
  validación lo rechaza). Por eso existe el bloque **`clearnet`**: publica un `clearnetItem` por objeto con
  `clearnetPublic: true` (y uno por repetición de un evento recurrente), y es una unidad de permiso como las
  demás (hace público en la web abierta lo que antes solo veían los habitantes). Las tribus públicas salen en
  `/c/tribe/:id` (medido: 24 de 24 con contenido).

### 4.5 Secretaría: el bot de soporte que siembra

Un bot más de la serie del pub (HUB §11): cuenta SSB propia, contenedor propio, estado en el volumen, fila y
`about` literal en la ficha de instancia. En la casa es el **bot nº 3, `retro.escrivivir.co`**, tipo retro
(secretaría de plantillas). Qué lo distingue de los otros dos:

- **Modo `server`** (`command: ["server"]`, solo sbot, sin HTTP). Un backend tendría su propio keyring de
  tribus en memoria (`crypto.js:549`) y pisaría el que escribe el seeder; y nada publica solo: ni avisos
  automáticos, ni `about` de `clearnetSince`, ni PM de bienvenida. Lo único que el sbot publica por su cuenta es
  `oasisVersion` tras el primer mensaje del feed (`SSB_server.js:325-340`): se declara en los gates.
- **Sin `oasis-config.json`** (en modo server apenas se lee; `regen-node-configs.js` no lo genera).
- **Bootstrap sin backend** (HUB §3 por el socket): `invite.create` en el pub (en un pub local, con
  `external: '<dominio.con.punto>'`) → host reescrito a la IP del bridge → `ssb-probe.js` con
  `SSB_ACTION=invite-accept` (precedente: UPGRADE U6) → **`docker restart`** (un nodo `server` persiste
  `conn.json` al parar: antes del reinicio está vacío) → `hub-conn-fix.js` → `docker restart` → CONNECTED;
  verificar por estado (`conn.json` sin seed, `contact` +1 en el pub). El feed del bot queda en 3:
  `contact` y `pub` (los publica `invite.accept`) y `oasisVersion` (el reinicio). La **foto base** para medir
  la siembra se toma **después** de esto: un sbot sin mensajes no tiene `db2/log.bipf` y `snapshot` lo da
  por ilegible.
- **`about` con imagen**: `ssb-admin.js publish-about '<nombre>' "$(cat /tmp/desc.txt)" --image <png>` sube el
  blob y publica un único `about` (`name`, `description`, `image`). Irreversible: literal aprobado, contar
  antes y después (HUB §12). La descripción entra al contenedor **por stdin** (`printf … | docker exec -i …
  'cat > /tmp/desc.txt'`), nunca con `docker cp` de una ruta del host: en el drill ese `cp` falló en Windows
  y el `about` salió sin descripción. Antes de dar el `about` por bueno: leer el mensaje y comprobar
  `description` no vacía e `image` = el blob id previsto. El avatar del bot entra por bind (`OASIS_RETRO_BOT_ASSETS_DIR`) o `docker cp`: los PNG no
  viajan en la imagen Docker (`.dockerignore`).
- **Qué monta**: `ssb-data`, `logs`, `config/retro-bot/ssb-config:ro` (`pub:false`, `hops:3`, `onion: []`),
  `pub/tools:ro`, `pub/templates:ro` y el directorio de assets `:ro` en `/app/pub/assets/<plantilla>` (hermano, no anidado:
  un bind dentro de otro `:ro` no se puede crear si la imagen no trae `/app/pub`; medido en el VPS). Sin `ports`, sin ruta en Caddy.
  Variables `OASIS_RETRO_BOT_*` en `pub/.env.*.example`; perfil compose `retro` (`npm run pub:local:retro-bot:up`).
- Los scripts que enumeran nodos lo conocen: `upgrade-gates.sh`, `capacity.sh`, `lib-node.sh`
  (`*retro-bot*` antes del comodín, o se mediría contra el `.ssb` del pub), `deploy-status.sh`.

### 4.6 Guía de reparto de accesos (el libro del operador)

El guion dice *quién crea* cada objeto; el manual del habitante dice *cómo se entra*. Faltaba el libro de la
**mesa técnica**: a qué órgano le toca cada tribu, sala, calendario, lista o mapa, qué tipo de acceso lleva
(abierta con QR, estricta con códigos del autor, lista cerrada, sala solo por invitación, invitación pública en
la tarjeta) y **dónde se obtiene** en la UI. Lo genera `--reparto` desde el campo `responsable` de cada objeto
(un hecho del organigrama: el órgano; quién dentro del órgano lo recibe es DECISIÓN del colectivo, `meta.reparto`).

- **Nunca códigos ni semillas** (§5): la guía dice *quién* y *dónde*, nunca *cuál*.
- Con `--ledger` (tras `--hot`) añade el enlace público de cada objeto: `/c/tribe/:id`, `/c/calendars/:id`,
  `/c/rooms/:id`, `/c/maps/:id`, `/c/wiki/:id`, `/c/events/:eventId` (rutas de 1.2.3, `backend.js:7977-8607`).
- **Una fuente, tres salidas, ninguna editada a mano**: (1) markdown del dosier; (2) wiki en Oasis (entrada
  `wiki[]` con `file:` que el bloque `wiki` siembra; se lee en `/c/wiki/:id`); (3) página del sitio del pub con
  `--html pub/site-templates/poster/guia.html` (fanzine, cero JS). En la casa: Sala 02,
  `pub/site/parlament/campamento/`. Ninguna repite lo que el visor ya muestra: enlazan a `/c`.

## 5. Verificación tras activar

- **Antes de medir `/c`**: que el HUB tenga el feed de la secretaría (`ssb-probe.js` con `SSB_FEED=<bot>` en
  el HUB: `seq` = el del bot). Está a 2 saltos (sigue al pub, el pub al bot) y la replicación no llegó sola en
  el drill: hizo falta reiniciar el HUB (20 s). Y **vaciar la caché** del HUB (VPS: `hub-disk.sh
  prune-cache`): el sitemap y las listas de antes de la siembra se sirven 7 días.
- Recuento por tipo en el visor público: `/c/sitemap.xml` y `/c/rss/<módulo>`. Aparecen **solo** los objetos
  que llevan su `clearnetItem` y que el HUB puede leer (bloque `clearnet`, §4.4); los que tienen tribu o van
  cifrados, nunca; las tribus públicas, en `/c/tribe/:id`. Cada imagen del kit: `/c/blob/<id>` responde
  `200 image/png`. Medido en el drill: 1 calendario, 7 eventos, 1 mapa, 5 wikis, 24 tribus; 0 salas (todas con tribu).
- `./oasis.sh status` (pares) y, si hubo secretaría, su `sequence` subiendo en el pub
  (`pub/tools/ssb-probe.js`).
- Las tribus con invitación abierta muestran código y QR en su tarjeta; **el código no se copia a
  ningún documento**.
- El feed del pub no ha cambiado: mismo `sequence` antes y después (si cambió, parada dura).

## 6. Lo irreversible y lo que la plantilla nunca lleva

Tabla completa en [`AGENTES.md` §3](../AGENTES.md). Para este protocolo: cada tribu, sub-tribu, sala,
calendario, lista, wiki y mapa es un mensaje permanente; cada invitación abierta también; `about`,
`contact` (follow entre pubs) e invite redimida piden PERMISO cada vez. La plantilla nunca contiene
`secret`, códigos de invitación con semilla, direcciones de cartera ni datos de otra instancia.

## 7. Addenda-roadmap

Módulos fuera del workflow elegido que resolverían algo del organigrama: `addenda[]` en la plantilla,
§3 del mapeo de la demo. Encenderlos es un clic por cliente (Settings → Modules); el protocolo no los
activa, los señala.

## 8. Registro

| Fecha | Qué | Dónde |
|---|---|---|
| 2026-10-07 | Primera plantilla (Acampada26S), guion generado, vías fría y caliente con contrato | WP-O129, `ARCHIVO/DISCO/retro-exporter/` |
| 2026-10-08 | Vía caliente escrita (`--hot`, bot retro en modo `server`, bloque `clearnet`), kit visual, guía de reparto (`--reparto`, tres salidas), plantilla genérica Campamento | WP-O131, `ARCHIVO/DISCO/scriptorium-exported/` |
| 2026-10-08 | **Drill local ejecutado**: bootstrap por socket, `about` con avatar, 146 mensajes en 10 bloques, una parada por delta (`calendarNote`), reejecución sin duplicados, `/c` del HUB con lo marcado y solo eso, 36 enlaces de la guía en 200. 12 hallazgos, 7 correcciones aplicadas | `plan/REPORTES/WP-O131-retro-bot-via-caliente.md` · `ARCHIVO/DISCO/scriptorium-exported/runbook-drill.md` |
