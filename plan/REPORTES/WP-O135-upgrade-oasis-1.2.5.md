# WP-O135 · Upgrade a Oasis 1.2.5 en local (preparación; el host no se ha tocado)

Rama `upgrade/oasis-1.2.5` (desde `main` 5f4462b6) · 2026-10-10 · `OLD_REF=043f4634` (1.2.3) ·
`NEW_REF=560580d7` (1.2.5: upstream publicó **tres** commits «Oasis release 1.2.5» el 2026-10-09; el
preflight toma el último). La 1.2.4 (30e54200, 2026-10-08) queda dentro del salto: decisión del
custodio, directo a 1.2.5, un `oasisVersion` por nodo. Sin cambio de motor (`annex` db2 íntegro).

**Alcance de este reporte.** UPGRADE §2 y §3.1-§3.3 hechos. §3.4 (gates locales) **pendiente**:
Docker Desktop estaba parado en la máquina operadora y el custodio pidió que al VPS no se tocara
nada, ni en lectura. Las secciones 4-6 dicen qué falta y con qué delta declarado. Nada de lo que
sigue autoriza el §4: el host pide `deploy-status.sh` primero y GO por nodo.

## 1. Estado de partida

Host: **no medido en esta sesión** (decisión del custodio). Versión de partida tomada del registro
del ciclo anterior (WP-O128, 2026-10-07): pub, HUB y bot de cartera en 1.2.3; bot retro en modo
`server`; cliente local en 1.2.2 (el custodio decidió no subirlo). Antes del §4: `deploy-status.sh`
y, si no cuadra, corregir este párrafo.

Preflight (`upgrade-preflight.sh --from 1.2.3`, tras `git fetch oasis-upstream`):

```
LOCAL=1.2.3  UPSTREAM=1.2.5
DESPLEGADA=1.2.3  (journal, target=pub, o --from)   OBJETIVO=1.2.5
OLD_REF=043f4634
NEW_REF=560580d7
Código que cambia por rol: pub en modo server = 16 de los 25 ficheros que carga · backends y cliente = 126 · activos (assets, mapas) = 20 · dependencias vendorizadas (src/base) = 786
    pub: updater.js · i18n.js · config-manager.js · shared-state.js · state-manager.js · banking_model.js · tombstone_validator.js · typed_log.js · SSB_server.js · db2_legacy.js · lanRouter.js · network_pause.js · package.json · phone_module.js · ssb_config.js · ssb_metadata.js
Ciclo actual de red: 6 · caps.shs local coincide · nuestro pub en el directorio: cycle=6 status=online
WARN x2: árbol no limpio (png igual en ambas ramas + .claude/settings.json sin trackear) · upstream por delante
```

Línea base local (U0, `snapshot pre125`): **pendiente** (§5).

## 2. Qué se entregó

| Commit | Pieza |
|---|---|
| `0e2d7e48` | Overlay limpio `git rm -r src && git checkout 560580d7 -- src/`, tal cual upstream. Se conservan `blockchain-cycle.json` (fork-only) y `snh-invite-code.json` (upstream no lo tocó). `scripts/patch-node-modules.js` sigue a upstream. 782 borrados (dependencias que upstream retira de `src/base`: pdfjs, open-rpc…), 150 modificados |
| `b6ad82b3` | Los 6 guards repuestos. Upstream tocó 5 de los 6 ficheros. Cuatro entraron con `git apply --3way` limpio; `backend.js` dio un conflicto (upstream añade un middleware de rutas solo-loopback justo antes de la línea de idioma del guard): se conservan los dos. `ssb_config.js`: `blobs.max` vuelve a 50 MB (upstream 75) y se conservan `readServerConfig()` y el `bindHost` nuevos. `clearnet_view.js`: upstream solo cambió el paginador (`?perPage=`), disjunto del sexto guard |
| `8d01eda2` | Adaptación: el bind `:ro` de `oasis-config.json` del HUB y del bot pasa de `/app/src/configs/` a `/home/oasis/.ssb/oasis/` (§3, H1). Los cinco `ssb-config` pierden el bloque `gossip` (el sbot ya no carga `ssb-gossip`) |
| `12a86f5e` | Protocolos: HUB §2 y §5.2, fila de disco de `/c/blob`; ECOIN §5.2; UPGRADE §0.2 y §2; AGENTES §4 (tres trampas); CLIENT §4 (adaptación pendiente) |

