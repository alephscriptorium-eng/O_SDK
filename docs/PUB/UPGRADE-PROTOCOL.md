# Protocolo de upgrade de Oasis (fork dockerizado)

> **Este repo es el sitio del upgrade** (`C:\S_LAB\o-sdk`,
> `https://github.com/alephscriptorium-eng/O_SDK.git`). No uses
> `BlockchainComPort` ni `alephscript-network-sdk` (archivado).

Subir el fork a una versión nueva de upstream (`epsylon/oasis`) sin perder identidad, sin publicar
nada que no esté previsto y sin romper las piezas que el fork ha puesto alrededor. Este protocolo
**orquesta**: dice qué se mide, en qué orden y con qué puerta. Lo particular de cada pieza vive en
su anexo (`HUB-PROTOCOL.md` §5, `ECOIN-PROTOCOL.md` §5, `../CLIENT-PROTOCOL.md` §4).

Deriva de los ciclos registrados en §7. Mide lo caro, no solo lo barato: no basta con que los
guards de `src/` sigan puestos («esto sigue existiendo»); hay que medir que Oasis **se comporta**
igual («esto sigue haciendo lo mismo») y que cada nodo publica exactamente lo declarado.

| Paso | Qué | Dónde | Puerta |
|---|---|---|---|
| §0 | Qué se sube, qué hay desplegado | host (lectura) | — |
| §1 | Preflight: de qué versión a cuál | repo | — |
| §2 | Overlay de `src/` + guards | rama `upgrade/oasis-X.Y.Z` | invariante de 7 ficheros |
| §3 | Qué cambia de comportamiento; derivados; gates locales | repo + Docker local | gates U0-U7, UM, UR, US |
| §4 | Deploy por rol | host | **GO del custodio** |
| §5 | Ciclo de red (solo si rota) | repo + host | GO |
| §6 | Healthcheck y rollback | host | — |
| §7 | Cierre y registro del ciclo | repo | — |

## 0. Qué se sube y qué hay desplegado

### 0.1 El riesgo va por rol, no por `src/`

Una sola imagen, tres maneras de arrancarla. Cada una ejecuta una parte distinta de Oasis, y por
tanto un upgrade le cambia cosas distintas:

| Rol | `command` | Qué código de Oasis ejecuta | Qué arriesga en un upgrade |
|---|---|---|---|
| **pub** | `server` | el sbot: `src/server/SSB_server.js` **y lo que carga** (su cierre de requires: también `banking_model.js`, `state-manager.js`, `typed_log.js`; el preflight lo cuenta) | dependencias `ssb-*`, `ssb_config.js`, y lo que el sbot hace solo al arrancar (anunciar versión; publicar dirección si tuviera cartera a mano). Es el único cuyo reinicio se nota en la red |
| **nodo de soporte** (HUB, bots) | `backend` | todo `src/`: sbot embebido + `backend.js` con identidad propia y, en un bot de cartera, dinero | todo lo que el backend haga **solo** al arrancar o por temporizador, y todo lo que publique |
| **cliente** | `full` | todo `src/` + GUI con una persona delante + IA | lo anterior, más cada botón nuevo que publique |

`upgrade-preflight.sh` (§1) dice qué ficheros cambian para cada rol. Para el pub no cuenta una
carpeta sino el **cierre de requires** de `SSB_server.js` (`devops/scripts/upgrade-closure.js`): el
preflight cuenta cuántos ficheros cambian para el pub y cuántos para backends y cliente; lo normal
es que el pub cargue una fracción pequeña de `src/` y los backends todo.

### 0.2 Inventario de piezas

Lo que hay alrededor de Oasis y de qué depende cada cosa. **Si añades una pieza al fork, añade su
fila**: una pieza sin fila es una pieza que nadie mira al subir.

| Pieza | Modo · código de Oasis | Contrato con upstream (sin API estable) | Cómo se comprueba | Anexo | Publica al subir |
|---|---|---|---|---|---|
| pub | `server` · cierre de `SSB_server.js` | `ssb_config.js` (guard), dependencias `ssb-*`, plugins; `ensureSelfAddressPublished` a los 5 s (inerte sin cartera alcanzable) | `check`, invite, directorio | este | `oasisVersion` +1 |
| HUB clearnet | `backend --public` | rutas `/c/*`, cabeceras, flag de primer contacto, getter del sbot, prefijo `OASIS_` | `annex` (hub) + gate `hub` | `HUB-PROTOCOL.md` §5 | `oasisVersion` +1 |
| bot de cartera | `backend`, `pub:true` si el motor está encendido | `banking_model.js`, `state-manager.js`, interruptor `isPubNode`, rutas de banca | `annex` (ecoin) + `check` + `worst` | `ECOIN-PROTOCOL.md` §5 | `oasisVersion` +1; con el motor encendido, `pubAvailability` +0..1 |
| caché del HUB | nginx | qué rutas hay, qué cabeceras manda el backend, **de qué depende la respuesta además de la URL** | gate `hub` | `HUB-PROTOCOL.md` §2 | — |
| edge | Caddy (compartido con otros vhosts) | qué prefijos enruta al HUB | sin tocar salvo ruta nueva fuera de `/c/*` | `HUB-PROTOCOL.md` §2 | — |
| panel-api y landing | `docker exec` al pub | ruta de `ssb-admin.js` y de `package.json` **dentro de la imagen** | `/public/status` da la versión nueva | — | — |
| `pub/tools/*.js` | dentro de la imagen o por stdin | `ssb-client`, `ssb_config`, API de `ssb-conn` e `ssb-invite` | gate del invite si cambian `ssb-*` (§3.4 U6) | `HUB-PROTOCOL.md` §3 | `invite-accept` (solo si se usa) |
| guardián de feeds (`feed_guard.js`, sbot, desde 1.3.8) | todos los modos | `createHistoryStream` de cada par, `db.deleteFeed`/`db.add`, `publish`; RPC `feedGuard.status` | sonda `feed-guard-status.js` tras recrear: `lastRepair: null` | §3.4 U3, §4 | **nada si el feed coincide con la red**; si un par tiene otra copia, borra la cola local y la **republica** (irreversible, sin interruptor: D-O40) |
| prefetch de blobs (`blob_prefetch.js`, sbot, desde 1.3.8) | `pub: true` (pub; bot con el motor encendido) | `db.onMsgAdded`, `friends.isFollowing`, `blobs.want` | disco de `ssb-data/blobs` del pub (`capacity.sh`, CAPACIDAD) | `CAPACIDAD.md` | — (pedir blobs no publica) |
| salas en clearnet (HUB, desde 1.3.8) | `backend --public` | `syncClearnetRooms` (20 s, cada 60 s: `viewerJoin` por RPC al plugin de teléfono), `GET /c/rooms/:id/(live·sound)` (flujo sin fin, `no-store`), `CLEARNET_ROOM_WATCHERS_MAX` | gate `hub`; `location` de nginx sin búfer ni caché | `HUB-PROTOCOL.md` §2 · `CAPACIDAD.md` §4 | — (unirse y retransmitir no publica) |
| nodo deprecated con identidad conservada (en la casa: bot nº 3 retro, `volumes-real/`, D-O36) | no corre | — | **fuera del ciclo**: no se recrea, no se mide, no se ofrece como pendiente. La imagen local `:latest` cambia en U2: un `compose up` de su servicio lo recrearía en la versión nueva | `../AGENTES.md` §2.9 y §3 | nada, si nadie lo arranca |
| maint-ui | backend sobre el `.ssb` **del pub** | — | **prohibida durante el ciclo**: todo lo que un backend publica solo lo publicaría con la identidad del pub | — | lo que publique un backend |
| ecoind | imagen propia | RPC | no se recrea en un upgrade de Oasis | `ECOIN-PROTOCOL.md` | — |
| cliente | `full` + entrypoint (`persist_client_state`, `wire_wallet_config`, `setup_oasis_config`) | forma de `oasis-config.json`, loopback, contrato de IA | drill del cliente | `../CLIENT-PROTOCOL.md` §4-§5 | `oasisVersion` +1; `wallet` si hay cartera cableada sin publicar |
| config de cada nodo (`oasis-config.json`) | bind `:ro` del compose (HUB, bot) · symlink del entrypoint (cliente) | **dónde la lee** `config-manager.js`: hasta 1.2.3 `src/configs/`; desde 1.2.4 `~/.ssb/oasis/oasis-config.json` (la vieja se copia una vez). También `lanRouter.js`, `network_pause.js` | `annex` (hub) · tras U3, `docker exec … cat ~/.ssb/oasis/oasis-config.json` = la del repo | `HUB-PROTOCOL.md` §5.2 · `ECOIN-PROTOCOL.md` §5.2 | — |
| token de admin (desde 1.2.4) | `backend.js` con `OASIS_ALLOW_HOST` | `isLoopbackRequest` exige cookie `oasis_admin` además del socket local; rechaza cabeceras de proxy | el log de arranque dice «Admin access» (el token **no** se copia); un `POST` solo-loopback sin cookie da 403 | `ECOIN-PROTOCOL.md` §5.2 | — |
| dependencias vendorizadas | `src/base/node_modules` (desde 1.2; entra con el overlay) + enlace `src/server/node_modules` que crea el `Dockerfile` | qué paquetes trae upstream, sus binarios precompilados, la versión de Node que declara | el build prueba que el núcleo carga; invariante `src/base` idéntico a upstream | §2, §3.3 | — |
| parches de `node_modules` | `apply_node_patches` del entrypoint, sobre `src/base` | versiones de `ssb-ref`, `ssb-blobs`, `multiserver`; qué trae ya parcheado upstream en lo vendorizado y qué parchea su `scripts/patch-node-modules.js` (que el fork no ejecuta sobre el repo) | `upgrade-patches-audit.js $NEW_REF` (sección `patches` del diff): ningún `pendiente` · log de arranque: cada parche del entrypoint dice «patcheado» o «ya parcheado», ninguno «no se encontró» | §2, §3.3 | — |
| snapshot del pub | `pub/tools/snapshot-build.js`, que lanza el entrypoint del pub cada `OASIS_PUB_SNAPSHOT_HOURS` horas (`pub-snapshot.sh` para mirar o forzar) | formato `OASISSN1`, ruta de `snapshot_plugin.js`, RPC `createLogStream` | gate US (§3.4) · `pub-snapshot.sh status` | `HUB-PROTOCOL.md` §13 | — (construir no publica) |
| centralita del pub (Phone y Rooms, desde 1.2.2) | clave `phone` del ssb-config del pub + `phone.relay = false` en HUB y bots (`regen-node-configs.js`) | de dónde lee el plugin su política, `relay`, `relayOpen`, `roomMax`, RPC `roomInfo` | `annex` (phone) · `phone.roomInfo` devuelve el aforo fijado | `HUB-PROTOCOL.md` §14 | — (retransmitir no publica) |
| medida de los nodos | `lib-node.sh`, `pub/tools/log-bipf.js`, `pub/tools/ssb-probe.js` | formato del log, texto de la guarda de migración, RPC `createUserStream` | `annex` (db2) · `snapshot` cuadra en las tres fuentes | §3.4 | — |
| enlace de los nodos de soporte con el pub | `start_pub_link` del entrypoint (modos `client` y `backend`) + `pub/tools/pub-link.js` + la libreta del pub (`conn.remember` de sus nodos sin `autoconnect`; `link pub` conecta solo con el que no tenga el enlace) | `maintainConnections(4, …)` (cupo de 4 salientes para pares que no son room, `conn-scheduler.js`), `inbound` fuera del cupo (parche de upstream), `oasisPeerRank` (orden y rotación, `network_pause.js`), `populatePubs`, `syncPeerBook` (`pub: true` marca `autoconnect` a todo pub), API de `ssb-conn` (`peers`, `dbPeers`, `remember`, `connect`) | `annex` (link) · `check` exige `pub_link=connected` en cada nodo de `GATE_LINK_NODES` · `[pub-link]` en el log del nodo solo en cambios de estado | `HUB-PROTOCOL.md` §2 | — (`conn.connect` no publica) |
| contrato de IA | `src/AI/*` + `client/scripts/test-ai-service.sh` | modelo, puerto, autenticación del servicio | `npm run client:test-ai` | §3.3 | — |
| Teatro, sidecar RRSS, blobstore-sidecar | estático o proceso propio | rutas `/torrents`, `/profile/edit`, `sbot.blobs` | solo si el diff toca esas rutas | sus protocolos | — |

