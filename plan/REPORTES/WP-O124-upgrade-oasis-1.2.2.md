# WP-O124 · Upgrade a Oasis 1.2.2 (Phone y Rooms) · fase local

2026-10-05 · rama `upgrade/oasis-1.2.2` · upstream `942d39c9` (1.2.1) → `b1f7adfc` (1.2.2).
**Estado: overlay, guards, invariantes, configuración y documentación hechos. Build y gates locales
SIN HACER: Docker local estaba apagado.** El host no se ha tocado: sigue en 1.2.1.

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
Donde dice «pendiente», la disposición es un gate que aún no se ha corrido.

- **roles · el plugin de la centralita y lo que lo carga** (5). `adaptado` en `2ed09ff4` y `documentado` en `HUB-PROTOCOL.md` §14: el sbot carga `phone_module` y `network_pause`; el pub acota la centralita desde su ssb-config. `gate` de arranque del pub (pendiente: Docker local apagado).
  IDs: `ea7cb03a` `dd4c8958` `a7b2b8f1` `aba81af3` `46f6e16c`
- **roles · resto del código que carga el pub** (11). `gate` U3 (pendiente): leídos los diffs de `SSB_server.js`, `lanRouter.js` (guarda de LAN; el pub va con `local: false`), `ssb_metadata.js` (cartel de arranque: añade «VoIP ID», «Mode», «Workflow»), `config-manager.js` (normaliza `phone`, módulos nuevos), `shared-state.js` (estado en memoria), `banking_model.js` (karma de `room`, filtro de direcciones), `typed_log.js`. De `updater.js`, `desktopNotify.js`, `viewer_filters.js`, `workflows_model.js` y `state-manager.js` solo lo que toca a los guards y al estado. Lo decide la medida: el pub publica `oasisVersion` +1 y nada más.
  IDs: `fb29c533` `7bbaee7e` `11e046cb` `5c0837d4` `bd892fc9` `9f6ad872` `ad3e9c63` `83e4f40f` `0dfe1974` `8e63beb3` `f870255c`
- **files · ficheros de Phone y Rooms** (7). `documentado` en `HUB-PROTOCOL.md` §14. Modelos y vistas son de la GUI; en los nodos de soporte nadie la usa.
  IDs: `5502abb6` `435267e7` `bbb8a952` `20d197ee` `8d907d99` `89a70280` `82fbe25b`
- **files · resto** (3). `no-afecta`: `desktopNotify.js` solo actúa si existe `notify-send` y lo arranca un backend no público; `peer_health.js` y `network_pause.js` acompañan a la pausa de red, que ningún compose activa.
  IDs: `aa01c0d2` `d6cabc13` `c39727ef`
- **routes · rutas nuevas** (39). `no-afecta` al clearnet: ninguna cae bajo `/c/` (nginx y Caddy no cambian). Son la GUI de Phone, Rooms, pausa de red, Pixelia y bienvenida; las POST son acciones que alguien pulsa, y en HUB y bots nadie lo hace. `gate` `hub --strict` (pendiente).
  IDs: `dc2e46f5` `17e60c85` `edde6593` `cd4abe51` `20a7caf3` `07bb6d12` `359803d6` `48fd1cdf` `540b2c2b` `5e36254b` `f431293b` `be788722` `f5acfde0` `f305465d` `32d5c076` `d6e52237` `f5d5ace2` `e505b340` `16106ba1` `3356031a` `03f38827` `a09d4048` `ed9b2f84` `90b0f583` `6a57ec01` `d9f603b4` `78506945` `aa7fa6db` `b7242be1` `5a25d5a4` `e1a30be7` `5e8e9057` `2495d23a` `f6a82403` `d46e372c` `d89a51fb` `145c6907` `c3316109` `86e3c5ac`
- **routes · rutas retiradas** (4). `no-afecta`: `/settings/conn/*` pasa a ser `/peers/pause` y `/peers/resume`. Ningún script ni documento del fork las usaba (grep: 0).
  IDs: `5b3d0176` `b3fd6af2` `5a67ff51` `4c2a62be`
- **loopback** (1). `no-afecta`: acción de la GUI de bienvenida, reservada al loopback.
  IDs: `7b42af71`
- **publish** (7). `gate` U3/U4 (pendiente): todas salen de una acción de GUI (ajustes de Phone → `about` con `visibilityPrefs.phone`; enviar un mensaje de voz → privado `pam`; salas → `room`, `roomMember`, `tribe-keys`) o son el mismo `publishJoin`/`publishLeaveLarp` con otro manejo de error. Ninguna está en un temporizador. Tipos nuevos posibles en el log: `room`, `roomMember`, `pam` (cifrado).
  IDs: `3aa23744` `a0703915` `4987510f` `1d05f40f` `d6e92691` `fec2443a` `5075acb3`
- **timers · arranque de Phone en el backend** (2). `no-afecta` con el compose actual: `phoneModel.start()` y los avisos de escritorio solo arrancan `if (!config.public)`, y HUB y bot van con `OASIS_PUBLIC=true`. Ojo en un alta: durante el bootstrap del invite (`OASIS_PUBLIC=false`) sí arrancan; sin audio no hacen nada observable. `gate` U4.
  IDs: `8492ef7a` `31761e2f`