Verificación de invariantes (UPGRADE §2), medida tras `b6ad82b3`:

```
git diff 560580d7 --stat -- src/              → 7 files changed (backend.js 37, updater.js 4, blockchain-cycle.json 4, snh-invite-code.json 2, ssb_config.js 25, clearnet_view.js 66, settings_view.js 4)
git diff 560580d7 --stat -- src/base          → (vacío)
git diff 560580d7 --stat -- scripts/patch-node-modules.js → (vacío)
git ls-files -s src/server/node_modules       → 120000 … (enlace)
node --check  backend.js clearnet_view.js ssb_config.js updater.js settings_view.js → OK los cinco
grep -m1 version src/server/package.json      → "1.2.5"
node devops/scripts/upgrade-patches-audit.js 560580d7 → aplicado=6 silencioso=5 pendiente=0 sin-anclaje=0 ausente=1 (src/AI, normal) · rc=0
node pub/scripts/regen-node-configs.js --check → al día (upstream no tocó src/configs/oasis-config.json)
```

## 3. Disposiciones

`bash devops/scripts/upgrade-behaviour-diff.sh 043f4634 560580d7`: 255 líneas, **184 con signo**; `annex` sin
ningún `!` (db2, ecoin, hub, phone: todo `ok`). Cada ID con signo se dispone abajo; `--check` de este fichero en
verde (§7). Las lecturas que lo sostienen están en los hallazgos H1-H8 al final de la sección.

### roles (16 `+`: lo que carga el pub en modo `server`)

- `7c250c58` `ssb_config.js` → **adaptado** `b6ad82b3` (guard repuesto sobre `readServerConfig()`; `blobs.max` 50; `bindHost` de upstream conservado: nuestros `incoming.net` llevan `host` explícito y no lo tocan).
- `dd4c8958` `SSB_server.js` → sin `ssb-plugins`, `ssb-gossip`, `ssb-friend-pub`, `ssb-partial-replication` (ver *deps*); `tightenStateDir()` hace `chmod 700` del `.ssb` (H6); `handleFatal` ya no mata el proceso si el sbot está vivo; el RPC `config` redacta `keys`. Nada publica → **gate U3** (pub `oasisVersion=+1` y nada más) · **documentado** H6.
- `a7b2b8f1` `network_pause.js` → `syncPeerBook` (H5) → **gate U3**: pares `connected` del pub y del HUB tras recrear; `conn.json` sin duplicados.
- `46f6e16c` `phone_module.js` → +283 líneas de salas (grabación, mano, silencio, chimes, límites `HUB_ROOMS_MAX`/`RING_PER_WINDOW`). La política (`relay`, `relayOpen`, `roomMax`) no cambia (`annex` phone ok ×6). No publica → **no-afecta** al feed; **gate** `annex` ya en verde y `roomInfo` en U3.
- `aba81af3` `package.json` → ver *deps*.
- `e6ef65b3` `db2_legacy.js` → `batch(1000)` en las consultas: rendimiento → **no-afecta**; lo mide `snapshot` (cuadre de las tres fuentes).
- `8e63beb3` `lanRouter.js` → lee `oasis-config.json` del directorio de estado (H1) → **adaptado** `8d01eda2` (nodos con bind); en el pub, default de la imagen → **no-afecta**.
- `f870255c` `ssb_metadata.js` → imprime límite de blobs, caché de medios y uso en disco → **no-afecta**.
- `11e046cb` `config-manager.js` → H1 → **adaptado** `8d01eda2` · **documentado** HUB §5.2, ECOIN §5.2, UPGRADE §0.2, AGENTES §4, CLIENT §4.
- `5c0837d4` `shared-state.js` → retira `liveRooms` (y su `dismiss`), añade `suggestionsQuiet` → memoria del proceso → **no-afecta**.
- `bd892fc9` `state-manager.js` → `migrateAll` borra duplicados de banderas ya migradas y las carpetas vacías `keys/` y `node_modules/` del `.ssb` → **no-afecta** (nada que el fork use; inventario de upstream lo confirma).
- `9f6ad872` `banking_model.js` → ver *publish* y H2.
- `1ae9b77b` `tombstone_validator.js` → valida **todas** las reclamaciones de borrado, no solo la última por objetivo → lectura → **no-afecta**.
- `ad3e9c63` `typed_log.js` → `tombstone` deja de estar acotado por `ssbLogStream.limit` y entra la lectura de privados (`withPrivate`) → más memoria en un HUB con `mem_limit` 1536m/768m → **gate** U3/U4: RSS del HUB tras `hub --strict` frente al ciclo 1.2.3.
- `7bbaee7e` `updater.js` → guard repuesto → **adaptado** `b6ad82b3`.
- `bb76c3ea` `i18n.js` → cadenas → **no-afecta**.