### 0.3 Medir el host

```bash
bash devops/scripts/deploy-status.sh        # journal · pub vivo · piezas vivas y deriva · directorio · disco
```

No asumas el estado: lo que dice un documento es lo que había el día que se escribió. El bloque
**«Piezas vivas»** da la versión de Oasis **dentro de cada contenedor** (la imagen es compartida,
pero un retag no recrea a nadie: puede haber nodos en versiones distintas) y su modo. El bloque
**«Deriva»** dice si los ficheros que **no** viajan con `src/` (`Dockerfile`, entrypoint,
`.dockerignore`, compose, configs) son los del repo. Los **restos de rollback** (`src.old*`, tgz,
tags de imagen) ocupan disco y, si existe `src.old`, rompen el `mv` de §4.

> **Layout del host.** `devops/hosts/<instancia>/host.env` lleva el layout **medido**, no el
> canónico. La clave SSH vive en `devops/.ssh/` (fuera de git). En Windows, `python3` puede ser el
> stub de la Microsoft Store: el chequeo del directorio sale vacío aunque el pub esté verde;
> verifica con `python` o con node.

### 0.4 Un upgrade publica, y un rollback también

Cada **nodo** emite un mensaje `oasisVersion` al arrancar en una versión distinta de la última que
anunció. Lo hace el propio sbot (`SSB_server.js`, a los 7 s) y, en los backends, también
`backend.js`: vale para el pub en modo `server`, para los nodos de soporte y para el cliente. Es la
única publicación esperada de un upgrade, y es irreversible como cualquier mensaje SSB
(`../AGENTES.md` §3). Consecuencias:

- Cada nodo publica **uno** al subir. Volver atrás publica **otro**, y volver a subir, otro más.
  **Ningún rollback es gratis**: el de cualquier nodo pide GO.
- Recrear un nodo en la **misma** versión no publica nada… con una excepción desde 1.2.3: un
  backend **no público** (bot, cliente) que ya tenga `visibilityPrefs` publicados intenta a los 3 s
  de **cada** arranque publicar un `about` con `clearnetSince` (`syncClearnetSince`), una sola vez;
  si los índices aún no responden (medido: en el stack local nunca llegan a tiempo) no publica ni
  deja marcador, y lo reintentará en el siguiente arranque. Se declara `about=+0..1` en cada
  recreación del bot y del cliente, también en la misma versión, hasta que salga.
- Cualquier otra cosa que aparezca en el feed de un nodo tras recrearlo es una **desviación**:
  parada dura. Para eso está `upgrade-gates.sh check` (§3.4).

### 0.5 Un cambio de motor no tiene vuelta (D-O27)

Oasis 1.2 cambia el motor de base de datos (`ssb-db`/flume → `ssb-db2`). El **primer arranque** de
un nodo en la versión nueva migra `flume/log.offset` a `db2/log.bipf`, **borra `flume/`** y deja en
su sitio un fichero-guarda de texto. Una versión anterior no sabe leer la guarda: se cae al
arrancar y no escribe nada (medido, gate UR). Además el nodo ya ha publicado su `oasisVersion`.

Consecuencia: **desde que un nodo migra no hay rollback**. Reponer el log viejo y arrancar la
versión vieja sería arrancar una identidad con un log más corto que el de la red: bifurca el feed
(`../AGENTES.md` §3, `RECOVERY-PROTOCOL.md` §4). Se corrige hacia delante. A cambio:

- la migración se **ensaya** como gate bloqueante (UM, §3.4) y, en el host, sobre una copia del log
  real antes de recrear a nadie (§4, paso 5);
- cada nodo se **para y se copia en frío** justo antes de subirlo (§4);
- el GO de cada nodo se pide diciendo «sin retorno».

Un ciclo es de este tipo si el preflight trae `SSB_server.js` con otra capa de base de datos o si
`annex` marca roto un invariante de `upgrade-invariants.d/db2.tsv`.

## 1. Preflight

```bash
bash devops/scripts/upgrade-preflight.sh [--from X.Y.Z] [--to X.Y.Z]   # drift de versión + de qué commit a cuál + drift de ciclo + árbol
```

- Compara `src/server/package.json` local con `oasis-upstream/main`.
- Imprime `OLD_REF` y `NEW_REF`: el commit de upstream de la versión **desplegada** y el de la
  nueva. Upstream no etiqueta las versiones de Oasis (solo las de Android): el commit de una
  versión es el titulado `Oasis release X.Y.Z`, y **los dos** se resuelven así. Si hay varios con el
  mismo título, vale el **último**: es el que resuelve el preflight. La versión de
  partida sale del journal de deploys (último registro del **pub**); si §0.3 midió otra,
  `--from X.Y.Z`. La de llegada es la de upstream, o `--to X.Y.Z` para subir a una intermedia.
  `NEW_REF` **no es la punta de la rama**: si upstream empujó algo después de la release, el
  preflight avisa y el overlay de §2 se hace desde `$NEW_REF`, no desde `oasis-upstream/main`.
  Todo lo que sigue usa esos dos commits.
- Cuántos ficheros cambian por rol (§0.1). Los activos (traducciones, CSS, teselas y datos de
  mapas) se cuentan aparte: son miles y no son código.
- Deriva el ciclo/cap actual de la red desde el directorio y lo compara con el local (§5).
- Sale `0` = sin avisos, `1` = hay avisos. (El aviso in-app de Oasis es un no-op en Docker:
  `.dockerignore` excluye `.git` y el updater está gateado por `existsSync('../../.git')`.)

## 2. Overlay y guards

Las historias fork↔upstream no comparten merge-base (upstream se importa como snapshot). Sobre una
rama `upgrade/oasis-X.Y.Z`:

```bash
git switch -c upgrade/oasis-X.Y.Z
git rm -r -q src && git checkout $NEW_REF -- src/                # overlay LIMPIO: borra lo que upstream borró. Desde NEW_REF, no desde la rama (§1)
git checkout HEAD -- src/configs/blockchain-cycle.json           # único fichero fork-only bajo src/
# (hasta 1.3.2) git checkout $NEW_REF -- scripts/patch-node-modules.js: desde 1.3.3 el parcheador vive en src/patches/ y entra con el overlay (abajo)
# Guards cuyo fichero upstream NO tocó entre OLD_REF y NEW_REF: se recuperan tal cual.
git diff --stat $OLD_REF $NEW_REF -- <fichero>                   # vacío → git checkout HEAD -- <fichero>
# Guards cuyo fichero SÍ cambió: se reponen A MANO sobre el fichero nuevo (tabla de abajo). Un parche a tres bandas
# (git diff $OLD_REF HEAD -- <fichero> guardado antes del overlay; git apply -3) resuelve lo que no colisiona.
# Fichero BORRADO por upstream: buscar quién leía lo que el guard fijaba (git grep en $NEW_REF) y reponer el guard
# donde se lea ahora (1.3.0: snh-invite-code.json → invite-codes.json, entrada 0).
```

Por qué `git rm` antes del checkout: `git checkout <tree> -- src/` sobreescribe pero **no borra**.
Desde 1.1.3 eso es crítico: `src/configs/state-manager.js` **migra** al arrancar a `~/.ssb/oasis/**`
cualquier fichero de estado que encuentre en `src/configs/` o en `~/.ssb/`; un resto viejo acabaría
encima del estado real.

Nunca `git checkout HEAD --` de un fichero que upstream cambió: recuperar la versión vieja rompe el
árbol nuevo. En Windows el overlay sale **CRLF** en el árbol de trabajo (`autocrlf`): detecta el
EOL antes de un reemplazo literal.

**Un guard puede quedarse sin razón de ser.** Antes de reponer un guard sobre un fichero que upstream
cambió, se lee qué hace ahora upstream en ese punto y se contrasta con el asiento D-O que creó el guard:
si el cambio de upstream **cubre lo que el guard perseguía** (1.3.8: `/c/blob` pide a la red lo que el
séptimo guard pedía, y mejor), el guard **se retira** con asiento (supera al D-O de origen), su fila del
`.tsv` pasa a medir el literal de upstream que lo sustituye y la frase canónica cambia en la misma rama.
Reponerlo a ciegas deja al fork con un comportamiento peor que el de upstream.

**`src/base` (desde 1.2).** Upstream vendoriza sus dependencias en `src/base/node_modules` y deja
`src/server/node_modules` como enlace simbólico a ellas. Entran con el overlay y se versionan
enteras, tal cual:

- `.gitignore` las re-incluye al final (`!src/base/**`) y `.gitattributes` les quita la conversión
  de fin de línea (`src/base/** -text`). Comprobación previa al overlay:
  `git ls-tree -r --name-only $NEW_REF src/base | git check-ignore --stdin --no-index | wc -l` → 0.
- **Nunca `npm install` en `src/server`** (escribiría a través del enlace) ni
  `patch-node-modules.js` (`src/patches/`; hasta 1.3.2 `scripts/`) sobre el repo. El enlace lo crea el `Dockerfile`.
