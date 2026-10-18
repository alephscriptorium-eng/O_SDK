# WP-O146 · Upgrade a Oasis 1.3.2 (1.3.0 → 1.3.2; la 1.3.1 queda dentro del salto)

Rama `upgrade/oasis-1.3.2` desde `main` 0d5d5e98 (merge de WP-O145). 2026-10-18. Segundo ciclo con el protocolo v3
(`docs/PUB/UPGRADE-PROTOCOL.md`). Encargo del custodio: «a ver si está claro el protocolo de upgrade y hacemos a latest».
Alcance: pub, HUB y bot de cartera de la instancia Scriptorium **y el cliente real** (1.3.0 desde WP-O145). Fuera: el bot
retro (deprecated, D-O36), `ecoind`, la maint-ui (prohibida durante el ciclo) y `caps.shs` (ciclo 6: «mantener»).

## 1. Estado de partida

**Host** (`deploy-status.sh`, 2026-10-18 ≈ 09:10Z, solo lectura):

- Journal: último registro `target=pub`, `oasisVersion=1.3.0`, `gitSha=7b7cd500`, 2026-10-15T17:28:20Z,
  `mode=server+hub+wallet-engine-on`.
- Piezas vivas: `oasis-pub-scriptorium` (server), `oasis-pub-hub` (backend), `oasis-pub-wallet-bot` (backend): los tres
  **1.3.0**, `running healthy`, «imagen al día». `src/` en disco del host: 1.3.0. Engine 26.1.5. Enlace de los nodos de
  soporte con el pub: HUB y bot `connected out`, 4 pares cada uno.
- Deriva: `Dockerfile`, compose, Caddyfile, plantilla nginx, configs de HUB y bot y `tools/*.js` **iguales que HEAD**.
  `docker-entrypoint.sh` **DISTINTO**: el vivo es el blob de `dfc86d28` (sha256 `bf5756a4…`, WP-O144); HEAD es el de
  `4f9d9ff6` (`9bd76f89…`, WP-O145: `persist_client_state` en todos los modos). `.dockerignore` DISTINTO y fuera de la
  historia (layout `OASIS_PUB/`: no convergible hasta E0, WP-O141 §6; cumple §4: `src.old*`, `src.new*`,
  `OASIS_PUB/.env.*` con sus `.example` re-incluidos, `*.bak-*`, `ARCHIVO`).
- Restos de rollback del ciclo anterior: `/opt/oasis-scriptorium/src.old-1.2.8`, `/srv/oasis/src-1.2.8.tgz` (94 MB),
  imagen `:1.2.8`. Además en `/srv/oasis` siguen los `*.bak-o128/o135/o138/o141` de HUB y bot y `oasis-pub.cold-o123`
  (≈ 4,5 GB): no son de este ciclo; pendiente de siempre «backups fuera de la máquina».
- Directorio: ciclo 6, `pub.escrivivir.co` **VERDE**. Disco `/` 42 %, `/srv/oasis` 41 %; `hub-disk`, `ecoin-disk`
  (`wallet.dat` 600) y `capacity` OK, 0 avisos.

**Preflight** (`upgrade-preflight.sh`, tras `git fetch oasis-upstream`: trae 1.3.1 `149c0457` y 1.3.2 `a44bce44`):

```
LOCAL=1.3.0  UPSTREAM=1.3.2  DESPLEGADA=1.3.0  OBJETIVO=1.3.2
OLD_REF=37e0fc93  (Oasis release 1.3.0)      NEW_REF=a44bce44  (Oasis release 1.3.2 = punta de oasis-upstream/main)
pub en modo server: 10 de los 26 ficheros que carga · backends y cliente: 70 · activos: 20 · src/base: 1
  pub: opinion_categories.js, config-manager.js, state-manager.js, banking_model.js, karma_model.js, peer_health.js,
       viewer_filters.js, server/package.json, phone_module.js, ssb_config.js
caps.shs local = cap actual de la red (ciclo 6): MANTENER (§5)
WARN x1 (el esperado: upstream por delante)  rc=1
```

`SSB_server.js` no cambia → **sin cambio de motor**: UM y UR no aplican. `ssb_config.js` cambia (2 líneas: `bindHost`) y lleva
guard: se repone a mano (§2 del protocolo; aquí, 3-way limpio).