### files (4)

- `a58b2599` `src/backend/wallet_addresses.js` borrado: ningún fichero de `src/` lo requiere (grep = 0) y el fork solo nombra el **json de estado** (`oasis/banking/wallet-addresses.json`, que sigue) → **no-afecta**.
- `3b336a3f` `src/models/tribe_crypto.js` borrado: `backend.js` construye `tribeCrypto` con `models/crypto` → **no-afecta**.
- `15a7fe91`, `f12724af` `src/games/visualdj/*` nuevos: estáticos bajo `/game-assets` (no `/c`) → **no-afecta**.

### routes (16)

Ninguna ruta nueva bajo `/c/`: la plantilla de nginx y el Caddyfile **no cambian**. Todas las nuevas son acciones de
GUI que `publicModeGuard` bloquea en HUB y bot (ambos `OASIS_PUBLIC=true`): `84368171` `/rooms/recordings/:name`,
`afb815bc` `/files/:id/fetch`, `02059a3b` `/phone/silence`, `64ca5e07` `/qr-action/follow`, `899a2597`
`/qr-action/join`, `9e2180ed` `/qr-action/sign` (los tres pasan de GET a confirmación + POST), `422b899a`
`/rooms/hand`, `d314b507` `/rooms/notify`, `6042574c` `/rooms/notify/clear`, `6eb34136` `/rooms/rec/start`,
`37afc904` `/rooms/rec/stop`, `a4203911` `/rooms/recordings/:name/delete`, `a53defc8` `/rooms/silence`,
`9e8f60df` `/shops/open-invite/join` → **no-afecta** a los nodos; cliente: drill (CLIENT §5) cuando se suba.
`c2c6cf4f` `/rooms/live/dismiss` retirada → **no-afecta**. `9d8b3ac1` `GET /admin-session/:token` (H4) →
**documentado** ECOIN §5.2, UPGRADE §0.2, AGENTES §4.

### loopback (8)

`d58daca7`, `7e55bb51`, `14c63469`, `2fe2d998`, `23328bae`, `df4ad135` (salas), `5cb36dfe` `/backup/import`,
`8f2d4ec9` `/backup/keys/import`: pasan a exigir loopback (y `config.public` las cierra) → más estricto, nadie del
fork las llama → **no-afecta**. Lo que sí cambia para todas las solo-loopback es el token de admin (H4) →
**documentado** ECOIN §5.2.

### publish (25)

- Banca `1285ae12`, `e5c8e0c3`, `7bcf5d22`, `1327a42f`, `dc612b1b`, `c1387ac6`: `ubiClaimResult` lleva ahora
  `address`; sigue publicándose **solo al pagar un reclamo** (motor, época abierta). Antes de pagar comprueba
  reserva del pool y dirección no repetida en la época (H2) → **gate U3/U5** (`ubiAllocation` y `ubiClaimResult`
  = 0 con la época ya abierta) · **documentado** H2 (DECISIÓN).
- Calendarios `64252dbe`, `5a1e41d4`, `90ed5210`, `78dd3549`, `3cf9e541` (`tribe-keys`, `calendarParticipant` con
  `keyProof`), eventos `a37a3470`, `dc94f2bb`, `bd3a4d67`, mapas `e4aaf1ce`, `715c5ad8`, chats `f65bf6d6`,
  `f26d7467` (token en vez de código), tiendas `a36d1adb`, `5f7b72fa`: acciones de GUI tras formulario; nada las
  dispara solo → **no-afecta** a HUB y bot; cliente: drill.