- Algunos paquetes traen su propio `.gitattributes` (`* text=auto`): en Windows unos pocos ficheros
  salen en CRLF pese a la regla. No rompe el invariante (git normaliza al comparar), pero obliga a
  subir `src/` al host con `-c core.eol=lf` (§4).

Commits: uno para el overlay (con los ficheros editados a mano **tal cual vienen de upstream**) y
otro para los guards repuestos. Así el diff de los guards se lee solo.

| Fichero | Qué reponer sobre el fichero nuevo |
|---|---|
| `src/backend/backend.js` | **Tres edits, (1)-(3).** (El antiguo (0), séptimo guard WP-O135/D-O31 en `.get("/c/blob/:cnBlobId")`, `getLocal` → `getResolved`, **se retiró en 1.3.8**, D-O40: desde 1.3.3 upstream pide el blob ausente a la red en segundo plano (`wantClearnetBlob`, y lo pre-pide al indexar) y responde «pendiente» con `no-store`; `hub.tsv` mide ese literal.) (1) En `.post("/update")`: conservar `isLoopbackRequest` y `safeRefererRedirect`; sustituir las dos `exec` (`git reset --hard && git pull`, `sh install.sh`) por el `console.warn` del fork. (2) Interruptor de snapshots (D-O27): `const snapshotsOff = process.env.OASIS_SNAPSHOT === 'off';` antes de `runSnapshotBuild`, y `|| snapshotsOff` en la primera condición de `runSnapshotBuild` y de `bootstrapFromPub`. (3) La parte del sexto guard que vive en este fichero (`clearnetLanguage`/`clearnetTheme`): **está descrita en la fila de `clearnet_view.js`**, abajo |
| `src/server/ssb_config.js` | `mergeDeep` en vez del spread (`config = mergeDeep(config, configData)`); bloque `OASIS_SERVER_CONFIG_OVERRIDE` antes de `const megabyte`; `blobs.max` = 50 MB (upstream lo sube a 75 desde 1.2.4; el fork lo mantiene: fila de disco de `HUB-PROTOCOL.md`, `CAPACIDAD.md`). Conservar `config.statePath`, `config.db2` y, desde 1.2.4, `readServerConfig()` y el bloque `bindHost` de upstream |
| `src/backend/updater.js` | Los dos `console.log("...new code updates are available!...")` pasan a ser el mensaje del fork. Conservar el fix de ruta con `__dirname` |
| `src/views/settings_view.js` | El `form({ action: "/update" })` pasa a ser el `p(...)` informativo |
| `src/configs/invite-codes.json` (hasta 1.2.8, `snh-invite-code.json`) | **Solo `url` de la entrada 0** = dominio del pub de la instancia (D-O22): `config-manager.defaultInvite()` la lee y es la base de los enlaces de «compartir en clearnet» (`clearnetPublicBase`, `main_views`). El `code` de SNH se conserva: `banking_model`, `phone_model` y `transfers_model` sacan de él el feed del pub de SNH |
| `src/views/clearnet_view.js` | **Sexto guard (WP-O132, D-O30), tres piezas marcadas `// guard o-sdk (WP-O132, D-O30)`:** (a) `cnWithQuery`/`propagateQuery` (los antiguos `cnWithLang`/`propagateLang` pasan a envolverlos): `lang` y `theme` del visitante viajan a todo `href="/c…"` y formulario; (b) `THEMES` + `renderThemeSelector` + `getCurrentTheme` (prioridad `cnScope().cnTheme` → `config.themes.current` → `Dark-SNH`) y el selector pintado junto al de idioma en `renderClearnetPage`; (c) en `renderClearnetPage`, **re-afirmar `cnScope().lang`** con `mv().setLanguage` antes del render (el idioma es global del proceso y la ruta esperó). Y en `backend.js`, edit (3): `clearnetLanguage` guarda siempre `store.lang`, y `clearnetTheme(ctx)` valida `?theme=` contra `THEMES` y guarda `store.cnTheme`; el middleware lo llama tras `setLanguage` en rutas `/c`. Invariantes en `upgrade-invariants.d/hub.tsv`; gate `upgrade-gates.sh hub --strict` (cruce 0 en 18 peticiones de 6 idiomas, `?theme=`, enlaces con los dos parámetros) |
| `src/configs/blockchain-cycle.json` | fork-only (marcador de ciclo; se preserva) |

Eso es **todo** lo que puede divergir de upstream dentro de `src/`. Frase canónica (D-O37, la que
citan los demás documentos): **6 guards en 6 ficheros; con `src/configs/blockchain-cycle.json` el
invariante `git diff $NEW_REF --stat -- src/` es de 7 ficheros** (D-O40; hasta 1.3.2 eran 7 guards: el
séptimo, `/c/blob`, lo absorbió upstream). Los literales de los guards del
pub (`/update`, `settings_view`, `invite-codes.json`, `blobs.max`, `mergeDeep`) están en
`upgrade-invariants.d/pub.tsv` y los del sexto en `hub.tsv`: `annex` (§3.1) los comprueba.
Fuera de `src/` el fork se mantiene entero (nunca overlay): `Dockerfile`, `docker-compose*.yml`,
`docker-entrypoint.sh`, `pub/**`, `devops/**`, `client/**`. `install.sh`/`oasis.sh` son
bare-metal: sincronizarlos con upstream es opcional.

**`patch-node-modules.js` es de upstream y se sincroniza** (desde 1.3.3 en `src/patches/`, entra con el
overlay; hasta 1.3.2 en `scripts/`, copia del fork). Es el script con el que upstream parchea sus
dependencias en bare metal (`install.sh`). El fork no lo corre sobre el repo
(solo el `Dockerfile` sobre `src/AI`, con `OASIS_AI=nav|full`), pero es la **lista de lo que
upstream espera parcheado**: desde 1.2 lo vendorizado en `src/base` suele traer ya cada parche, y
cuando no lo trae, un nodo del fork correría sin él mientras el de upstream corre con él. Por eso:
(1) viene de `$NEW_REF` (con el overlay; antes de 1.3.3, copiándolo); (2) se mide, no se lee:

```bash
node devops/scripts/upgrade-patches-audit.js $NEW_REF   # ejecuta el script de upstream EN SECO sobre src/base
```

Un parche `pendiente` es lo vendorizado sin el parche: o lo aplica `apply_node_patches` del
entrypoint (§3.3) en la misma rama, o se dispone por escrito por qué no. `sin-anclaje` es
upstream contradiciéndose (su parche no casa con su propia dependencia): se dispone igual.
`ausente` en `src/AI/**` es normal (la pila de IA se instala en el build). Los tres parches del
entrypoint (`ssb-ref`, `ssb-blobs`, `multiserver`) no se retiran porque upstream los traiga: son
idempotentes y el log de arranque sigue siendo la prueba (§3.3). Una copia del fork que se quede
atrás no se ve leyendo: el audit la saca como línea `patches` del diff (§3.1).

### Verificación de invariantes (bloqueante)

```bash
git diff $NEW_REF --stat -- src/                  # exactamente 7 ficheros: los 6 de los 6 guards + blockchain-cycle.json (frase canónica, arriba)
git diff $NEW_REF --stat -- src/base              # vacío: lo vendorizado es el de upstream
git ls-files scripts/patch-node-modules.js             # vacío desde 1.3.3: el parcheador vive en src/patches/ (lo cubre el invariante de src/)
git ls-files -s src/server/node_modules           # modo 120000: sigue siendo un enlace
node --check src/backend/backend.js               # el edit a mano parsea
node --check src/views/clearnet_view.js           # ídem, sexto guard
grep -m1 '"version"' src/server/package.json      # = X.Y.Z
node devops/scripts/upgrade-patches-audit.js $NEW_REF   # exit 0: ningún parche pendiente ni sin anclaje
```

## 3. Qué cambia de comportamiento

### 3.1 Diff de comportamiento

```bash
bash devops/scripts/upgrade-behaviour-diff.sh $OLD_REF $NEW_REF > /tmp/diff.tsv
```

Saca, de forma mecánica, los **candidatos** a cambio de comportamiento. No da veredictos.

| Sección | Qué busca | Por qué importa |
|---|---|---|
| `roles`, `files` | qué código cambia para cada rol (para el pub, el cierre de requires de `SSB_server.js`); ficheros que nacen o mueren | acota el riesgo; un borrado sin `git rm` deja restos |
| `routes` | rutas HTTP añadidas o quitadas | una GET bajo `/c/` sale al clearnet; una POST es una acción nueva de la GUI |
| `loopback` | rutas tras `isLoopbackRequest` | tocan dinero o identidad |
| `publish` | líneas que publican en SSB | cada `+` es una publicación posible que antes no existía |
| `timers` | `setInterval`/`setTimeout` | lo que hará **solo** un bot recién subido |
| `headers` | cabeceras, cookies, protocolo, host | lo que depende de quién pide y no de la URL rompe una caché compartida (D-O25) |
| `env` | `process.env.*` nuevas, o que pasan a leerse en más sitios | una variable puede cambiar el modo de arranque |
| `state` | entradas de `state-manager.js` | la migración de estado es solo hacia delante |
| `config`, `deps` | defaults de `src/configs/*.json`, `package.json` | derivados que se regeneran (§3.2); parches y gate del invite |
| `outside` | lo que upstream cambia fuera de `src/` | el overlay no lo trae: instaladores, tests |
| `annex` | invariantes de cada pieza (`devops/scripts/upgrade-invariants.d/*.tsv`) sobre el árbol de trabajo | sustituye a los bloques de grep de los anexos |
| `patches` | el `patch-node-modules.js` de `NEW_REF` (`src/patches/`; hasta 1.3.2 `scripts/`) ejecutado en seco sobre el árbol de trabajo (`upgrade-patches-audit.js`) | un `!` es un parche que upstream aplica y lo vendorizado no trae (§2) |

Una ruta que pasa a declararse con un **array de paths** (`.get(["/c/sitemap.xml", "/sitemap.xml"], …)`,
1.3.8) sale en `routes` como `-` sin haberse borrado: antes de disponer un `routes -` se busca la ruta con
`grep` en el árbol nuevo.

**Cada línea con signo `+`, `-` o `!` se dispone por escrito** en el reporte del WP del upgrade
(sección «Disposiciones», §7), citando su ID, con una de:

- `no-afecta` y por qué (qué rol lo ejecuta, por qué no cambia nada observable);
- `adaptado` en tal commit;
- `documentado` en tal sección de tal protocolo;
- `gate` tal: lo decide una medida, no una lectura.

Se pueden disponer varias líneas con una sola frase si comparten causa (un refactor que mueve
veinte llamadas). Lo que **no** vale es dejar una línea sin leer:

```bash
bash devops/scripts/upgrade-behaviour-diff.sh $OLD_REF $NEW_REF --check plan/REPORTES/WP-O<n>-….md   # sale 0
```

Una línea `!` de `annex` es una pieza del fork cuyo suelo se ha movido: se adapta **en la misma
rama** y se repite su gate. Una `!` de `patches` es un parche que upstream aplica y el fork no
tendría (§2): se aplica en el entrypoint o se dispone por qué no.

El `--check` exige además que el registro lleve las seis cabeceras de §7: sin ellas no es un
reporte de ciclo.

### 3.2 Derivados fuera de `src/` y qué viaja al host

`src/` no es lo único que cambia. Estos ficheros son copias o consecuencias de upstream:

| Fichero | Se regenera cuando | Cómo llega al host |
|---|---|---|
| `pub/config/hub/oasis-config.json` | **siempre**: `node pub/scripts/regen-node-configs.js` (copia de `src/configs/oasis-config.json` con claves fijadas, entre ellas la lista de avisos silenciados, que sale de `pm_model.js`). `HUB-PROTOCOL.md` §5.2 | bind de fichero: **in place** (`cat >`) + recrear el HUB |
| `pub/config/wallet-bot/oasis-config.json.tpl` | ídem, mismo script. `ECOIN-PROTOCOL.md` §5.2 | re-render en el host + recrear el bot |
| `pub/config/hub/ssb-config`, `pub/config/wallet-bot/ssb-config*` | cambia `src/configs/server-config.json` (arrays enteros) o rota el ciclo (§5) | in place + recrear el nodo |
| `pub/config/hub/nginx.conf.template` | `routes` o `headers` traen algo nuevo bajo `/c/` | in place + **recrear** `hub-cache` (la plantilla se renderiza al arrancar: un `reload` no la relee) |
| `pub/caddy/Caddyfile` | una ruta nueva del visor fuera de los prefijos que ya enruta | in place + `validate` + `reload` (`../AGENTES.md` §2.6) |
| `pub/site/hub/` (Sala 04) | tipos o rutas nuevas del visor | `deploy-site.sh` |
| `client/scripts/*`, `docker-entrypoint.sh` | cambia el contrato de IA, la forma de `oasis-config.json`, los módulos parcheados **o un bucle de fondo del entrypoint** (snapshot del pub, `start_pub_link`) | rebuild del cliente; en el **host**, el entrypoint de la raíz in place (sha del vivo = blob del repo antes de pisar; §0.3, deriva) y **rebuild**: la imagen se construye desde esa raíz |
| `pub/tools/*.js` (`ssb-probe.js`, `pub-link.js`, `snapshot-build.js`, `log-bipf.js`, `ssb-admin.js`…) | cambia una herramienta que viaja **dentro de la imagen** (el entrypoint las busca en `*/tools/`) o que el panel ejecuta | el host no es un checkout: a `<carpeta del compose>/tools/` in place (`.bak`, HEAD, sha) y **rebuild**. Las que van por stdin (`ssb-probe.js` desde `lib-node.sh`) no dependen de la copia del host, pero la copia debe ser la del repo: `deploy-status.sh` la vigila |
| `pub/docker-compose.pub.yml` | upstream cambia **dónde lee** un fichero que montamos por bind (1.2.4: `oasis-config.json` pasa a `~/.ssb/oasis/`), o una variable que el compose fija, o cambia el fork (healthchecks) | **antes de que viaje**: Docker Engine del host ≥ 25 (`docker version`, el comando exacto en el bloque de §3.4: los healthchecks llevan `start_interval`) · sustituir in place tras `sha256` del vivo contra el del repo + recrear los nodos afectados (ya se recrean en el ciclo) |

El reporte del WP lleva la lista **«qué viaja al host»** de este ciclo: `src/` y cada fichero de
esta tabla que haya cambiado. §4 la ejecuta; lo que no esté en la lista no se sube.

### 3.3 Guards de arranque

- **Parches de `node_modules`.** `apply_node_patches` (`docker-entrypoint.sh`) parchea tres módulos
  (`ssb-ref`, `ssb-blobs`, `multiserver`) dentro de `src/base`. Son idempotentes. **Confirmar en el
  log de arranque** que cada uno dice «patcheado» o «ya parcheado» (upstream trae ya el de
  `ssb-blobs`) y ninguno «no se encontró». Lo que upstream parchea **además** de esos tres lo
  mide `upgrade-patches-audit.js` (§2): «ya parcheado» no se afirma por grep sino por ese audit.
- **Sin instalaciones en caliente.** El entrypoint comprueba que `src/server/node_modules` lleva a
  `src/base` y, si no, no arranca. La pila de IA se instala en el build (`OASIS_AI=none|nav|full`;
  pub, HUB y bots: `none`); sin ella, `aiMod` queda en `off` aunque haya modelo.
- **Contrato de IA.** `src/AI/ai_service.mjs`: modelo, puerto y autenticación. Si `env` o `headers`
  traen algo de `src/AI/`, `npm run client:test-ai` es gate del cliente.
- **Cliente con cartera.** `persist_client_state`, `wire_wallet_config` y `setup_oasis_config`
  solo actúan con `OASIS_CLIENT_STATE_DIR` y modo distinto de `server`. Tras el overlay,
  `src/configs/oasis-config.json` debe conservar `wallet.{url,user,pass,fee}`.
- **`OASIS_TEST`.** Si el entorno la define, el backend arranca sin sbot embebido (desde 1.1.3):
  ningún compose debe definirla.

### 3.4 Gates locales

Todo se ensaya en Docker local con **identidades desechables** (`volumes-dev/`) antes de tocar el
host (`../AGENTES.md` §2.9). Stack: `pub/docker-compose.pub.yml` + `pub/.env.local`. Los gates son
bloqueantes y cada uno tiene salida esperada; ante otra salida, parada dura.

```bash
G="bash devops/scripts/upgrade-gates.sh --local"
CL="docker compose --env-file pub/.env.local -f pub/docker-compose.pub.yml --profile wallet"
docker version --format '{{.Server.Version}}'      # ≥ 25: los healthchecks del compose llevan start_interval (abajo, «Variables»)
```

| Gate | Qué | Comando | Salida esperada |
|---|---|---|---|
| **U0** | Línea base **como el host**: stack local en la versión vieja, con cada pieza en el mismo modo que en §0.3 (motor encendido si allí lo está, época del mes abierta). Copia del estado. **Si el ciclo cambia el compose** (§3.2), U0 se levanta con el compose **desplegado** (`git show main:pub/docker-compose.pub.yml > pub/docker-compose.pub.<vieja>.yml`, sin trackear): con el compose nuevo y la imagen vieja la línea base no sería «como el host» | `$CL stop oasis-pub oasis-hub oasis-wallet-bot` · `$G backup pre` · arrancar · `$G snapshot pre` (si sale NO MEDIBLE, repetirla hasta que cuadre) | todos los nodos healthy en la versión vieja; `seq` = `registros` = `sbot` en todos. Con el motor encendido el bot publica su `pubAvailability` de arranque en los primeros segundos si pasaron 12 h del anterior: una foto tomada mientras tanto da `sbot ≠ log` (medido en 1.3.2: a los 18 s no cuadra, a los 64 s sí). Ese anuncio queda en la **base**, no en el delta |
| **U1** | Árbol | verificación de §2 · `annex` · `upgrade-behaviour-diff.sh $OLD_REF $NEW_REF --check <reporte> --from-tsv /tmp/diff.tsv` (lee el TSV de §3.1, no regenera el diff) | 7 ficheros · ningún `!` · 0 IDs sin disponer |
| **U2** | Imagen nueva | etiquetar la vieja (`docker tag <imagen>:latest <imagen>:X.Y.Z-vieja`) · `npm run build` (o el build del compose del pub) · `$G smoke <imagen>:latest` | build limpio · `SMOKE OK`: versión nueva, `node --check` de `backend.js`/`clearnet_view.js`/`SSB_server.js`, **0 ficheros `secret`**, sin `.env*` (los `*.example` no cuentan), `volumes-*`, `src.old*`/`src.new*`, `devops/`, `client/` ni `ARCHIVO/` en la raíz de `/app` (`src/client` es de upstream y no cuenta), el enlace `src/server/node_modules` → `src/base`, modo `server` abre el socket del sbot, modo `backend` da `GET /c` = 200, ≥3 parches («patcheado»/«ya parcheado»), 0 líneas de error. Los contenedores del humo son efímeros (`--network none`, sin volúmenes) y se borran al acabar |
| **U3** | Recrear en orden pub → HUB → bot y medir **qué publica cada uno** | `$G up pub` · `$G up hub` · `$G up bot` · `$G check pre --wait` | cada `up` termina en `healthy` (sin espera fija) · `check --wait` repite la foto hasta que el delta es el esperado (`expect.conf`, abajo) **y** ningún `seq` cambió en los últimos `GATE_STABLE` s → `GATE OK (delta esperado y sequence estable 60 s; N s en total)` (medido en local con 1.2.8: `healthy` a los 4 s por nodo, `up` de los tres en 25 s, `check --wait` verde en 75 s) · `pub_link=connected` en HUB y bot (el enlace con el pub es criterio del `check`, abajo). · **desde 1.3.8**, `feedGuard.status()` en cada nodo (`devops/scripts/feed-guard-status.js` por stdin): `selfChecked: true`, `reportedOk: true`, `lastRepair: null`. Una desviación firme corta en la primera vuelta |
| **U4** | Visor por delante de la caché | `$CL up -d --no-deps oasis-hub hub-cache pub-web` (el puerto local lo publica el edge: sin `pub-web` todo da `000`) · recrear `hub-cache` si cambió la plantilla · `$G hub --strict` | `GATE OK`: MISS→HIT, idioma independiente del visitante, sin cruce, rutas nuevas |
| **U5** | Peor caso del bot: las páginas donde el backend refresca la cartera por su cuenta (`/banking`, `/transfers`, `/shops`, `/market`, `/school`; `GATE_WORST_PATHS` para otra lista) | `$G snapshot u5` · `$G worst` · `$G check u5 --wait --expect 'bot:karmaScore=+0..1'` | `wallet` y `(cifrado)` no se mueven; misma dirección. **`/wallet` queda fuera a propósito**: en cualquier versión, con el motor encendido, republica la dirección (`../AGENTES.md` §4) |
| **U6** | Gates propios de las piezas que el diff ha tocado | invite (`HUB-PROTOCOL.md` §3, si cambian `ssb-*`, también los vendorizados en `src/base`: un `deps +` sobre `ssb-invite*`, `ssb-conn*`, `multiserver`…; en local, abajo) · bootstrap de un bot nuevo (`ECOIN-PROTOCOL.md` §3, si cambia la publicación de la dirección) · drill del cliente (`../CLIENT-PROTOCOL.md` §5) | los de cada anexo |
| **U7** | Repetible | `$CL stop oasis-pub oasis-hub oasis-wallet-bot` · `$G restore pre --yes` · **volver a renderizar** la config del bot (`restore` repone también la renderizada vieja, que vive en `volumes-dev/`) · repetir U3 | mismo delta que la primera vez |
| **UM** | Solo si cambia el motor (§0.5). Migración sobre una **copia** de cada nodo, sin red | copia de `volumes-dev/.gates/pre/<nodo>/ssb-data` · contenedor efímero `--network none` de la imagen nueva en modo `server` · contar antes (`FULL_SCAN=1 node client/scripts/lib/inspect-log-offset.js`) y después (`pub/tools/log-bipf.js`) | guarda presente, `db2/log.bipf` existe, mismo nº de autores, registros = los de antes **+1** (el `oasisVersion` propio), 0 borrados |
| **UR** | Solo si cambia el motor. No-retorno | la imagen **vieja** en modo `server` sobre una copia ya migrada | el contenedor se cae; la guarda y `db2/log.bipf` no cambian (mismo sha256) |
| **US** | Snapshot del pub | con los tres nodos de `GATE_NODES` en marcha (el log db2 solo se lee con el contenedor arriba: si falta uno, NO MEDIBLE) · `$G snapshot <tag>` · `pub-snapshot.sh --local build` · `$G check <tag> --expect 0` · un nodo desechable pide el snapshot antes y después de aceptar un invite; otro, con `OASIS_SNAPSHOT=off` | construir no publica; sin invite: `not allowed`; con invite, el log del nodo salta en segundos; con el interruptor, no |