**Local**: Docker Desktop 29.4.1; `oasis-pub-scriptorium:latest` = `f37e7e9d` (1.3.0, build de WP-O143/O144), los tres nodos
del stack local parados 2 días en esa imagen; bot con el motor encendido (`ssb-config.engine-on`), como el host.
Foto base `pre132` (09:34:16Z): pub seq 16 · HUB 15 · bot 32, los tres «cuadra · sbot=», v1.3.0, `enlace-pub=connected`.
(La primera foto, a los 18 s del arranque, salió NO MEDIBLE: el bot con el motor encendido publicó su `pubAvailability` de
arranque entre la lectura del log y la del sbot; repetida a los 64 s, cuadra: §6.)

## 2. Qué se entregó (rama)

| Commit | Pieza |
|---|---|
| `98829171` | Overlay limpio `git rm -r src && git checkout a44bce44 -- src/`, tal cual upstream. Se conservan `blockchain-cycle.json` y los guards de `updater.js`, `invite-codes.json` y `clearnet_view.js` (upstream no los tocó: `git diff --shortstat 37e0fc93 a44bce44` vacío en los tres). `scripts/patch-node-modules.js` sincronizado (upstream añade el parche de `ssb-invite-client`) |
| `3fb0fce0` | Guards repuestos en los tres ficheros que upstream sí cambió (`backend.js` +578/−184, `ssb_config.js` +2/−2, `settings_view.js` +298/−195): `git apply --3way` del diff de guards de 1.3.0, **limpio en los tres** |
| (este) | reporte, backlog, CHANGELOG, §7 del protocolo |

Verificación de invariantes (UPGRADE §2), tras `3fb0fce0`: `git diff a44bce44 --stat -- src/` = **7 ficheros** (113+/33−);
`-- src/base` vacío; `-- scripts/patch-node-modules.js` vacío; `src/server/node_modules` modo `120000`; `node --check` ok en
`backend.js`, `ssb_config.js`, `settings_view.js`, `clearnet_view.js`, `updater.js`; versión `1.3.2`;
`upgrade-patches-audit.js a44bce44` → `aplicado=10 silencioso=7 pendiente=0 sin-anclaje=0 ausente=1` (el ausente es `src/AI`,
normal; el parche nuevo de `ssb-invite-client` ya viene aplicado en lo vendorizado). `regen-node-configs.js`: «al día»
(los JSON de `src/configs/` no cambian; las claves nuevas `mentionsVisibility` y `phone.video` las fija `readConfig` en memoria).

## 3. Disposiciones

`upgrade-behaviour-diff.sh 37e0fc93 a44bce44` sobre el árbol con los guards repuestos (≈ 2 min en Windows): 192 líneas, 74 IDs
distintos piden disposición, `annex` **0 rotos** (90 `=`), `patches` 18 `=`. Agrupadas por causa:

**Guards y árbol (§2).** `roles +` 8bd8630f, 11e046cb, bd892fc9, 9f6ad872, c4ec6c5e, db75a40c, 83e4f40f, aba81af3, 46f6e16c,
7c250c58 (los diez ficheros que carga el pub en modo `server`) → **gate** U2 (`SMOKE OK` en modo `server`) y U3 (el pub publica
`oasisVersion` y nada más). De ellos, 7c250c58 `ssb_config.js` (`bindHost`: con `pub: true` sigue `0.0.0.0`; con `pub: false` y
`lanBroadcasting` activo pasa de `0.0.0.0` a `null`, y multiserver elige) → **no-afecta** a pub, HUB y bot: el pub tiene `pub: true`
y HUB y bot fijan `host: "0.0.0.0"` en su `ssb-config` (el código solo rellena `host` si falta); en el **cliente** (`pub: false`,
`lanBroadcasting: true`, sin `host`) sí cambia → **gate** U6 drill del cliente: el sbot escucha en `::` (medido en `/proc/net/tcp6`,
puerto 8008 alcanzable). `deps -/+` 4d462f72, e756f270 (versión 1.3.0 → 1.3.2) → **gate** U3 (`oasisVersion=+1` por nodo).
`patches +` b7ade88a y `outside +` afc2198e (upstream amplía su parcheador con `ssb-invite-client`) → **adaptado** 98829171 (copia
sincronizada) y medido (`pendiente=0`). `deps +` 7bc000c2 (`src/base`: 1 fichero, `ssb-invite-client/lib/index.js`: un pub que ya
nos sigue no es un invite fallido; es el lado que **acepta** invites) → **gate** U6 invite completo con nodo desechable: `accept: true`,
pub `contact+1`, HUB y bot 0.