- Parlamento `d5ef463c`, `ef96404e`, `ca5f53ad` (×6), `827c09e9`, `99ea6357`: upstream **retira** publicaciones
  (`approve`, `rej`, seis `updated`) y recompone el estado leyendo (`chainIndex`, `supportFor`); `tomb` cambia de
  sitio. Menos publicaciones posibles → **no-afecta**; **gate U3** (HUB y bot a 0, como en 1.2.3).

### timers (8)

- `21f84166` / `faf71e31`: `larpModel.init()` solo con `larpMod=on` → **no-afecta** (menos trabajo).
- `439277cc` `visualdj/index.html` → estático → **no-afecta**.
- `708dbba4` `phone_model.js`: recuento al llegar mensajes (`onMsgAdded`, 500 ms) → lectura → **no-afecta**; cubierto por U3.
- `6771769c`, `5e18e140` `network_pause.js`: `syncPeerBook` a los 5 s, 30 s y cada 10 min **en todo sbot** (pub, HUB, bots, retro) (H5) → **gate U3**.
- `0824d194`, `94bd221e` `phone_module.js`: reproducción de audio a ritmo de trama → local → **no-afecta**.

### headers (17)

- `3ed19d3f`, `67e3cc9b`, `c8ab5a8a`: `isLoopbackRequest` rechaza cabeceras de proxy y exige la cookie de admin (H4) → **documentado** ECOIN §5.2, UPGRADE §0.2, AGENTES §4.
- `c63ef031`, `92388a52`, `77fde478`, `3fa7de11`, `fd4c00d2`: `Range`/`Content-Range`, `Cache-Control: private, no-store` y `Content-Disposition` en buzón de voz y grabaciones (GUI, no `/c`) → **no-afecta**.
- `fddac0ce`, `64e9f253`, `e6b00b70`: `Content-Security-Policy: sandbox` y descarga forzada para medios del fediverso (no `/c`) → **no-afecta**.
- `1bed45ec`: `updater.js` deja de mandar `Accept-Language` → **no-afecta**.
- `96487820`: `/assets` con `Cache-Control: public, max-age=3600` (o `immutable` con `?v=`): la location `/c/assets` de nginx lleva `proxy_ignore_headers Cache-Control` → **no-afecta**; **gate U4** (MISS→HIT).
- `979aeba5`, `a922ed72`, `9af71c96`, `8bad6b48`: CSP, `nosniff`, `X-Frame-Options`, `Referrer-Policy` en `/game-assets` (no `/c`; Caddy fija los suyos) → **no-afecta**.

### env (5)

- `bcbe2297` `process.env.ssb_path` (minúsculas): el compose define `SSB_PATH`; en Linux no casa y cae a `~/.ssb`, el mismo sitio → **no-afecta** · **documentado** UPGRADE §0.2 (fila nueva).
- `4e310684` `OASIS_BANKING_DIR` 9→11 usos: no definida (annex ecoin ok) → **no-afecta**.
- `5cd637bb` `OASIS_DEBUG`, `5e09db84` `OASIS_NETWORK_PAUSED`, `66eecc85` `OASIS_STATE_DIR`: ningún compose las define → **no-afecta**.

### config (7)

`7f8b93f4`, `dd7730d5`, `535a9625`, `f7d2724e`, `421fffb4`, `2da9f511`, `bd3329c1`: upstream retira el bloque
`gossip` de `server-config.json` (y el plugin). En nuestros cinco `ssb-config` era inerte → **adaptado**
`8d01eda2`; viajan al host (§4). `connections.*` no cambia: nada que decidir.

### deps (24)