**El delta declarado (U3).** El delta esperado por defecto vive en
`devops/scripts/upgrade-invariants.d/expect.conf` (una línea por nodo) y `check` lo lee si no se
pasa `--expect`; lo imprime como `esperado: … (expect.conf)`. `--expect 0` declara todo a cero
(recrear en la misma versión); un `--expect '…'` explícito manda sobre el fichero (U5, U6). Lo que
el fichero declara es esta tabla; si upstream cambia lo que un nodo publica solo, cambian las dos a
la vez, en la misma rama:

| Nodo | Tipo | Cuándo | Rango |
|---|---|---|---|
| pub | `oasisVersion` | al arrancar en otra versión que la última anunciada (también el pub, en modo `server`; también al volver atrás) | `+1` |
| hub | `oasisVersion` | ídem | `+1` |
| hub | `karmaScore` | refresco de fondo del backend: si el valor cambió (o nunca lo publicó) y pasaron 24 h del último (≥ 1.2.6) | `+0..1` |
| bot | `oasisVersion` | ídem | `+1` |
| bot | `karmaScore` | ídem hub | `+0..1` |
| bot | `about` | `syncClearnetSince` a los 3 s de **cada** arranque de un backend no público con `visibilityPrefs` publicados (≥ 1.2.3); si los índices no responden, no publica y lo reintenta en el siguiente arranque (§0.4). En el HUB no: es público | `+0..1` |
| bot | `pubAvailability` | solo con el motor encendido: al arrancar relee su último anuncio y vuelve a anunciar si pasaron más de 12 h o cambió el saldo. Cada anuncio gasta una dirección del keypool: `backup-ecoin.sh` antes y después (`ECOIN-PROTOCOL.md` §9) | `+0..1` |
| todos | `ubiAllocation` | **debe ser 0**: solo lo es si la **época del mes ya está abierta** antes de subir (`épocas=` en la foto). Si no lo está, la abriría la versión nueva con sus reglas: irreversible y distinto; decídelo con el custodio antes | `0` |
| todos | `(cifrado)` | **debe ser 0**: los avisos automáticos del backend (el «bot político», el de empleo, recordatorios) se disparan con cualquier petición, también la del healthcheck, y se envían **a sí mismos un mensaje cifrado**. En un nodo de soporte van silenciados por config (`inboxMutedBots`, `HUB-PROTOCOL.md` §2). Si aparece uno, esa lista está incompleta o el nodo corre una versión que aún no la entiende | `0` |

- `oasisVersion=+0` significa que el nodo no subió de versión (imagen vieja, o un estado que ya
  había pasado por la nueva: `restore` antes de repetir).
- En el pub, cualquier otra cosa es una desviación: algo arrancó un backend sobre su `.ssb`. El pub
  en modo `server` no carga el backend: ni `karmaScore`, ni `about`, ni cifrados.
- Un nodo que **nunca** publicó un tipo `+0..1` lo publica al subir (`+1`): sigue dentro del rango.

**U6 en local, invite completo.** `test-invite.sh` solo tiene modo host;
en local se hace con un **nodo desechable** de la imagen nueva, sin volúmenes, en la red del
compose: `$G snapshot u6` · invite de un uso en el pub (`invite.create({ uses: 1, external:
'<dominio.con.punto>' })` por `ssb-client` dentro del contenedor del pub) y reescribir el host a
la IP del pub en el bridge · `docker run -d --network <red del compose> -e OASIS_SNAPSHOT=off … <imagen> backend`
· `ssb-probe.js` con `SSB_ACTION=invite-accept` desde el desechable ·
`$G check u6 --expect 'pub:contact=+1 hub:=0 bot:about=+0..1'` · `docker rm -f` del desechable.
Salida esperada: `accept: true`, el pub como par `connected`, y el pub publica **exactamente un
`contact`**. El invite lleva semilla: no se imprime. Todo `docker exec` a mano desde Git Bash lleva
`MSYS_NO_PATHCONV=1` **solo en esa orden** (`../AGENTES.md` §4).

**Cuándo medir.** Un nodo no publica todo «al arrancar»: el sbot anuncia versión a los 7 s, el motor
hace su primer tick a los 15 s, y los avisos automáticos esperan a la primera petición con los
índices listos. Nadie cuenta ese tiempo a mano: `up` termina en cuanto el nodo está `healthy` y
`check <tag> --wait` lo espera **midiendo**: repite la foto cada `--every` s (20) hasta que el delta
coincide con el esperado **y** ningún `seq` cambió en los últimos `--stable` s (60); es verde solo
por estabilidad, nunca por tiempo. Una desviación firme (tipo no esperado, `+N` por encima del
rango, feed o dirección cambiados, errores en el log) corta en la primera vuelta; al agotar `--max`
(600) sin alcanzar el esperado → DESVIACIÓN (rc 1); si la foto no cuadra → NO MEDIBLE (rc 3).
`--min-age N` hace PREMATURA (NO MEDIBLE) la medida de un nodo recreado hace menos de N s; con
`--wait`, el bucle espera a cumplirlo. En `--remote` vale 300 por defecto: en el host el `check`
que cuenta es el que el propio script da por maduro, no el que el operador hace «a los 5 minutos»;
se repite en el cierre (`snapshot post`). En `--local` vale 0.

`check` exige además que el feed de cada nodo sea el mismo, que `Δsequence` == suma de Δ por tipo
(cifrados incluidos) y que el sbot vivo dé el mismo `sequence`. Si eso no cuadra responde
**NO MEDIBLE**: no es un verde. Y exige el **enlace con el pub** de cada nodo de soporte
(`GATE_LINK_NODES`): la foto lleva `peers` (pares conectados, cuántos entrantes) y `pub_link`
(`connected` con dirección `in|out` · `ausente` · `?`), medidos por `conn.peers()` del propio nodo
buscando la clave del pub, nunca por el log del pub. `pub_link=?` es NO MEDIBLE; `ausente` es
«todavía no» con `--wait` (el keepalive del nodo lo repone solo, §6) y DESVIACIÓN sin él o al agotar
`--max`. Un `ausente` que no se repone se restablece con `upgrade-gates.sh link <alias> --yes` (§4,
pasos 8-9), no esperando.

**La medida lee los dos formatos de log.** `flume/log.offset` (JSON, con `grep`) y `db2/log.bipf`
(binario, con `pub/tools/log-bipf.js` dentro del contenedor). La foto dice cuál leyó (`log=flume` o
`log=db2`) y `check` enseña el cambio. Un log que no se puede leer es `?`, y `?` es NO MEDIBLE:
nunca un 0. Si el nodo publica entre la lectura del log y la pregunta al sbot, las dos fuentes no
cuadran: se repite la foto.

**Lo que el ensayo local no reproduce.** El `Dockerfile` y el entrypoint del host pueden no ser
los del repo (§0.3, «Deriva»). Por eso la imagen que se construye **en** el host se prueba allí
con el mismo humo (`upgrade-gates.sh --remote smoke`) antes de recrear ningún nodo (§4, paso 6).

**Variables de los gates.** Todas opcionales; el valor entre paréntesis es el que rige si no se
definen.

| Variable / opción | Qué fija | Dónde |
|---|---|---|
| `GATE_UP_TIMEOUT` (300) | segundos que `up` espera a `healthy` antes de fallar | `up` |
| `GATE_SETTLE` (sin definir) | **opt-in**: si se define, `up` duerme esos segundos tras `healthy`. Por defecto no duerme: la espera la hace `check --wait` | `up` |
| `GATE_WAIT_MAX` / `--max` (600) · `GATE_WAIT_EVERY` / `--every` (20) · `GATE_STABLE` / `--stable` (60) | tope, cadencia y ventana de estabilidad de `check --wait` | `check` |
| `GATE_MIN_AGE` / `--min-age` (300 en `--remote`, 0 en `--local`) | edad mínima del nodo desde su `StartedAt` para que la foto no sea PREMATURA | `check` |
| `GATE_SMOKE_MAX` / `--max` (120) | segundos que `smoke` espera al socket del sbot y a `GET /c` = 200 | `smoke` |
| `GATE_WORST_PATHS` | lista de rutas de `worst` (por defecto `/banking /transfers /shops /market /school`) | `worst` |
| `GATE_RSS_MODULE` (`feed`) | módulo del RSS (`/c/rss/<módulo>`) que `hub --strict` pide | `hub` |
| `HUB_CACHE_CONTAINER` (`oasis-pub-hub-cache`) | contenedor de la caché desde el que `hub` pide al backend por dentro | `hub` |
| `GATE_NODES` | qué nodos entran en la foto (la base y la medida deben llevar los **mismos**; `../AGENTES.md` §4) | `snapshot`, `check` |
| `GATE_PUB_ALIAS` (`pub`) | alias del pub en `GATE_NODES`: su feed es la clave que `pub_link` busca en los demás | `snapshot`, `check`, `link` |
| `GATE_LINK_NODES` (los alias de `GATE_NODES` distintos de `GATE_PUB_ALIAS`) | nodos de soporte a los que se les exige `pub_link=connected` | `snapshot`, `check`, `link` |
| `GATE_PUB_LINK_HOST` (`oasis-pub`) | host del pub en la red del compose que `link <alias>` pide a `pub-link.js --ensure` del nodo | `link` |
| `expect.conf` | delta por defecto de `check` (una línea por nodo); `--expect` explícito manda | `check` |
| `--from-tsv <tsv>` · `--skip <secciones>` | `--check` sobre un TSV ya generado (segundos, no minutos) · secciones que el diff no genera | `upgrade-behaviour-diff.sh` |
| `start_interval: 3s` (compose local) | cadencia del healthcheck de pub, HUB y bot **durante `start_period`**: `up` ve el `healthy` en segundos. Exige Docker Engine ≥ 25 en la máquina que corre el compose (`docker version`, el comando exacto en el bloque de arranque de esta sección) | compose |