**Karma.** `files +` d78265a6 (`karma_model.js`, nuevo) y `publish -/+` 6b64756c, 590fa4d8, 5e431359 → 18a77051, cc75cab4, 27e22ddf
(`publishKarmaScore` se muda de `banking_model.js` a `karma_model.js`, que `banking_model` requiere; el refresco de fondo sigue en
`backend.js`, sin cambios en su temporizador) → **no-afecta** al cuándo (24 h y valor cambiado, ≥ 1.2.6) y **gate** U3/U5: el
algoritmo nuevo (`karmaReceived`, decaimiento) puede cambiar el valor y adelantar un `karmaScore` en el primer refresco: dentro del
`+0..1` declarado en `expect.conf`. En local no salió en ninguno de los tres nodos.

**Publicaciones de la GUI.** `publish -/+` e44acfc7 → af27584e (`publishExposure` con `publicCopyOf`: exponer contenido de tribu,
POST de la GUI) y `publish +` 1a0e389c (`files_model.js`: `fileOpinion` y ficheros sellados, acciones de la GUI) → **no-afecta** a
los nodos de soporte: nadie usa su GUI (su único tráfico es el healthcheck) y el pub no carga el backend. `publish +` ecb0c20d,
410dc827, 67e4f6e5, 6bef8806 y `timers +` cc2b2508, 91428d19, 9417d04f, ebd90a94, 0e1c0d86 (`phone_module.js`: `publishFrame` **no
es `ssb.publish`**: empuja fotogramas JPEG a los observadores de una llamada o sala; los temporizadores viven mientras hay vídeo) →
**no-afecta** al feed (0 `ssb.publish` en el fichero) y **documentado** abajo (centralita). `timers +` ee155bf3 (`nextcloud_model`:
`abort` de una petición HTTP de la GUI) → **no-afecta**.

**Centralita del pub (Phone y Rooms).** 46f6e16c `phone_module.js` (+335): el plugin del sbot añade los RPC `video`/`relayVideo`
(permiso `anonymous`) y `camera`; el pub en modo `server` **retransmite vídeo** entre participantes como ya hacía con el audio.
Medido en el código: `relayVideo` pasa por el mismo `relayAllowed` que el audio (política `relay`/`relayOpen`), las salas respetan
`roomMax` y anuncian `video: policy().video !== false`; la clave `phone.video` del `ssb-config` del pub puede apagarlo. Hoy el pub
lleva `relay: true, roomMax: 12` y **no fija `video`** → vídeo permitido por defecto (≈ 200 KB/s por participante,
`ROOM_VIDEO_BYTES_PER_S`; fotograma ≤ 10 KB en sala). **DECISIÓN del custodio antes del host**: dejarlo así o acotarlo
(`"video": false` en `pub/config/ssb/config`, HUB §14, CAPACIDAD §4). Retransmitir no publica (U3, U5 y US a 0). `sharp` viene
vendorizado en `src/base` (`sharpLib` se carga con `try`). En HUB y bot `phone.relay = false` (regen) y no tienen cámara:
`cfg.phone.video` solo afecta a quien llama.

**Superficie HTTP.** `routes +` d6952836, 474a1b17, 270ee467, 163f0395, 1e8a1e50, 97d57a6e, e15b3857, dd1f861c, bf6a7fbf,
3f10ef5e, 79c693b0, e682c78c, 7e6b9324, 3f21afca (`GET /blob/sealed/:manifestId`, `GET /phone/video/:peer`, doce `POST` de
Nextcloud, ocultar/silenciar, pares, cámara, visibilidad de menciones) → **no-afecta**: ninguna bajo `/c/` (`git diff` de rutas
`/c` vacío); el edge solo enruta `/c/*` al HUB (HUB §2). `loopback +` 90a4bf54, 60830604, f775452b, 03b99f89, 324fe7d3
(`GET /peers` con filtros avanzados, vídeo, cámara, Nextcloud pasan a solo-loopback) → **no-afecta** por lo mismo y porque
el HUB corre `--public`.