- `e1402052` / `7c7d36e1` versión; `52d97ca0` / `1f60fe1f` `nodemon` fijado; `107c44a1`, `dce025a5`, `2ac93a91` `devDependencies` fuera → **no-afecta**.
- Retiradas `93555fa1` `@open-rpc/client-js`, `7206aa91` `is-svg`, `de9168d8` `node-fetch`, `fed6e993` `pdfjs-dist`, `fcf158e0` `util`: nada del fork las usa (grep en `pub/`, `devops/`, `client/`, entrypoint = 0) → **no-afecta**.
- Retiradas `1b21edc9` `ssb-gossip`, `964788be` `ssb-friend-pub`, `e8c44323` `ssb-partial-replication`, `2fe0ea65` `ssb-plugins`: salen del sbot (`SSB_server.js`). `friendPub.*` no lo llamaba nadie del fork; `ssb-plugins` cargaba plugins de usuario que no tenemos. Cambia `ssb-*` → **gate U6** (invite completo con nodo desechable) obligatorio y **gate U3** (pares).
- Añadidas `b6c5b7e8` `bencode`, `ac9f3f93` `bipf`, `42697c61` `chloride`, `65777037` `pull-level`, `6e4d9b8d` `ssb-classic`, `b63026ea` `ssb-sort`, `f5696b1f` `stream-to-pull-stream`: explicitan lo que ya iba vendorizado (`log-bipf.js` y `ssb-probe.js` del fork usan `bipf` de `src/base`) → **no-afecta**; `annex` db2 ok.
- `4d3cf372` `src/base` 786 ficheros en 31 paquetes → invariante `git diff 560580d7 -- src/base` vacío ✓ · audit de parches `pendiente=0` ✓.

### outside (45)

- `65c44fee` `install.sh`, `67d375cc` `oasis.sh`: bare metal, no se sincronizan (UPGRADE §2) → **no-afecta**. Leído `oasis.sh`: pone `aiMod/aiNavMod=off` en cada arranque del pub; nuestro `server` no lo necesita (sin backend).
- `afc2198e` `scripts/patch-node-modules.js` → **adaptado** `0e2d7e48` (copia del fork = upstream; audit en §2).
- Tests de upstream (el fork no corre su suite): `4f1ccd7c`, `253e341f`, `597d595e`, `c32b0057`, `eb3341f1`, `eb0d23c5`, `0a9d6023`, `7bca7c6a`, `0d4fbf70`, `fd450682`, `bdadcc72`, `4d96b978`, `51a13174`, `fb1f99ef`, `c8ad869e`, `6323a904`, `b909f816`, `73638de7`, `a5c00aa4`, `d87de6d3`, `8d8c3641`, `4a0683a8`, `919e4b55`, `401e522b`, `6f807533`, `706b8d2f`, `3d63a9b9`, `aedb6787`, `dc5afb84`, `a34a372c`, `1101ea11`, `9c90040a`, `ef96b084`, `27b19e3d`, `148eda3d`, `45c6cbec`, `a8ecdb99`, `2e7ce600`, `01cc7d7c`, `473da552`, `b00767c0`, `d6e17003` → **no-afecta**.
- `f70bd0ae` (`=`) docs de upstream, leídas: `deploy.md` confirma H1 (`~/.ssb/oasis/oasis-server-config.json` y `oasis-config.json`), `security.md` explica H4 («una petición que llega por un intermediario nunca es local»; secreto de admin por arranque), `clearnet.md` el modelo de confianza de pubs (H2).

### patches (1)

`b7ade88a`: upstream cambió su parcheador → **adaptado** `0e2d7e48`; `upgrade-patches-audit.js 560580d7` =
`aplicado=6 silencioso=5 pendiente=0 sin-anclaje=0 ausente=1` (los parches nuevos de `ssb-db2/utils`, `ssb-conn-hub`,
`ssb-lan`, `ssb-box` ya van en lo vendorizado). Los tres del entrypoint (`ssb-ref`, `ssb-blobs`, `multiserver`) se
confirman en el log de arranque (U2/U3).

### Hallazgos (lo que no se ve en el listado)

**H1 · La config del nodo se muda al directorio de estado.** `config-manager.js` lee `~/.ssb/oasis/oasis-config.json`
(y `oasis-server-config.json`, fusionado sobre `server-config.json`); la de `src/configs/` solo la **copia una vez**
si aquella falta. También `lanRouter.js` y `network_pause.js`. Nuestros binds `:ro` a `/app/src/configs/` habrían
servido el primer arranque y después habrían quedado muertos: la regeneración de HUB §5.2 / ECOIN §5.2 no surtiría
efecto. **Adaptado** (`8d01eda2`): bind al sitio nuevo. Consecuencias: (a) con el bind presente no hay copia; (b) un
`saveConfig` del backend falla contra el `:ro` como hasta ahora, pero su temporal (`oasis-config.json.tmp-*`) caería
en `~/.ssb/oasis/` → gate U3 lo busca; (c) Docker crea el punto de montaje si falta: `~/.ssb/oasis/` existe en los
tres nodos desde 1.1.3. **Pub** (`server`): carga `config-manager` por `ssb_config.js`, así que su `.ssb` gana un
`oasis/oasis-config.json` copiado del default de la imagen (`lanBroadcasting: true`, `phone.relay: true`): inerte,
porque `pub: true` ya fija `bindHost` y la política de `phone` la lee de su `ssb-config` (`annex` phone ok). **Cliente**:
`persist_client_state` enlaza `src/configs/oasis-config.json` al estado en `/app/state`; en 1.2.4+ ese enlace se
leería una vez y después mandaría la copia del volumen de `.ssb`: `wire_wallet_config` dejaría de mandar. Adaptación
del entrypoint **pendiente** antes de subir el cliente (CLIENT §4). `oasis-server-config.json` no se crea en
nuestros nodos (solo si el default trae `pub: true` o `hops ≠ 2`); el override del guard sigue mandando.

