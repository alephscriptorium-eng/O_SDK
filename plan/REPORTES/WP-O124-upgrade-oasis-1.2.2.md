# WP-O124 · Upgrade a Oasis 1.2.2 (Phone y Rooms) · local y host

2026-10-05 · rama `upgrade/oasis-1.2.2` · upstream `942d39c9` (1.2.1) → `b1f7adfc` (1.2.2).
**Estado: desplegado en el host el 2026-10-05 (§7). Pub, HUB y bot en 1.2.2; delta medido igual al
declarado. El pub se llama ahora `pub.escrivivir.co` (§7.1).** Gates locales en verde (§5); hallazgo
del `about` de HUB y bot en §5.1.

## 1. Qué trae 1.2.2

Un plugin muxrpc `phone` (`src/server/phone_module.js`, 1 161 líneas, sin dependencias nuevas) que
`SSB_server.js` carga junto a `snapshot_plugin`: llamadas de voz y salas entre habitantes.

- Audio capturado y reproducido por el sistema del nodo (`parec`/`pacat`, `pw-record`/`pw-play`,
  `arecord`/`aplay`); G.711 µ-law a 8 kHz, tramas de 20 ms, por un `duplex` de muxrpc.
- Cifrado extremo a extremo con claves efímeras por llamada (curve25519 + `secretbox` por trama),
  firmadas con la clave del feed.
- Directo si los nodos se alcanzan; si no, por un pub (`relay`, `relayAudio`), que no puede abrirlo.
- Llamadas conjuntas de hasta 7; salas de hasta 50 alojadas en un pub (`roomHub`).
- Además: pausa de red (`network_pause.js`, `/peers/pause`), avisos de escritorio, Pixelia a PDF.

Como el plugin vive en el sbot, **el pub (solo sbot) hace de centralita al subir**, de fábrica.

## 2. Decisión: centralita en el pub, acotada

Decidido por el custodio el 2026-10-05, frente a apagarla o a un nodo VoIP aparte.

| Nodo | Política | Dónde |
|---|---|---|
| pub | `"phone": { "relay": true, "roomMax": 12 }`, sin `relayOpen`: solo sirve si sigue a uno de los interlocutores | `pub/config/ssb/config` y `config.local` (llega por el guard `OASIS_SERVER_CONFIG_OVERRIDE`, con `mergeDeep`) |
| HUB y bot | `phone.relay = false` | `pub/scripts/regen-node-configs.js` → sus `oasis-config.json` |

Por qué no un nodo aparte (leído del código, no ensayado): los clientes solo usan de relé a un nodo
que tienen como `type: 'pub'` y al que están conectados, así que sería un segundo pub con identidad,
puerto e invites propios; para quitársela al pub principal haría falta un sexto guard en `src/`
(con `relay: false` el pub sigue anunciando `roomHub` y rechaza a quien entra); y en el mismo VPS
no separa el ancho de banda, que es lo que pesa.

## 3. Lo hecho

| Paso | Resultado |
|---|---|
| Preflight | `LOCAL=1.2.1 UPSTREAM=1.2.2`; ciclo 6, cap coincide; pub: cambian 16 de los 24 ficheros que carga; `src/base`: 4 |
| Overlay | `git rm -r src` + checkout de upstream; upstream no borra ficheros, añade 10. Commit `b8869e89` |
| Guards | `ssb_config.js` y `snh-invite-code.json` no cambiaron upstream: se conservan. `backend.js` (dos edits), `updater.js` y `settings_view.js` repuestos a mano; el formulario de `/update` vive ahora en un panel de actualización. Commit `96acac51` |
| Invariantes | `git diff oasis-upstream/main --stat -- src/` → 6 ficheros · `src/base` → vacío · `src/server/node_modules` modo 120000 · `node --check` de los tres ficheros editados · versión 1.2.2 |
| Diff de comportamiento | 202 líneas, 145 piden disposición; `annex`: 49 invariantes (7 nuevos de la centralita), ninguno roto (§4) |
| Derivados | `regen-node-configs.js`: HUB y bot regenerados (`roomsMod`, `phoneMod`, `phone`); `--check`: al día |
| Centralita | config del pub, `phone.relay=false` en soporte, `upgrade-invariants.d/phone.tsv` (7 invariantes, todos presentes), `HUB-PROTOCOL.md` §14, `CAPACIDAD.md` §4, fila en el inventario de `UPGRADE-PROTOCOL.md` §0.2. Commit `2ed09ff4` |