**Cabeceras y cookies (D-O25).** `headers +` 2155533d (`Cache-Control: no-store` en `/qr-*`, `/welcome`, `/backup*`,
`/wallet/qr`, `/ai`, `/phone/video`), 1c822ff2 (`X-Content-Type-Options` en `/phone/video` y `/blob/sealed`), d6f2b1cd
(`multipart/x-mixed-replace` del vídeo), 90aa57d3 (`private, max-age=3600` en `/blob/sealed` y `/fediverse/*`), d63652f1
(`Content-Disposition` de `/blob/sealed`) → **no-afecta** a `/c` (ninguna de esas rutas está bajo `/c/`: medido buscando la ruta
que envuelve cada línea) y **gate** U4: `hub --strict` en verde (0 cruces en 18 peticiones de 6 idiomas, variante `?theme=` en
caché).

**Estado.** `state +` 95d2e11d (`nextcloud-account.json` → `multiverse`), 1b95a531 (`viewer_hidden.json` → `content`) →
**documentado** aquí: dos ficheros de estado nuevos que un rollback de imagen no deshace (UPGRADE §6); en los nodos de soporte
nacen vacíos (nadie usa Nextcloud ni oculta objetos desde su GUI). `files +` e8c3774c (`nextcloud_model.js`, nuevo) → **no-afecta**:
solo lo dispara la GUI (`POST /settings/nextcloud`, `/files/nextcloud`).

**Fuera de `src/`.** `outside +` 17f66563, 8286c364 (tests nuevos), b53d5335, bdadcc72, 3f6324c0, a5c00aa4, 2d02a331, 7b4f2b8b,
dc5afb84, a34a372c, 9c90040a, 5e0882a3, f5f24bee (tests de upstream modificados) → **no-afecta**: camino bare-metal y tests de
upstream; el overlay no los trae (UPGRADE §2).

`upgrade-behaviour-diff.sh 37e0fc93 a44bce44 --check <este fichero> --from-tsv` → «todas las líneas tienen disposición» (§5, U1).

## 4. Qué viaja al host

- `src/` entero (1.3.2 + 7 guards), por `git archive` LF desde `upgrade/oasis-1.3.2` (§4 paso 4).
- `docker-entrypoint.sh`: el vivo es el blob de `dfc86d28`; el repo lleva el de `4f9d9ff6` (WP-O145: `persist_client_state`
  corre en todos los modos **si `OASIS_CLIENT_STATE_DIR` está definida**; en pub, HUB y bot no lo está → inerte para ellos). Viaja
  para converger la deriva (§3.2: «el entrypoint de la raíz in place, sha del vivo = blob del repo antes de pisar, y rebuild»).
  Precondición medida: sha256 del vivo `bf5756a4…` = `git show dfc86d28:docker-entrypoint.sh`.
- `.dockerignore` del host: **no se converge** (otro layout, E0); cumple §4; `smoke` lo mide.
- Nada más: compose igual que HEAD; ninguna ruta nueva bajo `/c/` (plantilla nginx y Caddy sin cambio); configs de HUB y bot sin
  cambio (`regen-node-configs` al día); `pub/tools/*.js` iguales que HEAD.
- **Opcional, DECISIÓN**: `pub/config/ssb/config` del pub con `"video": false` en `phone` si el custodio acota el vídeo (arriba).
  Si viaja, es un bind in place y el pub lo lee al recrearse (paso 7).

## 5. Gates U0-U7, UM, UR, US

Stack local sobre `volumes-dev/` (identidades desechables), `$G = upgrade-gates.sh --local`, 2026-10-18 09:33-09:49 UTC.
UM y UR no aplican (el ciclo no cambia el motor, §1).