**H2 · Confianza de pubs en Banking (DECISIÓN del custodio).** `banking_model.js` introduce `trustedPubIds()`: para un
habitante, un pub es de confianza si es el **pub por defecto** (el del invite de `snh-invite-code.json`, que el guard
D-O22 no toca: es el de SNH) o si el habitante **publicó un `pub` con su clave al redimir un invite y lo sigue**.
`listUbiPubs`, `discoverUbiPub`, el historial y `pubAvailability` filtran por esa lista; un `ubiClaimResult` solo cuenta
si lo firma un pub de confianza **o** el pub al que iba dirigido el `ubiClaim`. Nuestro banco es el bot de cartera
(D-O19, identidad propia, sin invites): un habitante que no haya redimido un invite **del bot** dejará de verlo en
Banking → UBI y `discoverUbiPub` lo ignorará, aunque siga su feed. Quien ya reclamó (claim dirigido al bot) conserva su
historial. Opciones, para decidir antes del §4 o declarar que se acepta: (a) aceptarlo y documentar que la RBU de la
casa solo llega a quien redime un invite del bot (`pub: true` carga `ssb-invite`: el bot **puede** emitir invites,
pero cada redención le publica un `contact`); (b) revisar D-O19 (motor en la identidad del pub); (c) nada hoy, medir en
el host con un cliente real. Este reporte no decide. **Documentado** aquí; ECOIN §9 pide una nota cuando se decida.
Otros cambios del motor, sin decisión: `available` del anuncio sale de `computePoolVars().available ≥ floor` (antes
saldo bruto) → un `pubAvailability=+0..1` al arrancar ya estaba declarado; `claimEpoch` solo mes actual o anterior;
una dirección no cobra dos veces por época; `confirmIncomingTransfers` exige `gettransaction.details` con `receive`.

**H3 · `/c/blob` deja de pedir blobs a la red (DECISIÓN del custodio).** `GET /c/blob/:id` usa `blob.getLocal` (antes
`getResolved`, que hacía `blobs.want` hasta 30 s) y exige `clearnetBlobAllowed` (el blob aparece en un objeto clearnet
o en un avatar). Un blob que el HUB **no tiene** da 404 y nada lo pedirá: las imágenes de objetos publicados después
del upgrade no saldrán en `/c` hasta que alguien las replique al HUB. Las de la exposición Campamento ya están en el
HUB (se pidieron en 1.2.3) y seguirán, salvo poda de `blobCache` (2048 MB, lejos). Opciones: (a) aceptar el modelo de
upstream; (b) **séptimo guard de una línea** (`getResolved` tras `clearnetBlobAllowed`: la lista blanca ya acota lo que
el visor puede pedir); (c) tarea externa que pida los blobs del índice clearnet por el socket del HUB. El gate U4 debe
medir las dos caras (200 para un blob que el HUB tiene; 404 para uno que no) antes de decidir. **Documentado** HUB
fila de disco, AGENTES §4.