## 4. Disposiciones del diff de comportamiento

`upgrade-behaviour-diff.sh 942d39c9 b1f7adfc`: 202 líneas, 145 piden disposición; `annex`: 49 invariantes, ninguno roto. `--check` contra este reporte: sale 0.
Los gates que citan las disposiciones están corridos (§5).

- **roles · el plugin de la centralita y lo que lo carga** (5). `adaptado` en `2ed09ff4` y `documentado` en `HUB-PROTOCOL.md` §14: el sbot carga `phone_module` y `network_pause`; el pub acota la centralita desde su ssb-config. `gate` de arranque del pub (hecho, §5).
  IDs: `ea7cb03a` `dd4c8958` `a7b2b8f1` `aba81af3` `46f6e16c`
- **roles · resto del código que carga el pub** (11). `gate` U3 (hecho, §5): leídos los diffs de `SSB_server.js`, `lanRouter.js` (guarda de LAN; el pub va con `local: false`), `ssb_metadata.js` (cartel de arranque: añade «VoIP ID», «Mode», «Workflow»), `config-manager.js` (normaliza `phone`, módulos nuevos), `shared-state.js` (estado en memoria), `banking_model.js` (karma de `room`, filtro de direcciones), `typed_log.js`. De `updater.js`, `desktopNotify.js`, `viewer_filters.js`, `workflows_model.js` y `state-manager.js` solo lo que toca a los guards y al estado. Lo decide la medida: el pub publica `oasisVersion` +1 y nada más.
  IDs: `fb29c533` `7bbaee7e` `11e046cb` `5c0837d4` `bd892fc9` `9f6ad872` `ad3e9c63` `83e4f40f` `0dfe1974` `8e63beb3` `f870255c`
- **files · ficheros de Phone y Rooms** (7). `documentado` en `HUB-PROTOCOL.md` §14. Modelos y vistas son de la GUI; en los nodos de soporte nadie la usa.
  IDs: `5502abb6` `435267e7` `bbb8a952` `20d197ee` `8d907d99` `89a70280` `82fbe25b`
- **files · resto** (3). `no-afecta`: `desktopNotify.js` solo actúa si existe `notify-send` y lo arranca un backend no público; `peer_health.js` y `network_pause.js` acompañan a la pausa de red, que ningún compose activa.
  IDs: `aa01c0d2` `d6cabc13` `c39727ef`
- **routes · rutas nuevas** (39). `no-afecta` al clearnet: ninguna cae bajo `/c/` (nginx y Caddy no cambian). Son la GUI de Phone, Rooms, pausa de red, Pixelia y bienvenida; las POST son acciones que alguien pulsa, y en HUB y bots nadie lo hace. `gate` `hub --strict` (hecho, §5).
  IDs: `dc2e46f5` `17e60c85` `edde6593` `cd4abe51` `20a7caf3` `07bb6d12` `359803d6` `48fd1cdf` `540b2c2b` `5e36254b` `f431293b` `be788722` `f5acfde0` `f305465d` `32d5c076` `d6e52237` `f5d5ace2` `e505b340` `16106ba1` `3356031a` `03f38827` `a09d4048` `ed9b2f84` `90b0f583` `6a57ec01` `d9f603b4` `78506945` `aa7fa6db` `b7242be1` `5a25d5a4` `e1a30be7` `5e8e9057` `2495d23a` `f6a82403` `d46e372c` `d89a51fb` `145c6907` `c3316109` `86e3c5ac`