| Gate | Comando | Salida |
|---|---|---|
| **U0** | nodos parados · `$G backup pre132` · `$CL up -d` · `$G snapshot pre132` | copia 3,1 MB; `healthy` los tres a los 10 s; primera foto NO MEDIBLE (bot `sbot=32 ≠ log=31`: `pubAvailability` de arranque, motor encendido y > 12 h); repetida a los 64 s: pub 16 · hub 15 · bot 32, «cuadra · sbot=», v1.3.0, `enlace-pub=connected` en HUB y bot |
| **U1** | `git diff a44bce44 --stat -- src/` · `-- src/base` · `-- scripts/patch-node-modules.js` · `git ls-files -s src/server/node_modules` · `node --check` ×5 · `upgrade-patches-audit.js a44bce44` · `--check --from-tsv` | **7 ficheros** (113+/33−) · vacío · vacío · `120000` · ok · `pendiente=0 sin-anclaje=0` · «todas las líneas tienen disposición» (74 IDs). `annex`: 0 rotos |
| **U2** | `docker tag :latest :1.3.0-vieja` · `compose build oasis-pub` · `$G smoke oasis-pub-scriptorium:latest` | imagen `420ceeb70182` (1,55 GB) · `SMOKE OK`: 1.3.2, `node --check` ×3, enlace a `src/base`, **0 `secret`**, nada del fork en `/app`, `server` socket a los 2 s, `backend` `GET /c` 200 a los 2 s y `start_pub_link` anunciado, 3 parches ×2, 0 errores ×2 |
| **U3** | `$G up pub` · `$G up hub` · `$G up bot` · `$G check pre132 --wait` | `healthy` a los 4 s cada uno (26 s en total) · **`GATE OK` (82 s)**: pub `oasisVersion+1` · hub `oasisVersion+1` · bot `oasisVersion+1`, **nada más** (ni `karmaScore`, ni `about`, ni `pubAvailability`, ni `pub-invites`); `enlace-pub connected(out)` en HUB y bot |
| **U4** | `hub-cache` y `pub-web` arriba · `$G hub --strict` | **`GATE OK`**, 16 ok: MISS→HIT, una CSP, idioma «es» igual con de/es/fr y cookies, `?lang=`, **0 cruces en 18 peticiones de 6 idiomas**, `?lang=ar`, selector de tema, `?theme=` Clear/Matrix/desconocido, enlaces con `lang` (23) y `theme` (32), variante `?theme=` en caché, 0 cruces de tema en 9, `/c?type=files` 200, sitemap 10 URLs https, RSS feed/files https |
| **U5** | `$G snapshot u5` · `$G worst` · `$G check u5 --wait --expect 'bot:karmaScore=+0..1'` | 5 GET → 200 · **`GATE OK`** (79 s): los tres Δ0; `wallet` y `(cifrado)` quietos, misma dirección `EYMWF4…` |
| **U6** invite | `$G snapshot u6` · `invite.create({uses:1, external:'gate.example.org'})` por `ssb-client` en el pub (120 caracteres, no impreso) · host → `172.20.0.2` · desechable `docker run --network oasis-pub-scriptorium_oasis_pub_net -e OASIS_SNAPSHOT=off … :latest backend` (socket a los 5 s) · `ssb-probe.js` `SSB_ACTION=invite-accept` · `$G check u6 --wait --expect 'pub:contact=+1 hub:=0 bot:about=+0..1'` · `docker rm -f` | `accept: true`; el pub (`@eDyDjJ…`) como par `connected` del desechable; **`GATE OK`** (77 s): **pub `contact+1`**, HUB y bot 0. Desechable retirado |
| **U6** cliente | drill `o-sdk-drill` (identidad desechable `@Br/nQy…`, `OASIS_AI=none`): `docker tag …:pre-o146` · `$D build` (caché del build del pub: 4 s) · `$D up -d` · tipos dentro del contenedor cada 20 s hasta estable 60 s · `GET /` · `ecoin-verify` · `stat` de la viva · `$D stop` | `healthy` a los 5 s; log: 3 parches, «config viva: default de la imagen + lo vivo (gana lo vivo) (sin cambios)», `wallet.url`, `[Version: 1.3.2]`; sbot en `[::]:8008` (tcp6) y GUI en `0.0.0.0:3001`; feed: `oasisVersion` [5,12,15,16,**17**], `about` [1,13], `karmaScore` [2,14], `wallet` 0, `pub-invites` 0 → **`oasisVersion+1`, nada más**; `GET /` 302; **16 PASS · 0 FAIL · 0 SKIP**; viva `600 regular 1998`, `src/configs` regular; 0 errores en el log |
| **U7** | `$CL stop` ×3 · `$G restore pre132 --yes` · `render-wallet-bot-config.sh pub/.env.local` · `$G up` ×3 · `$G check pre132 --wait` | `healthy` a los 4 s ×3 · **`GATE OK`** (107 s): **mismo delta que la primera vez** (`oasisVersion+1` ×3, nada más) |
| **US** | `$G snapshot us` · `pub-snapshot.sh --local build` · `$G check us --expect 0` · `status` | `{"ok":true,"messages":224,"feeds":6,"boxed":5,"bytes":69035,"ms":78}` · **`GATE OK`**: los tres Δ0 (construir no publica) · snapshot de hace 0 h, reconstrucción cada 6 h |