**H4 · Token de admin por arranque.** Con `config.allowHost` (`OASIS_ALLOW_HOST`: HUB = dominio, bot = `localhost`)
`backend.js` genera `ADMIN_TOKEN` y `isLoopbackRequest` exige la cookie `oasis_admin`, que da `GET /admin-session/<token>`
desde el socket local con `Host` local y **sin** cabeceras de proxy. El token se imprime en el log de arranque («Admin
access»): secreto de sesión, **no se copia a reportes** (ley 4). Afecta al bootstrap de un bot nuevo (`POST
/banking/addresses`, ECOIN §3) y a cualquier `/settings/*`; no a lo automático (`ensureSelfAddressPublished`, motor)
ni a los gates (`worst` solo hace GET a rutas que no son solo-loopback; `hub` entra por nginx). El puente de loopback
del cliente es TCP puro (sin cabeceras) y el cliente no define `allowHost` → sin token. **Documentado**.

**H5 · `syncPeerBook`.** El sbot (todos los nodos) rehace su libreta: normaliza claves de 43 caracteres en `conn.json`
(las nuestras ya van con `=`, `hub-conn-fix.js`), olvida lo de `gossip_unfollowed.json`, **recuerda con `autoconnect`
cada pub de `gossip.json` y de `connections.seeds`** y, si `config.pub`, pone `autoconnect: true` a todo par `type: pub`.
El pub tiene `gossip.json` (inventario del backup); HUB y bots, lo que dejara el invite. Sustituye a `ssb-gossip`
(`global`, `seed`). No publica. → gate U3: pares del pub y del HUB, sin entradas duplicadas.

**H6 · `chmod 700` del `.ssb`.** `tightenStateDir()` en cada arranque del sbot. En el host `/srv/oasis/<nodo>/ssb-data`
pasa a 700 del uid del contenedor. `lib-node.sh` ya entra con `sudo -n`; `deploy-status.sh` no lee `ssb-data`. Antes
del §4: confirmar que `backup-oasis-pub.sh` y `backup-ecoin.sh` no leen esa carpeta como usuario sin `sudo`.

**H7 · `phone.visibility` por defecto pasa a `mutuals`.** `desiredPhoneVisibility()` devuelve `off` en público: HUB y bot
no cambian. Un cliente (no público, `phoneMod` on) publicará un `about` nuevo al subir: `about=+1` en su delta
(CLIENT §4).

**H8 · `blobs.max`.** Upstream sube a 75 MB (sbot y subida de la GUI). El guard mantiene 50 (HUB fila de disco,
CAPACIDAD). Cambiarlo es del custodio; no cambia nada publicable.

## 4. Qué viaja al host

Lista cerrada de este ciclo (lo que no está aquí **no se sube**):

| Qué | Cómo | Después |
|---|---|---|
| `src/` (overlay + guards, `b6ad82b3`) | `git -c core.autocrlf=false -c core.eol=lf archive` → tgz → `src.old-1.2.3` (comprobar `test ! -e` antes del `mv`) | `build` + contenedor efímero (§4 paso 6) |
| `pub/docker-compose.pub.yml` (bind nuevo de `oasis-config.json` en HUB y bot) | sustituir in place tras `sha256` del vivo contra el del repo en `5f4462b6` | ya se recrean HUB y bot en el ciclo |
| `pub/config/hub/ssb-config`, `pub/config/wallet-bot/ssb-config`, `pub/config/wallet-bot/ssb-config.engine-on`, `pub/config/retro-bot/ssb-config`, `pub/config/ssb/config` (sin `gossip`) | `cat >` in place (binds de fichero) | se leen al recrear cada nodo |
| Antes de recrear HUB y bot | `test -d /srv/oasis/<nodo>/ssb-data/oasis && test ! -e …/oasis/oasis-config.json` | si existiera, apartarlo con sufijo |

**No viaja**: `nginx.conf.template` (sin rutas nuevas bajo `/c`; `Cache-Control` de assets ya ignorado), `Caddyfile`,
`pub/config/hub/oasis-config.json` y la plantilla del bot (al día), `docker-entrypoint.sh`, `Dockerfile`,
`pub/panel-api`. `deploy-status.sh` marcará deriva en compose y configs hasta que se suban.

## 5. Gates

**Pendientes.** Docker Desktop estaba parado en la máquina operadora al preparar este ciclo; no se ha ejecutado ningún
gate. Plan, con lo que este ciclo añade (todo `bash devops/scripts/upgrade-gates.sh --local`):