- **routes · rutas retiradas** (4). `no-afecta`: `/settings/conn/*` pasa a ser `/peers/pause` y `/peers/resume`. Ningún script ni documento del fork las usaba (grep: 0).
  IDs: `5b3d0176` `b3fd6af2` `5a67ff51` `4c2a62be`
- **loopback** (1). `no-afecta`: acción de la GUI de bienvenida, reservada al loopback.
  IDs: `7b42af71`
- **publish** (7). `gate` U3–U7: **una de ellas no es de GUI** y la primera lectura lo dio por tal (corregido por el gate, §5.1): el `about` con `visibilityPrefs.phone` lo publica también `syncPhoneVisibility()` desde el refresco de fondo del backend. El resto sí salen de una acción de GUI (enviar un mensaje de voz → privado `pam`; salas → `room`, `roomMember`, `tribe-keys`) o son el mismo `publishJoin`/`publishLeaveLarp` con otro manejo de error. Tipos nuevos posibles en el log: `room`, `roomMember`, `pam` (cifrado).
  IDs: `3aa23744` `a0703915` `4987510f` `1d05f40f` `d6e92691` `fec2443a` `5075acb3`
- **timers · arranque de Phone en el backend** (2). `no-afecta` con el compose actual: `phoneModel.start()` y los avisos de escritorio solo arrancan `if (!config.public)`, y HUB y bot van con `OASIS_PUBLIC=true`. Ojo en un alta: durante el bootstrap del invite (`OASIS_PUBLIC=false`) sí arrancan; sin audio no hacen nada observable. `gate` U4.
  IDs: `8492ef7a` `31761e2f`
- **timers · plugin phone** (10). `no-afecta`: temporizadores de una llamada o sala en curso en el propio nodo (timbre, buzón, entrada a sala). Sin dispositivo de audio el nodo ignora los timbres y no puede llamar ni entrar en salas; el lado de relé no arma ninguno.
  IDs: `f06976e7` `a8d6bc17` `65bed86d` `71564fee` `2f7d2b6a` `ec033c19` `e82be24f` `6b1d03a9` `2322d7d8` `0d83447a`
- **timers · resto** (2). `gate` U4 (hecho, §5): dos temporizadores retirados de `main_models.js`.
  IDs: `66f7fe25` `9c4f07ae`
- **headers** (4). `gate` `hub --strict` (hecho, §5; «una sola cabecera CSP»): la CSP gana un parámetro de marcos para `GET /games/<id>` (fuera de `/c/`); la cookie `theme` y el `referer` nuevos están en `/welcome/workflow`, loopback. El tema del visor sigue saliendo de la config (invariante `themes?.current`: ok).
  IDs: `6d79f1e1` `b9825219` `d1aecef4` `fd9ec9e9`
- **env** (3). `documentado`: `OASIS_NETWORK_PAUSED=1` arranca el nodo sin conexiones; ningún compose debe definirla (hoy: 0). `PATH` lo lee `desktopNotify.js` para buscar `notify-send`. `OASIS_DEBUG` ya existía.
  IDs: `245b8241` `c154d79c` `b75a39cc`
- **state** (4). `gate` U3/U4 (hecho, §5): cuatro ficheros nuevos bajo `~/.ssb/oasis/{peers,phone}`. Nacen con el uso; un rollback de imagen los deja inertes. Si un nodo tuviera ya un `lan-peers.json` o `peer-health.json` fuera de sitio, el arranque lo mudaría (solo hacia delante).
  IDs: `2edffebd` `28685784` `647d52d1` `25eae6c1`
- **config** (15). `adaptado` en `2ed09ff4`: configs del HUB y del bot regeneradas (`regen-node-configs.js --check`: al día) con `phone.relay = false`. `language` no se mueve en los nodos (el script lo conserva). `blobCache` sigue fijado por el script.
  IDs: `29dde2d3` `fd585f0d` `7c52f483` `8017348e` `b1c87985` `2944e32a` `22253381` `fec2761e` `f8c876ec` `75a15c97` `0c319c95` `8c5fdfc5` `86baaaaa` `33441934` `2491ca0e`