Tiempo del camino feliz local (U0+U3+U5+U7, sin build ni diff): ≈ 7 min. Overlay: 7 min 15 s (Windows); diff de comportamiento:
≈ 2 min (la vez anterior, 6 min 36 s).

## 6. Delta de publicación

**Local** (U3 y U7, idénticos): pub `oasisVersion+1` · HUB `oasisVersion+1` · bot `oasisVersion+1`. Nada de lo declarado como
`+0..1` salió (`karmaScore`: los tres lo habían publicado hace < 24 h o sin cambio de valor; `about`: el bot ya llevaba su
`clearnetSince`; `pubAvailability`: el bot lo publicó en U0, al arrancar la línea base, 12 h después del anterior: queda en la
base, no en el delta). U6: pub `contact+1` (el invite, solo porque se usó). Cliente (drill): `oasisVersion+1`, nada más.

**Host**: pendiente (§9). Delta declarado para el host: `expect.conf` (pub `oasisVersion=+1`; HUB `oasisVersion=+1,karmaScore=+0..1`;
bot `oasisVersion=+1,karmaScore=+0..1,about=+0..1,pubAvailability=+0..1`); el bot lleva el motor encendido desde el 15 a las 14:56Z.
**Cliente real** (CLIENT §4.3): `oasisVersion=+1`, `about=+0..1`, `karmaScore=+0..1`, `wallet=0`, `pub-invites=0`.

## 7. Correcciones al protocolo

- **U0 con el motor encendido: la foto base se toma cuando el bot se ha asentado.** Al arrancar la línea base, el bot (motor
  encendido, > 12 h desde su último anuncio) publica un `pubAvailability` en los primeros segundos; la foto a los 18 s salió NO
  MEDIBLE (`sbot ≠ log`) y la de los 64 s cuadró. El gate hizo lo correcto; la fila U0 de §3.4 debe decir «repetir la foto hasta
  que `seq` = `registros` = `sbot`» en vez de «arrancar · snapshot». Aplicado en este WP.
- **Un `deps +` en `src/base` sobre un paquete `ssb-*` dispara U6.** Esta vez era `ssb-invite-client` (el lado que acepta
  invites). La tabla ya lo dice para «si cambian `ssb-*`»; se añade que lo vendorizado cuenta (en §3.4, U6). Aplicado.
- **`bindHost` de `ssb_config.js`**: a partir de 1.3.2 un nodo con `pub: false` y `lanBroadcasting` activo deja a multiserver
  elegir la interfaz (`::`). Nuestros HUB y bot fijan `host` en su `ssb-config` y no les afecta; el cliente sí (medido en el drill:
  el puerto sigue abierto). Nota en CLIENT-PROTOCOL §8 (D-anexo) para que nadie lo tome por desviación. Aplicado.
- Ninguna otra: el 3-way de los guards fue limpio (también en `ssb_config.js`, el primero con guard que upstream toca desde 1.2.4),
  el humo y los gates salieron a la primera.

## 8. Seguimiento

- DECISIÓN del custodio: política de vídeo de la centralita del pub (`phone.video`) antes de GO-2.
- Cliente real: tras el host, CLIENT §4.2 (retag `:1.3.0`, copia en frío con el cliente parado, `npm run build`, `up -d`, medir
  el delta con `count-feed-type.js`, `ecoin:verify`, `pub-feed-seq`).
- Backups viejos en `/srv/oasis` (`*.bak-o128/o135/o138`, `cold-o123`, ≈ 3 GB) fuera de la máquina: no es de este ciclo, sigue
  pendiente desde WP-O128.