| Gate | Este ciclo |
|---|---|
| U0 | `backup pre125` · stack en 1.2.3 (imagen actual) · `snapshot pre125`: tres nodos healthy, `seq = registros = sbot` |
| U1 | invariantes de §2 ✓ (hecho) · `annex` ✓ · `--check` ✓ (§7) |
| U2 | `docker tag …:latest …:1.2.3-vieja` · build · `node --check` dentro de la imagen · log de arranque: tres parches «ya parcheado», ninguno «no se encontró» |
| U3 | `up pub` · `up hub` · `up bot` · `check pre125 --expect 'pub:oasisVersion=+1 hub:oasisVersion=+1 bot:oasisVersion=+1,pubAvailability=+0..1,about=+0..1'` (retro, si `GATE_NODES` lo incluye: `oasisVersion=+1`). **Añadidos**: `docker exec … cat ~/.ssb/oasis/oasis-config.json` = la del repo (H1); `ls ~/.ssb/oasis/` sin `*.tmp-*`; `stat -c %a ~/.ssb` = 700 (H6); pares `connected` del pub y del HUB y `conn.json` sin duplicados (H5); el log del HUB y del bot trae «Admin access» (no copiar); RSS del HUB frente a 1.2.3 |
| U4 | `hub --strict` (MISS→HIT, 0/18 cruces, `?theme=`, `?perPage=` nuevo del paginador) · **añadido** H3: `GET /c/blob/<id>` de un PNG del kit que el HUB tiene → 200; de uno que no tiene → 404 y sigue 404 a los 30 s (antes 200) |
| U5 | `snapshot u5` · `worst` · `check u5 --expect 'bot:karmaScore=+0..1'`: `wallet` y `(cifrado)` a 0; `GET /banking` 200 (no 403: no es solo-loopback) |
| U6 | **obligatorio** (cambian `ssb-*`): invite completo con nodo desechable (`invite.create` + `ssb-probe.js invite-accept`), `check u6 --expect 'pub:contact=+1 hub:=0 bot:about=+0..1'` |
| U7 | `restore pre125 --yes` · re-render de la config del bot · repetir U3: mismo delta |
| US | `pub-snapshot.sh --local build` · construir no publica |

## 6. Delta de publicación

**No medido** (gates pendientes). Declarado: `pub:oasisVersion=+1` · `hub:oasisVersion=+1` ·
`bot:oasisVersion=+1,pubAvailability=+0..1,about=+0..1` · retro (`server`): `oasisVersion=+1`. Cualquier otra cosa es
desviación: parada dura. Host: no aplica en este reporte.

## 7. Correcciones al protocolo

- UPGRADE §3.2: `pub/docker-compose.pub.yml` entra en la tabla de derivados («cuando upstream cambia **dónde lee** un
  fichero montado»): este ciclo lo cambió y la tabla no lo contemplaba.
- UPGRADE §1: con varios commits «Oasis release X.Y.Z» (1.2.5 tuvo tres el mismo día), vale el último; el preflight ya
  lo hacía, el texto no lo decía.
- UPGRADE §0.2: dos piezas nuevas en el inventario (config del nodo; token de admin).
- AGENTES §4: tres trampas (config regenerada que no surte efecto; 403 con `Host`/`Referer` correctos; 404 en `/c/blob`).
- ECOIN §5.2, HUB §5.2 y fila de disco, CLIENT §4: lo de H1, H3, H4.
- `--check`: `bash devops/scripts/upgrade-behaviour-diff.sh 043f4634 560580d7 --check plan/REPORTES/WP-O135-upgrade-oasis-1.2.5.md`
  → «todas las líneas tienen disposición … y el registro lleva las seis cabeceras» (salida pegada al cerrar la sesión).

## 8. No medido / pendiente

1. Gates U0-U7, US (§5): arrancar Docker Desktop y ejecutarlos; corregir aquí lo que midan.
2. `deploy-status.sh` del host antes del §4 (ley 1); confirmar H6 contra los scripts de backup.
3. **DECISIONES**: H2 (confianza de pubs: ¿invites del bot, D-O19, o aceptar?), H3 (`/c/blob`: ¿séptimo guard?), H8
   (`blobs.max` 50/75), cliente (H1/H7: adaptar entrypoint y drill antes de subirlo; hoy sigue en 1.2.2).
4. §4 host: GO por nodo. Un `oasisVersion` por nodo; rollback = `src.old-1.2.3` + imagen `:1.2.3-vieja`, y también
   publica (UPGRADE §0.4).