- **deps** (3). `gate` de arranque (hecho, §5): en `src/base` cambian `ssb-gossip` (2 ficheros), `ssb-lan` y `openpgp`; los dos primeros llegan ya con los parches nuevos de upstream aplicados (comprobado por grep). Los tres parches del entrypoint (`ssb-ref`, `ssb-blobs`, `multiserver`) no se tocan.
  IDs: `ccb241e6` `b95e6275` `cc0f043c`
- **outside · instalador y parches** (2). `no-afecta`: `oasis.sh` es bare-metal; `scripts/patch-node-modules.js` es del fork y no se ejecuta sobre el repo. Sus parches nuevos vienen ya aplicados en `src/base`.
  IDs: `67d375cc` `afc2198e`
- **outside · tests de upstream** (23). `no-afecta`: el fork no trae ni ejecuta `test/` de upstream.
  IDs: `253e341f` `597d595e` `fd6ae8c1` `eb3341f1` `eb0d23c5` `b9b0afb6` `83c40863` `919e4b55` `5e7baf16` `7f70e5f9` `9e7860ee` `fdec14f7` `2ce4d229` `cdec2b9b` `27b19e3d` `148eda3d` `01cc7d7c` `807d2a51` `d6e17003` `6b44ae2e` `88e2b2f3` `2597ff10` `cb5fdaad`

## 5. Gates locales (2026-10-05, stack local con identidades desechables)

| Gate | Resultado |
|---|---|
| **U0** línea base | tres nodos `healthy` en 1.2.1, `seq` = `registros` = `sbot` (pub 10, HUB 8, bot 20); motor del bot encendido, épocas `2026-09,2026-10`. Copia y foto `pre122` |
| **U1** árbol | 6 ficheros · `annex` sin `!` (49 invariantes) · `--check` sale 0 |
| **U2** imagen | build limpio (`nucleo vendorizado: carga en node v22.23.3`), 1,58 GB con la IA local; `node --check` de `backend.js` y `phone_module.js` dentro de la imagen; versión 1.2.2. La anterior queda como `:1.2.1-vieja` |
| **U3** recrear y medir | los tres `healthy` a los 5 s. Recién arrancados: `oasisVersion` +1 cada uno y nada más. Parches: `ssb-ref` y `multiserver` «patcheado», `ssb-blobs` «ya parcheado», ninguno «no se encontró» |
| **U4** visor | `hub --strict`: `GATE OK` (10 comprobaciones), también después de que el HUB publicara su `about` |
| **U5** peor caso del bot | `wallet` y `(cifrado)` no se mueven, misma dirección; `karmaScore` +1. **Desviación: `about` +1** (§5.1) |
| **U6** invite | parcial: el pub en 1.2.2 emite un invite con el formato esperado (`invite.create` con `external`). No se redimió con un cliente: `test-invite.sh` solo tiene modo host |
| **U7** repetible | `restore pre122`, render del bot, U3 otra vez: mismo delta que la primera pasada |
| **US** snapshot | el temporizador del entrypoint construyó solo a los 120 s (`[snapshot] {"ok":true,…,"messages":44,"feeds":5}`); `pub-snapshot.sh --local status`: «cada 6 h»; el pub no publicó nada al construir |

Delta completo tras el ciclo (arranque + visor + páginas del bot), medido dos veces:

```
$ upgrade-gates.sh --local check pre122 --expect 'pub:oasisVersion=+1 hub:oasisVersion=+1,about=+1 bot:oasisVersion=+1,about=+1,karmaScore=+0..1,pubAvailability=+0..1'
  pub  v1.2.1 → v1.2.2 · Δseq=1 · oasisVersion+1 → ok
  hub  v1.2.1 → v1.2.2 · Δseq=2 · about+1 oasisVersion+1 → ok
  bot  v1.2.1 → v1.2.2 · Δseq=3 · karmaScore+1 oasisVersion+1 about+1 → ok
GATE OK
```

### 5.1 Hallazgo: HUB y bot publican un `about` (irreversible en el host)