## 4. Deploy por rol (host)

**Puerta: GO expreso del custodio** antes de escribir en el host y antes de cada paso marcado
(`plan/PRACTICAS.md`). Un comando por paso: nada de cadenas largas sobre un host vivo. Reglas de
siempre (`../AGENTES.md` §2): un servicio cada vez con `up -d --no-deps`, nunca el `deploy.sh` del
host, binds de fichero in place, Caddy `validate` + `reload`.

```bash
C="docker compose --env-file .env.prod -f docker-compose.pub.yml"     # en la carpeta del compose del host
R="bash devops/scripts/upgrade-gates.sh --remote"                     # en la máquina operadora
```

| # | Paso | Detalle | Puerta |
|---|---|---|---|
| 0 | **Medir** | `deploy-status.sh` · `$R snapshot pre` · `df -h /` · `docker system df` | lectura |
| 1 | **Backups** | `backup-oasis-pub.sh` · `backup-ecoin.sh` (si hay cartera) · tgz de `ssb-data` de cada nodo de soporte · copia `*.bak-<etiqueta>-<fecha>` de cada fichero que vaya a cambiar (las de ficheros bajo `site/`, **fuera** de `site/`: esa carpeta se sirve al público). Si §0.3 dio **deriva** en `Dockerfile`, entrypoint, `.dockerignore` o compose y el ciclo los cambia: traerlos, diferenciarlos con el repo y converger **in place** (no afecta a nadie hasta el build o hasta recrear). **Antes de sobrescribir**: el sha del vivo debe ser un blob del repo (`git log --all --find-object`), el diff vivo→repo solo debe añadir lo que el ciclo trae, y si el host tiene **otro layout** (carpeta del compose con otro nombre, raíz pre-refactor) el `.dockerignore` del host **no se converge**: se comprueba que cumple lo de arriba (rollbacks de `src` con comodín, `.env` de producción fuera, sin material de identidad) y se deja; `smoke` lo mide | **GO-1** |
| 2 | **Disco** | retirar el rollback del ciclo **anterior** (tag de imagen, `src.old*`, tgz) · `docker image prune -f` · `docker builder prune -f`. Cada rebuild deja ~3 GB | |
| 3 | **Rollback de este ciclo** | `docker tag <imagen>:latest <imagen>:<ver-vieja>` · `sudo tar -czf <datos>/src-<ver-vieja>.tgz src` (la carpeta de datos es de root) | |
| 4 | **Subir `src/`** | ver abajo | |
| 5 | **Lo demás que viaja** (§3.2) que sea inocuo en la versión vieja: se sube y se aplica **ahora**, con los nodos todavía en la versión vieja, y se comprueba | p. ej. plantilla nginx: a un temporal del host · `nginx -t` en un contenedor desechable · in place · `$C up -d --no-deps --force-recreate hub-cache` · `$R hub` · salud de **todos** los vhosts del edge. Si viaja el compose: antes, Docker Engine del host ≥ 25 (`docker version`; §3.2, §3.4) | |
| 6 | **Build y humo** | `$C build oasis-pub` (el pub sigue sirviendo) · `$R smoke <imagen>:latest` (abajo) · si cambia el motor, **ensayo de migración** (abajo) · `df -h /` | |
| 7 | **Pub** | si cambia el motor: `$C stop oasis-pub` y tgz en frío de su `ssb-data` (se queda en el host) · `$C up -d --no-deps oasis-pub` · esperar a `healthy` (la migración ocurre antes de abrir el sbot) · `$R check pre --wait --expect 'pub:oasisVersion=+1'` (`--min-age` 300 por defecto en `--remote`: la foto madura la impone el script) · invite · `/public/status` | **GO-2** (el pub se reinicia y publica `oasisVersion`; si cambia el motor, **sin retorno**) |
| 8 | **HUB** | sus configs in place · si cambia el motor, parar y tgz en frío · `$C up -d --no-deps oasis-hub` · `$R check … --wait` (mide también el enlace: `pub_link=connected`; si queda `ausente` agotado el tope → `$R link hub --yes` con GO y repetir el `check`, nunca seguir a ciegas) · `hub-disk.sh prune-cache` · `$R hub --strict` (en ese orden: la caché guarda 404 de las rutas que la versión vieja no tenía) · ficheros del sitio que cambien: **uno a uno**, tras comprobar que el vivo es el del repo (`deploy-site.sh` sincroniza el sitio entero con `--delete`) | **GO-3** (publica `oasisVersion`) |
| 9 | **Bot de cartera** | plantilla in place y render (**con `sudo` en el host**: el destino es de otro uid y está a 400) · motor encendido: `hub-wallet.sh pause` (lo recrea en la versión nueva con el motor **apagado**) · `$R check … --wait` (misma dirección, `wallet` sin cambios, `pub_link=connected`: si queda `ausente` agotado el tope → `$R link bot --yes` con GO y repetir el `check`; **nunca un `on` a ciegas**: `on` exige el enlace medido) · y entonces `hub-wallet.sh on --yes` · `$R check …` · `backup-ecoin.sh`. Motor apagado: `$C up -d --no-deps oasis-wallet-bot` · `$R check … --wait` (ídem) | **GO-4a** (`oasisVersion`) · **GO-4b** (encender: `pubAvailability`) |
| 9b | **Snapshot del pub** | no hay paso: lo reconstruye el propio pub desde que arranca (`OASIS_PUB_SNAPSHOT_HOURS`, `HUB-PROTOCOL.md` §13). Comprobar: `pub-snapshot.sh status` a los pocos minutos · `[snapshot]` en el log del pub · `$R check …` (construir no publica) | la **primera** vez que una instancia lo ofrece: GO (servicio nuevo desde el pub) |
| 10 | **Cierre** | `$R snapshot post` · `deploy-status.sh` · `capacity.sh` · `deploy-log.sh` (abajo) · ficha de instancia | |

**Desde 1.3.8, tras el `check` de cada nodo (pasos 7-9)**: `feed-guard-status.js` contra ese nodo (`docker exec` por SSH, stdin):
`lastRepair: null`. El guardián de feeds de upstream (`feed_guard.js`, §0.2) compara el feed del nodo con la copia de
cada par al conectar y, si difieren, **borra y republica solo**; la sonda es la prueba de que no lo hizo. Un `lastRepair`
con contenido es parada dura (RECOVERY §4).

Orden fijo: **pub → HUB → bots**. La imagen es compartida y un retag no recrea contenedores:
mientras no se recrea, cada nodo sigue en la versión vieja. `ecoind` no depende de la imagen de
Oasis y **no se recrea**.

**Paso 6, humo de la imagen.** El `Dockerfile` y el entrypoint del host pueden no ser los del repo
(§0.3): la imagen que se acaba de construir **allí** se prueba allí, antes de recrear a nadie, con
`$R smoke <imagen>:latest` (`--max 120`). Corre en el host en contenedores efímeros que no tocan
nada (`--network none`, sin volúmenes: identidad y `.ssb` desechables dentro, borrados al acabar) y
comprueba lo mismo que U2: versión nueva, `node --check` de `backend.js`, `clearnet_view.js` y
`SSB_server.js`, `find / -xdev -name secret` = 0, sin `.env*`, `volumes-*`, `src.old`, `devops/` ni
`client/` en `/app` (lo que el `.dockerignore` del host debe excluir, abajo), modo `server` hasta que
existe el socket del sbot, modo `backend` hasta `GET /c` = 200, ≥3 parches («patcheado»/«ya
parcheado») y 0 líneas de error en el log. Salida esperada: `SMOKE OK`; cualquier otra es
`SMOKE: DESVIACIÓN` y no se recrea a nadie.

**Paso 6, ensayo de migración (solo si cambia el motor, §0.5).** Con la imagen nueva ya construida
y antes de recrear a nadie, se migra una **copia** del log de cada nodo en un contenedor efímero:
sin red, sin el `secret` del nodo (la identidad del ensayo es desechable y nace dentro) y que se
borra al acabar. Lo que no se copia no sale del host.

```bash
IMG=<imagen>:latest; T=<datos>/migracion-ensayo
for nodo in <ssb-data del pub> <ssb-data del HUB> <ssb-data del bot>; do
  d="$T/$(basename "$(dirname "$nodo")")"; mkdir -p "$d/flume"; cp "$nodo/flume/log.offset" "$d/flume/"; chown -R <uid de oasis> "$d"
  antes=$(docker run --rm --network none -v "$d:/s:ro" --entrypoint node $IMG - /s/flume/log.offset < client/scripts/lib/inspect-log-offset.js)   # records, feeds (FULL_SCAN=1)
  cid=$(docker run -d --network none -e OASIS_SKIP_AI_MODEL=true -e HOME=/home/oasis -e SSB_PATH=/home/oasis/.ssb -v "$d:/home/oasis/.ssb" $IMG server)
  # esperar a la guarda: head -c 20 "$d/flume/log.offset" → «OASIS: this log was»; anotar los segundos
  docker exec -i -u oasis -e HOME=/home/oasis $cid sh -lc 'cd /app/src/server && node -' < pub/tools/log-bipf.js   # T (total), A (autores), D (borrados)
  docker rm -f $cid; du -sh "$d"
done; rm -rf "$T"
```

Salida esperada por nodo: `T` = registros de antes **+1** (el `oasisVersion` de la identidad del
ensayo), `A` = autores de antes +1, `D` = 0. Se anotan la duración (dice cuánto estará el nodo sin
sbot en el paso 7; si pasa del `start_period` del healthcheck, se sube antes) y el tamaño de `db2/`
(el pico de disco es log viejo + log nuevo + índices).

**Paso 4, subir `src/`.** El host no es un checkout git. Desde la rama, solo ficheros trackeados:

```bash
# en la máquina operadora (en Windows `git archive` aplica autocrlf y eol nativo: de ahí los -c)
git -c core.autocrlf=false -c core.eol=lf archive <rama> src | ssh <host> 'cd <repo-del-host> && rm -rf src.new && mkdir src.new && tar -x -C src.new'
# en el host: comprobar ANTES de cambiar nada
grep -m1 '"version"' src.new/src/server/package.json          # = X.Y.Z
grep -c $'\r' src.new/src/backend/backend.js                  # = 0  (sin CRLF)
test -L src.new/src/server/node_modules && test -d src.new/src/base/node_modules/ssb-db2   # (desde 1.2) el enlace es un enlace y lo vendorizado llegó
grep -c $'\r' src.new/src/base/node_modules/is-map/index.js    # = 0  (un paquete con .gitattributes propio)
grep -m1 '"url"' src.new/src/configs/invite-codes.json        # el dominio del pub en la entrada 0 (5.º guard; hasta 1.2.8, snh-invite-code.json)
grep -c 'guard o-sdk (WP-O132' src.new/src/views/clearnet_view.js src.new/src/backend/backend.js   # 4 y 2 (6.º guard)
grep -c 'guard o-sdk (WP-O135' src.new/src/backend/backend.js   # 0 desde 1.3.8 (el 7.º guard se retiró, D-O40)
grep -c 'wantClearnetBlob(blobId); return sendPendingContent(ctx);' src.new/src/backend/backend.js   # 1 (lo de upstream que lo sustituye)
# los demás guards (/update, settings_view, blobs.max, mergeDeep): los literales de upgrade-invariants.d/pub.tsv, con grep sobre src.new/
ls src.new/src/configs/*.json                                 # ningún JSON de estado
# y cambiar. El destino del `mv` NO debe existir: `mv src src.old` con un src.old presente mete src DENTRO.
test ! -e src.old-<ver-vieja> && mv src src.old-<ver-vieja> && mv src.new/src src && rmdir src.new
```

**Antes del build, el `.dockerignore` del host.** El contexto de build es la raíz del repo del host y
`COPY . .` se lo lleva todo a la imagen. Debe excluir los rollbacks de `src` **con comodín**
(`src.old*`, `src.new*`: un `src.old` a secas no cubre `src.old-X.Y.Z`) y los env de producción de
la carpeta del compose (`<carpeta>/.env.*`: el patrón `.env.*` solo casa en la raíz). Comprobarlo
en la imagen construida, dentro del humo del paso 6: `ls -a` de la carpeta del compose no muestra
ningún `.env.prod*` (lo comprueba `smoke`).

**Journal.** El `deploy.sh` del repo apunta el deploy al terminar; el del host es una copia vieja
que no se usa. Tras un deploy a mano, desde la máquina operadora:

```bash
bash devops/scripts/deploy-log.sh --target pub --host <dominio> --version X.Y.Z --caps-shs <shs> --cycle <n> --feed <feed> --mode <server|server+hub|server+hub+wallet-engine-on>
```

**Preservar siempre** (bind mounts): el `.ssb` de cada nodo (`secret` = identidad, `flume`, `blobs`,
`conn.json`, `oasis/**`) y `ai-models`. **Landing**: no se toca; lee versión y ciclo en vivo.

**Cliente** (`docker-compose.yml`, modo `full`): **antes de nada, mira si está cerrado** (`volumes-dev/ssb-data/IDENTIDAD-MUDADA`,
`../CLIENT-PROTOCOL.md` §7.1: la identidad se mudó; subirlo publicaría con ella y bifurcaría el feed; en la demo lo está desde
2026-10-18, D-O39). Si no, después del host y con otro GO si la identidad es
real. `docker tag o-sdk-oasis-client o-sdk-oasis-client:<ver-vieja>` → `npm run build && docker
compose up -d oasis-client`. Detalle, importación de identidad y sbot puro: `../CLIENT-PROTOCOL.md` §4.
También se apunta en el journal (`deploy-log.sh --target client --host localhost --version X.Y.Z
--feed <feed> --mode full`): el preflight solo mira los registros del pub, así que el del cliente
no lo confunde, y sin él nadie sabe en qué versión quedó.

## 5. Ciclo de red — dos casos

> **Modelo mental.** El *ciclo de red* no lo calcula ningún código local (`blockchain-cycle.json`
> no lo lee nadie). Es una generación de red del proyecto identificada por el **`caps.shs`**. El
> directorio `https://oasis-project.pub/api/pubs` mapea `caps.shs → ciclo`. Un pub aparece «verde»
> solo si el directorio consigue **handshake** con él en el cap actual, y para eso debe
> **descubrirlo** por gossip de su anuncio `type:pub`: hace falta que **alguien de la red le siga
> de vuelta**. Estar en rojo por `shs:null` suele ser descubribilidad, no cap ni deploy.

- **Mantener** (bump de versión normal): no tocar `caps.shs` ni seeds. Feeds, invites e identidad
  intactos.
- **Rotar** (solo si el proyecto rota a un cap nuevo): editar en lockstep `caps.shs` +
  `autofollow.feeds` en `pub/config/ssb/config(.local)`, `src/configs/server-config.json`,
  `docs/PUB/*.example` + `docs/PUB/deploy.md`, `devops/hosts/<instancia>/host.env` (`EXPECTED_SHS`,
  `SNH_FEED`), `pub/site/index.html` y los `ssb-config` de cada nodo de soporte
  (`pub/config/hub/ssb-config`, `pub/config/wallet-bot/ssb-config*`: rotan juntos, el follow entre
  ellos sobrevive); luego `pub-federation.sh announce` + `follow-solarnethub` + re-emitir invites.
  Cambiar `caps.shs` = red SSB distinta (los del cap viejo dejan de hacer handshake).

## 6. Healthcheck y rollback

- **Todos los nodos**: `upgrade-gates.sh --remote check pre --wait` → versión nueva, healthy,
  mismo feed, delta declarado (`expect.conf`, §3.4), sin errores en el log.
- **Pub**: `deploy-status.sh` → `caps.shs` OK; `pub:invite` funciona (canario del override
  `OASIS_SERVER_CONFIG_OVERRIDE`); `/public/status` da la versión nueva.
- **HUB**: `upgrade-gates.sh --remote hub --strict`; matriz pública de `HUB-PROTOCOL.md` §4;
  `hub-disk.sh check` → 0; sin `EROFS` en su log.
- **Bot de cartera**: misma dirección, `ismine: true`, **un** mensaje `wallet`; `hub-wallet.sh
  status`.
- **Nodos de soporte, enlace con el pub**: `pub_link=connected` en el `check` (`in` u `out`);
  `hub-wallet.sh status` línea `pares:`; `deploy-status.sh` líneas `LINK`; `[pub-link]` en el log
  del nodo **solo en cambios de estado** (un log que lo repite cada minuto es un enlace que rota:
  `HUB-PROTOCOL.md` §2). Si queda `ausente`: `upgrade-gates.sh --remote link <alias> --yes` (GO).
- **Cliente**: `docker ps` healthy; `/settings` muestra la versión nueva; `npm run client:test-ai`;
  `whoami` = mismo feed id. Matriz completa: `../CLIENT-PROTOCOL.md` §5.
- **Descubribilidad** (aparte): para pasar a verde en el directorio hace falta follow-back de un
  pub raíz.

**Rollback.** Todo lo que sigue vale para un ciclo que **no** cambia el motor. Si lo cambia
(§0.5), solo hay rollback **antes** de que el nodo arranque en la versión nueva; después se
corrige hacia delante, y la copia en frío del paso 7 solo sirve por `RECOVERY-PROTOCOL.md` §4.

- **Pub** (< 2 min; publica otro `oasisVersion`: **GO**): `docker tag <imagen>:<ver-vieja> <imagen>:latest` + `$C up -d
  --no-deps --no-build oasis-pub`; `src/` desde `src.old-<ver-vieja>` o el tgz. `.ssb` intacto.
- **Nodos de soporte** (publica otro `oasisVersion`: **GO**): mismo retag + `up -d --no-deps
  --no-build` del nodo. El estado que la versión nueva haya mudado (`state` en §3.1) no vuelve
  solo: se repone desde el tgz de `ssb-data/oasis/` del paso 1.
- **Lo que viajó fuera de `src/`**: restaurar el `*.bak-<etiqueta>-<fecha>` in place y recrear o
  recargar su servicio.
- **Cliente**: retag de la imagen anterior + `up -d --no-build` (`../CLIENT-PROTOCOL.md` §6). El
  `git switch` solo sirve para reconstruir, no para volver atrás.
- El rollback de este ciclo se retira cuando el siguiente lo sustituye (§4, paso 2), no antes.

## 7. Cierre y registro del ciclo

Un upgrade se cierra con (`plan/PRACTICAS.md`): reporte en `plan/REPORTES/`, `CHANGELOG.md`,
estado en `plan/BACKLOG.md`, journal de deploy y ficha de instancia. El **reporte** es el registro
del ciclo y lleva, además de lo habitual, **seis cabeceras fijas** (como `## n. <cabecera>`; el
`--check` del diff de comportamiento las exige):

1. **Estado de partida**: salida de `deploy-status.sh` y de `snapshot pre`.
2. **Disposiciones**: una por ID del diff de comportamiento (§3.1); `--check` en verde.
3. **Qué viaja al host** (§3.2).
4. **Gates** U0-U7, UM, UR, US: comando y salida (los que no aplican, en una línea: «UM/UR: el
   ciclo no cambia el motor»).
5. **Delta de publicación** medido en local y en el host, por nodo.
6. **Correcciones al protocolo**: cada tropiezo es un defecto de este documento y se arregla aquí.
   Si no hubo ninguno, la sección lo dice («ninguna»): una sección que falta no se distingue de
   un ciclo que no miró.

Un ciclo partido en dos reportes (local y host) lleva las seis en cada uno; lo que no aplica
(el delta del host en el reporte local) se dice en una línea.

Ciclos registrados, del más reciente al más antiguo. Esta tabla es la **única** historia del
protocolo: lo que un ciclo enseñó se escribe aquí, una vez, y el cuerpo del documento queda en
presente.