- **timers · plugin phone** (10). `no-afecta`: temporizadores de una llamada o sala en curso en el propio nodo (timbre, buzón, entrada a sala). Sin dispositivo de audio el nodo ignora los timbres y no puede llamar ni entrar en salas; el lado de relé no arma ninguno.
  IDs: `f06976e7` `a8d6bc17` `65bed86d` `71564fee` `2f7d2b6a` `ec033c19` `e82be24f` `6b1d03a9` `2322d7d8` `0d83447a`
- **timers · resto** (2). `gate` U4 (pendiente): dos temporizadores retirados de `main_models.js`.
  IDs: `66f7fe25` `9c4f07ae`
- **headers** (4). `gate` `hub --strict` (pendiente; «una sola cabecera CSP»): la CSP gana un parámetro de marcos para `GET /games/<id>` (fuera de `/c/`); la cookie `theme` y el `referer` nuevos están en `/welcome/workflow`, loopback. El tema del visor sigue saliendo de la config (invariante `themes?.current`: ok).
  IDs: `6d79f1e1` `b9825219` `d1aecef4` `fd9ec9e9`
- **env** (3). `documentado`: `OASIS_NETWORK_PAUSED=1` arranca el nodo sin conexiones; ningún compose debe definirla (hoy: 0). `PATH` lo lee `desktopNotify.js` para buscar `notify-send`. `OASIS_DEBUG` ya existía.
  IDs: `245b8241` `c154d79c` `b75a39cc`
- **state** (4). `gate` U3/U4 (pendiente): cuatro ficheros nuevos bajo `~/.ssb/oasis/{peers,phone}`. Nacen con el uso; un rollback de imagen los deja inertes. Si un nodo tuviera ya un `lan-peers.json` o `peer-health.json` fuera de sitio, el arranque lo mudaría (solo hacia delante).
  IDs: `2edffebd` `28685784` `647d52d1` `25eae6c1`
- **config** (15). `adaptado` en `2ed09ff4`: configs del HUB y del bot regeneradas (`regen-node-configs.js --check`: al día) con `phone.relay = false`. `language` no se mueve en los nodos (el script lo conserva). `blobCache` sigue fijado por el script.
  IDs: `29dde2d3` `fd585f0d` `7c52f483` `8017348e` `b1c87985` `2944e32a` `22253381` `fec2761e` `f8c876ec` `75a15c97` `0c319c95` `8c5fdfc5` `86baaaaa` `33441934` `2491ca0e`
- **deps** (3). `gate` de arranque (pendiente): en `src/base` cambian `ssb-gossip` (2 ficheros), `ssb-lan` y `openpgp`; los dos primeros llegan ya con los parches nuevos de upstream aplicados (comprobado por grep). Los tres parches del entrypoint (`ssb-ref`, `ssb-blobs`, `multiserver`) no se tocan.
  IDs: `ccb241e6` `b95e6275` `cc0f043c`
- **outside · instalador y parches** (2). `no-afecta`: `oasis.sh` es bare-metal; `scripts/patch-node-modules.js` es del fork y no se ejecuta sobre el repo. Sus parches nuevos vienen ya aplicados en `src/base`.
  IDs: `67d375cc` `afc2198e`
- **outside · tests de upstream** (23). `no-afecta`: el fork no trae ni ejecuta `test/` de upstream.
  IDs: `253e341f` `597d595e` `fd6ae8c1` `eb3341f1` `eb0d23c5` `b9b0afb6` `83c40863` `919e4b55` `5e7baf16` `7f70e5f9` `9e7860ee` `fdec14f7` `2ce4d229` `cdec2b9b` `27b19e3d` `148eda3d` `01cc7d7c` `807d2a51` `d6e17003` `6b44ae2e` `88e2b2f3` `2597ff10` `cb5fdaad`

## 5. Sin hacer

- **Build local y gates (§3.4 del protocolo)**: arranque del pub con el plugin, log de parches,
  `check` (el pub publica `oasisVersion` +1 y nada más), HUB `--strict`, bot, snapshot.
- **Aforo aplicado**: `phone.roomInfo({ rid })` contra el pub local debe devolver `max: 12`.
- **Memoria del pub** en reposo frente a 1.2.1.
- **Una llamada real**: no ensayable en contenedores (sin audio); se prueba con dos clientes de
  escritorio contra el host.

## 6. Qué viaja al host (cuando haya GO)

`src/` · `pub/config/ssb/config` del pub (**in place**: el del host lleva datos de instancia; se
añade solo la clave `phone`) · `pub/config/hub/oasis-config.json` · plantilla del bot y su render ·
`tools/` no cambia. Orden pub → HUB → bot. En este ciclo HUB y bot se recrean: se retira entonces
la etiqueta `oasis-pub-scriptorium:1.2.1-pre-o123t`. No cambia el motor: hay rollback por retag.