En 1.2.2, `syncPhoneVisibility()` (`backend.js`) compara lo que el nodo tiene publicado en
`visibilityPrefs.phone` con lo que le toca. A un backend **público** le toca `'off'`; lo publicado
por defecto cuenta como `'whole'`. Como difieren, publica **una vez** un `about` propio con sus
`visibilityPrefs` y `phone: "off"`. No sale en el arranque: sale con el primer refresco de fondo
tras atender peticiones (en el HUB, al usar el visor; en el bot, al visitar sus páginas). Después
ya coincide y no vuelve a publicar.

- Medido en HUB y bot locales, dos veces. El pub no lo publica (es solo sbot).
- El mensaje dice la verdad (el nodo no atiende llamadas) y lo usan los clientes para no llamarle.
- No hay ajuste de configuración que lo evite: solo un guard más en `src/`. No se propone.
- **Delta declarado para el host**: `hub:oasisVersion=+1,about=+1` y
  `bot:oasisVersion=+1,about=+1,pubAvailability=+0..1`. Es decisión del custodio (GO-3 y GO-4a).
- La primera disposición de esa línea del diff (`3aa23744`) decía «acción de GUI»: era una lectura
  incompleta. La corrigió el gate U5.

### 5.2 Centralita

```
config.phone = {"relay":true,"roomMax":12}          (lo que ve el sbot del pub local)
roomInfo     = {"count":0,"max":12}                 (phone.roomInfo por el socket del pub)
```

- La clave `phone` del ssb-config llega al plugin y el aforo aplicado es 12.
- La imagen no trae `parec`, `pw-record`, `arecord` ni `notify-send`: sin audio, los nodos ignoran
  los timbres y no hay avisos de escritorio.
- El cartel de arranque del pub imprime un «VoIP ID» aunque no se le pueda llamar: es solo el cartel.
- Memoria en reposo: pub 40 MiB, HUB 143 MiB, bot 135 MiB. No se tomó la de 1.2.1 antes de subir:
  no hay comparación.
- Estado nuevo: en el bot aparece `~/.ssb/oasis/peers/lan-peers.json`; `oasis/phone/` existe vacío.

### 5.3 Sin medir

- **Una llamada o una sala reales**, y por tanto el relé del pub con tráfico: no ensayable en
  contenedores. Se prueba con dos clientes de escritorio contra el host.
- **Redimir un invite** con un cliente en 1.2.2 (U6 completo) y el drill del cliente.
- Memoria y red del pub **retransmitiendo**.

Dos tropiezos de herramienta al correr U4, sin relación con 1.2.2: el frontal local
(`oasis-pub-web`) estaba parado, y la variable `MSYS_NO_PATHCONV` exportada en la sesión hacía
fallar el `curl` del gate. Arrancado el frontal y sin la variable: `GATE OK`.

## 6. Qué viaja al host

`src/` · `pub/config/ssb/config` del pub (**in place**: el del host lleva datos de instancia; se
añade solo la clave `phone`) · `pub/config/hub/oasis-config.json` · plantilla del bot y su render ·
`tools/` no cambia. Orden pub → HUB → bot. En este ciclo HUB y bot se recrean: se retira entonces
la etiqueta `oasis-pub-scriptorium:1.2.1-pre-o123t`. No cambia el motor: hay rollback por retag.

## 7. Aplicación en el host (2026-10-05, GO del custodio)

GO único del custodio para el ciclo, con los dos `about` de §5.1 aceptados en el delta, y encargo
de renombrar el pub.

```
$ upgrade-gates.sh --remote check pre-o124 --expect 'pub:oasisVersion=+1,about=+1 hub:oasisVersion=+1,about=+1 bot:oasisVersion=+1,about=+0..1,pubAvailability=+0..1'
  pub  v1.2.1 → v1.2.2 · Δseq=2 · oasisVersion+1 about+1 → ok
  hub  v1.2.1 → v1.2.2 · Δseq=2 · about+1 oasisVersion+1 → ok
  bot  v1.2.1 → v1.2.2 · Δseq=1 · oasisVersion+1 → ok
GATE OK
```