| Ciclo | Reporte | Lo que enseñó |
|---|---|---|
| 1.3.2 → 1.3.8 | `plan/REPORTES/WP-O147-upgrade-oasis-1.3.8.md` (local y host: mismo delta; las 1.3.3-1.3.7 quedan dentro; 31 min de host) | **Upstream absorbió el séptimo guard** (`/c/blob` pide el blob ausente a la red en segundo plano y responde «pendiente» con `no-store`): se retira (D-O40) y la frase canónica pasa a 6 guards en 6 ficheros, invariante de 7. El parcheador se muda a `src/patches/` (Dockerfile, audit y diff lo siguen por las dos rutas). **Tres plugins nuevos del sbot que carga también el pub**: `feed_guard` (repara feeds bifurcados **solo**: borra y republica; sin interruptor; medido con `feedGuard.status()`), `blob_prefetch` (el pub pide los blobs de a quien sigue) y `long_content` (trocea al publicar). El cupo de salientes de `ssb-conn` deja de ser 4: `connections` de la config (10 por defecto) y el ranking pone primero a quien nos sigue (`link.tsv` al día). Salas en clearnet (opt-in del autor) y PDF rasterizado en el HUB (`mupdf`): dos `location` nuevas en nginx. `INBOX_BOTS += social` (regen). Un `routes -` puede ser un array de paths. Overlay 8 min, diff 80 s, U0+U3+U4+U5 ≈ 12 min |
| 1.3.0 → 1.3.2 | `plan/REPORTES/WP-O146-upgrade-oasis-1.3.2.md` (local y host: mismo delta; la 1.3.1 queda dentro; 46 min de host) | Primer ciclo en que upstream toca `ssb_config.js` (guard de `mergeDeep`/override/`blobs.max`) desde que existe el 3-way: limpio. `bindHost` nuevo: con `pub: false` y `lanBroadcasting` activo multiserver elige la interfaz (`::`); los nodos con `host` fijado en su `ssb-config` no lo notan, el cliente sí (medido en el drill: puerto abierto). **La centralita del pub retransmite vídeo** desde 1.3.2 (`relayVideo`, misma política `relay` que el audio, `roomMax`, apagable con `phone.video: false`): retransmitir no publica, pero es ancho de banda (CAPACIDAD §4) y pide DECISIÓN. Con el motor encendido, la foto base de U0 se repite hasta que cuadre (el bot anuncia `pubAvailability` al arrancar). Un `deps +` en `src/base` sobre `ssb-invite-client` disparó U6: `accept: true`, pub `contact+1`. Overlay 7 min, diff 2 min, camino feliz local 7 min |
| 1.2.8 → 1.3.0 | `plan/REPORTES/WP-O141-upgrade-oasis-1.3.0.md` (local y host: mismo delta; la 1.2.9 queda dentro) | Primer ciclo con el protocolo v3 (WP-O140): `up` ×3 en 23 s y `check --wait` verde en 70 s en local; en el host `--min-age 300` impuso los 5 min y el `smoke` remoto cazó solo falsos positivos del propio gate (`docs/` y `.env*.example`: corregido). **Un fichero de guard puede desaparecer**: upstream borró `snh-invite-code.json` y lee la entrada 0 de `invite-codes.json`; el quinto guard se repone donde se lea ahora (§2). **Tipo nuevo `pub-invites`** (backend con `pub: true`, a los 60 s y cada 24 h, solo si ha creado invites): no se declaró y no salió. La deriva del `.dockerignore` del host no es convergible con otro layout (§4 paso 1). La precondición de `hub-wallet.sh on` destapó que el bot llevaba un día sin conectar con el pub (WP-O143): la foto mide lo publicado, no la conectividad. Dos tropiezos del operador (compose in place sin parar ante un sha distinto; journal con modo falso tras un `on` abortado): un comando por paso también para el operador → WP-O143 (enlace medido y garantizado) |
| 1.2.5 → 1.2.8 | `plan/REPORTES/WP-O138-upgrade-oasis-1.2.8.md` (local y host: mismo delta) | Una llamada que **cambia de sitio** no es una línea del diff: upstream movió la publicación del `karmaScore` de una página de GUI al refresco de fondo y U3 lo destapó en el HUB (`karmaScore=+0..1` desde 1.2.6; aceptado por el custodio, H4). El humo de U2 cazó la identidad real del bot retro dentro de la imagen local (el primer build se llevó `volumes-real/`, que `.dockerignore` no excluía): el humo comprueba 0 `secret`. Índice nuevo de db2 (`oasisActivity`) que no es migración. El reequilibrio de RBU entre pubs pierde su tope por época (leído; decisión antes de la dote). En Windows el overlay y el diff tardan más de 5 minutos cada uno. Al cierre, el bot retro queda deprecated (D-O36) |
| 1.2.3 → 1.2.5 | `plan/REPORTES/WP-O135-upgrade-oasis-1.2.5.md` (local y host: mismo delta; la 1.2.4 queda dentro del salto) | **Séptimo guard** (D-O31): desde 1.2.4 `/c/blob` sirve solo los blobs que el HUB ya tiene; el guard vuelve a pedir a la red los de la lista blanca. Desde 1.2.4 `config-manager.js` lee `oasis-config.json` en `~/.ssb/oasis/`: el bind del compose pasa al directorio de estado y el compose entra en la tabla de derivados (§3.2); por eso U0 se levanta con el compose **desplegado**: con el compose nuevo y la imagen vieja, el HUB habría arrancado con la config por defecto de la imagen (sin `inboxMutedBots`) y la línea base no habría sido «como el host». Upstream publicó tres commits «Oasis release 1.2.5» el mismo día: vale el último (§1). La base del `check` debe llevar los **mismos nodos** que la medida: no se retira un nodo entre foto y foto. Dos piezas nuevas en el inventario (config del nodo, token de admin). El bot retro no se subió en el host: se mudó a la máquina operadora como nodo real (D-O33) y Campamento se deshizo (115 tombstones con `seed-tombstone.js`; `TEMPLATE-PROTOCOL.md` §9, `HUB-PROTOCOL.md` §11) |
| 1.2.3 (mismo ciclo) | `plan/REPORTES/WP-O132-visor-idioma-tema.md` | Sexto guard, el primero en una vista: idioma y tema del visor `/c` por petición (scope), selector de tema por `?theme=`. Se midió un cruce de idiomas real en el host (6 de 18 páginas) que el gate antiguo (2 idiomas) no veía; el gate pasa a 6 idiomas. Recrear solo el HUB en la misma versión no publica nada |
| 1.2.2 → 1.2.3 | `plan/REPORTES/WP-O127` (mejoras previas) · `WP-O128-upgrade-oasis-1.2.3.md` (local) | Lo que se afirmaba de memoria se mide: `NEW_REF` por commit «release», audit de parches en seco (la copia del fork del parcheador era la de 1.2.1 y nadie lo había notado), instancia de `host.env`, seis cabeceras. Una disposición leída («el bot publica un `about` al subir») salió falsa en U3: `syncClearnetSince` falla a los 3 s y lo reintenta en cada arranque (`about=+0..1` también en la misma versión). Primer U6 completo en local con nodo desechable. El diff colapsa activos (10 922 teselas no son 10 922 disposiciones) |
| 1.2.1 → 1.2.2 | `plan/REPORTES/WP-O124-upgrade-oasis-1.2.2.md` (local, host y cliente) | Una disposición «acción de GUI» leída del código era falsa: el gate U5 destapó que HUB y bots publican un `about` de visibilidad (`visibilityPrefs.phone = "off"`) con el primer refresco de fondo tras atender peticiones, **una sola vez al subir a 1.2.2** (`about=+0..1` en el `check` inmediato, `+1` en el de cierre). El sbot trae un plugin que hace de centralita: se acota por config, sin guard (`HUB-PROTOCOL.md` §14, `phone.tsv`). En el cliente, de ≤ 1.1.x a ≥ 1.2 hay cambio de motor. Su reporte se cerró sin tres de las seis cabeceras: desde el ciclo siguiente el `--check` las exige |
| 1.1.10 → 1.2.1 | `plan/REPORTES/WP-O119-medida-db2.md`, `WP-O120-upgrade-oasis-1.2.1.md` (local), `WP-O121-capacidad.md`, `WP-O122-snapshots-pub.md`, `WP-O123-aplicacion-vps-1.2.1.md` (host: mismo delta que en local) · D-O27 | cambio de motor (flume → db2): migración de un solo sentido, sin rollback tras migrar; la medida daba 0 en silencio sobre el log nuevo; dependencias vendorizadas en `src/base` y un build que no instala nada; snapshots que nuestro pub sirve pero no construía; caché de blobs sin techo en un backend público |
| 1.1.4 → 1.1.10 | `plan/REPORTES/WP-O112-protocolo-upgrade.md` (reescritura de este protocolo), `WP-O113-upgrade-oasis-1.1.10.md` (local), `WP-O114-aplicacion-vps-1.1.10.md` (host: mismo delta que en local) | El protocolo anterior comprobaba lo barato (que los guards siguen puestos) y no lo caro: no medía comportamiento ni publicación; se reescribió. Todo nodo anuncia su versión (`oasisVersion`), también al volver atrás. Idioma por visitante en `/c` (D-O25). Avisos automáticos que se envían cifrados a uno mismo (`inboxMutedBots`). `GET /wallet` republica la dirección en un bot con el motor encendido. El primer `GET /banking` publica la dirección. El modelo de IA cambia bajo el mismo nombre. En el host, el `.env.prod` de la carpeta del compose entraba en la imagen hasta la aplicación de este ciclo (2026-10-01): el patrón `.env.*` del `.dockerignore` solo casa en la raíz (§4) |
| 1.1.2 → 1.1.4 | `plan/REPORTES/WP-O105-upgrade-oasis-1.1.4.md`, `WP-O106-aplicacion-vps-1.1.4.md` · `ECOIN-PROTOCOL.md` §5.4 | `state-manager.js` y la mudanza de estado; quinto guard; `git archive` y CRLF |
| 1.0.8 → 1.1.2 | `plan/REPORTES/WP-O97-upgrade-oasis-1.1.2.md` · `HUB-PROTOCOL.md` §5.5 | primer ciclo con el HUB activo: `/c/assets`, rutas de detalle nuevas |
| 0.8.3 → 0.8.8 → 0.9.6 → 1.0.8 | sin reporte de ciclo (anteriores a este protocolo; `CHANGELOG.md`) | Del 0.9.6 → 1.0.8 salió la receta v0 del HUB (proxy al backend del pub), retirada después (D-O13): historia en `HUB-PROTOCOL.md` §0 |

## 8. HUB clearnet — ver `HUB-PROTOCOL.md`

Desde 1.0.x el pub puede servir un **HUB web de solo lectura** en `/c` con el contenido público de
los habitantes que hayan activado *Clearnet* en su perfil (`clearnet.md`). **En Docker no basta con
Caddy**: nuestro modo `server` arranca solo `SSB_server.js`, mientras que `oasis.sh server` de
upstream arranca sbot + `backend.js --public`. Cómo lo resolvemos, cómo se activa, cómo se mantiene
en disco, qué cambia en cada upgrade y la historia de la receta anterior (v0, retirada por D-O13)
está en **`HUB-PROTOCOL.md`** (§0, §2, §5).