El `about` del pub es el renombrado (abajo). El del HUB salió al pasar el gate del visor. **El del
bot no había salido en el último `check`**: sale con el primer refresco de fondo tras atender
peticiones, y el bot no tiene ruta pública. Queda declarado como `about=+0..1`.

| Paso | Qué pasó |
|---|---|
| 0 · Medir | `deploy-status.sh`: tres nodos en 1.2.1, HUB y bot aún en la imagen anterior; deriva solo en las dos configs que este ciclo regenera. Foto `pre-o124`: pub 17, HUB 13, bot 60 mensajes propios; las tres fuentes cuadran |
| 1 · Backups | pub → `devops/backups/oasis-pub/20261005T180828Z`; `wallet.dat` antes y después (`backup-ecoin.sh`); en el host `/srv/oasis/oasis-{hub,wallet-bot}.bak-o124-2026-10-05.tgz` (600; el del HUB pesa 2,0 GB porque incluía 1,28 GB de caché HTTP) y `*.bak-o124-2026-10-05` de las tres configs |
| 3 · Rollback | tag `:1.2.1` · `/srv/oasis/src-1.2.1.tgz` · `src.old-1.2.1` |
| 4 · `src/` | `git archive` con `core.eol=lf` a `src.new`; comprobado antes de cambiar: versión 1.2.2, 0 CR en `backend.js` e `is-map`, enlace a `../base/node_modules`, dominio del pub en `snh-invite-code.json`, guards presentes, 24 910 ficheros + el enlace (los 24 911 del repo) |
| 5 · Config del pub | clave `phone` añadida **in place** al ssb-config del host (mismo inodo; el resto del fichero, idéntico) |
| 6 · Build y humo | imagen `9b49a2cb36d6`, 1,08 GB. Humo sin red en `server` y `backend`: `running`, versión 1.2.2, tres parches, `GET /c → 200`, sin `.env.prod` ni `src.old*` dentro |
| 7 · Pub | recreado 18:19:01 UTC, `healthy` a las 18:19:35. `oasisVersion` +1. `/`, `/c` y `/public/status` en 200 (versión 1.2.2). `phone.roomInfo` → `{"count":0,"max":12}` |
| 8 · HUB | config in place (sha256 del nuevo y del sustituido verificados); `healthy` en un minuto; `prune-cache`; `hub --strict`: `GATE OK` |
| 9 · Bot | plantilla in place, render con `sudo` (mismo inodo, sin marcadores, `language` en `en`, `phone.relay` en `false`); `hub-wallet.sh pause` → 1.2.2 con el motor apagado, `oasisVersion` +1, misma dirección, `wallet` = 1; `hub-wallet.sh on --yes` → «PUB engine on». Época de octubre ya abierta: ningún `ubiAllocation` nuevo |
| 9b · Snapshot | el pub lo reconstruyó solo: `[snapshot] {"ok":true,…,"messages":4915,"feeds":83}` |
| 10 · Cierre | foto `post-o124`, `hub --strict` otra vez en verde, journal, ficha de instancia. Retirada la etiqueta `:1.2.1-pre-o123t` (ya sin contenedores) |

Estado final (`deploy-status.sh`): pub, HUB y bot en 1.2.2, `healthy`, «imagen al día»; directorio
`online` ciclo 6; `/` 54 %, `/srv/oasis` 33 %. Memoria en reposo: pub 53 MiB, HUB 206 MiB, bot 146 MiB.
`capacity.sh`: **1 aviso**: seis restos de rollback (los de 1.1.10 y los de 1.2.1).

### 7.1 Renombrado del pub

El custodio pidió que el pub dejara de llamarse `PUB OASIS SCRIPTORIUM` y pasara a
`pub.escrivivir.co`. El pub es solo sbot (sin formulario de perfil): se publicó con
`tools/ssb-admin.js publish-about pub.escrivivir.co`, un `about` con **solo `name`** (secuencia 19
del feed); la descripción publicada antes se conserva.

```
$ upgrade-gates.sh --remote check pre-rename-o124 --expect 'pub:about=+1 …'
  pub  v1.2.2 · Δseq=1 · about+1 → ok
```

Los nodos que ya tenían el nombre viejo en memoria lo muestran hasta su siguiente reinicio
(`nameCache`, `HUB-PROTOCOL.md` §12 paso 6). El HUB no se ha reiniciado después del renombrado.

### 7.2 Sin medir en el host

- Una llamada o una sala reales por el pub (el relé con tráfico).
- El `about` del bot: el `check` de cierre se repitió pasados cinco minutos de recrearlo, con el mismo
  resultado; el bot seguía sin publicarlo. Saldrá cuando alguien visite sus páginas.
- Medida a las 24 h (memoria y red del pub).

## 8. Cliente (nodo personal), 2026-10-05

`CLIENT-PROTOCOL.md` §4-§5. El cliente real estaba parado desde el 2026-10-02, en **1.1.4** y con el
log en flume: subirlo migra a db2 **sin vuelta** por retag. Feed `@tMJz…IRY=`: secuencia 87 en local
y 87 en el pub antes de empezar.

| Paso | Resultado |
|---|---|
| Copia en frío | `devops/backups/client/20261005T183353Z` (`ssb-data` + `client-state`, 423 MB); `secret` y log iguales por sha256 a los vivos, también justo antes de arrancar |
| Imagen | la anterior queda como `o-sdk-oasis-client:1.1.4`; build de 1.2.2 con `OASIS_AI=full`: 5,03 GB |
| Ensayo 1 · migración | copia del log real, **sin el `secret`**, contenedor efímero `--network none`: 4 174 registros y 69 autores antes; `T 4174 · A 69 · D 0` después; guarda a los 2 s; `db2/` 5,2 MB; 89 MiB. Copia borrada |
| Ensayo 2 · drill | identidad desechable de 1.1.10 a 1.2.2: `healthy`, db2, secuencia 3 → 4 (solo `oasisVersion`), 1 `wallet`, ningún `about` ni tras visitar páginas; `client:ecoin:verify` 14 PASS; tema, cartera e idioma conservados |
| Cliente real (GO del custodio) | `docker compose up -d --no-build oasis-client`: `healthy` a los 22 s, tres parches, guarda de migración escrita, `db2/log.bipf` |

Healthcheck del cliente real:

```
feed          @tMJzSfcZSNCsFRF3pl3rMoFDatz6VjDCjQ8/TpjYIRY=.ed25519   (secret: mismo sha256 que la copia)
propio        seq=88 · último: {"type":"oasisVersion","version":"1.2.2",…}
log           T 4937 · D 0 · A 83
GUI           /settings → 1.2.2 · welcome-pm en el log: 0
verificación  ✓ Your feed: 88 messages, last sequence 88 · ✓ Forks: 0
              ✗ Files: 160 present, 258 referenced, 9 orphan · ✗ Your own files missing from this device: 3
pub           seq_pub=88   (a los dos minutos de arrancar)
cartera       client:ecoin:verify → 14 PASS · 0 FAIL; 1 mensaje wallet; backup en devops/backups/client-wallet/20261005T184201Z
IA            client:test-ai → POST /ai → HTTP 200
```

- Publicó solo su versión (secuencia 88) y el pub la recibió.
- Las dos ✗ de ficheros son blobs, no mensajes: antes del upgrade había 155 ficheros en `blobs/` y
  después 160. No se midió la verificación antes de subir, así que no hay comparación directa.
- Entre el ensayo (4 174 registros) y el arranque real (4 937) la diferencia es lo replicado al
  volver a conectarse tras tres días parado.
- Phone no funciona en el cliente tal como está: `/phone` dice «not available on this device»; el
  contenedor no tiene acceso al audio de la máquina.
- El drill queda parado, con sus datos en `volumes-dev/drill`.
- El stack local de ensayo del pub se paró entero mientras arrancaba el drill (18:38:29 UTC); la
  orden lanzada solo levantaba el drill y no se determinó quién lo paró. Sigue parado.
