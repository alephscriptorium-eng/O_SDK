# WP-O143 · Enlace garantizado de los nodos de soporte con el pub, cableado al protocolo de upgrade

Rama `wp/O143-enlace-pub` desde `main` 960dfda2. 2026-10-15. Decisión: **D-O38** («pub de la casa garantizado,
externos permitidos»; el enlace es un invariante medido). Método + ensayo local + aplicación en el host con GO por
paso (misma versión 1.3.0: la imagen se reconstruye porque cambian el entrypoint y `pub/tools`).

## 1. Estado de partida (medido)

- **Hallazgo** (WP-O141, GO-4b): el sbot del bot de cartera llevó de 2026-10-14T23:02Z a 2026-10-15T14:55Z sin conectar
  con nuestro pub, con `conn.json` sano (`autoconnect: true`, `failure: 0`) y TCP en orden (`connect ok 172.18.0.4`);
  lo destapó la precondición de `hub-wallet.sh on` (que leía las últimas 2000 líneas del log del pub) y se forzó por RPC
  con GO. La foto del protocolo mide lo publicado, no la conectividad.
- **Causa, en código** (`src/base/node_modules/ssb-conn/lib/conn-scheduler.js`, parcheado por upstream en
  `scripts/patch-node-modules.js:153-195`): `maintainConnections(4, isNotRoom, …)` = **4 plazas salientes** por nodo;
  las entrantes no cuentan (`.filter((p) => !p[1].inbound)`); con las plazas llenas `take(0)` hasta rotar (~2 h/√N,
  expulsando al de menor `oasisPeerRank`); el orden de entrada y de expulsión lo decide `ssb.oasisPeerRank`
  (`src/server/network_pause.js:75-90`: versión al día, seguidos compartidos, total). `autoconnect` solo filtra; no
  existe «par prioritario». `syncPeerBook` (`network_pause.js:179-186`) con `pub: true` marca `autoconnect: true` a
  **todo** pub descubierto: cada `hub-wallet.sh on` llena de candidatos al bot. `conn.populatePubs: false`
  (`conn-scheduler.js:433`) corta el descubrimiento.
- **Causa, en vivo** (RPC `conn.dbPeers`/`conn.peers` dentro de cada contenedor del host, 2026-10-15 ~15:20Z): bot 17
  pubs conocidos / 17 `autoconnect` / 4 salientes (elhack, 4ndr0m3d4, solarnethub, nuestro pub tras el `connect`
  forzado); **HUB 12 / 9 / 4** (elhack, 4ndr0m3d4, nuestro pub por IP, thepirateoasis: también compite); **pub 19 /
  17 y 1 saliente** (los externos le entran: 6 entrantes), 3 plazas salientes libres. `friends.hops` al pub = 1 desde
  HUB y bot. `oasisPeerRank` no está expuesto por muxrpc. Tras recrear el bot a las 14:56 reconectó solo a las
  14:56:12 y seguía conectado a las 15:10 (sus 4 plazas: elhack, 4ndr0m3d4, solarnethub, nuestro pub).
- Lo que había para medir: `pub/tools/ssb-probe.js` ya devolvía `peers[]` (sin `inbound`/`failure`/`stateChange`,
  con un `.catch(() => [])` que confundía fallo con «sin pares») y `node_probe_seq` lo descartaba; `hub-conn-fix.js`
  ya hacía `remember` + `connect`; `compare_snaps` admite campos nuevos sin tocar el parser.

## 2. Entregado (commit por pieza)

| Commit | Pieza |
|---|---|
| c7f8d7bc | `feat(tools)`: `ssb-probe.js` — `peers[]` con `inbound`/`failure`/`stateChange` (lo vivo fundido con la libreta), `peersError` (ya no se tapa un fallo como «sin pares»), `SSB_LINK_KEY` → `link`/`linkState`/`linkInbound` por clave. También retira `hub-conn-fix.js` (su `git rm` estaba en el índice; los mensajes de los commits 2 y 4 lo sitúan mal) |
| cc8b76d1 | `feat(tools)`: `pub-link.js` — `--status`, `--ensure <host> [--key] [--port]`, `--remember`, `--connect`, `--disconnect <host>` (por clave, todas las direcciones), `--forget-seeded`; una línea JSON, 0 publicaciones |
| 48efbc4b | `feat(lib-node)`: `node_probe` único por nodo, `node_probe_fields/link/peers`; en destino `node_probe_js`, `node_pub_link_js`, `node_link`, `node_peers`, `node_pub_link` |
| f0f969a7 | `feat(gates)`: `peers` y `pub_link` en la foto; criterio en `check` (`?` NO MEDIBLE, `ausente` soft); `link <alias> [--yes]`; `smoke` exige la línea del keepalive en modo `backend`; `GATE_PUB_ALIAS`, `GATE_LINK_NODES`, `GATE_PUB_LINK_HOST` |
| 22a171b8 | `feat(hub-wallet)`: `status` con `pares:`; `ready` mide por `conn.peers()` del bot; el log del pub queda como `info` |
| f43c8777 | `feat(deploy-status)`: sección «Enlace de los nodos de soporte con el pub» (`LINK` por backend) |
| c4d63d63 | `feat(entrypoint,compose)`: `start_pub_link` (modos `client|backend`; `OASIS_PUB_LINK_HOST` vacío = desactivado, `EVERY_S` 60, `FIRST_S` 30; `[pub-link]` solo en cambios); compose con las tres variables para HUB y bot |
| 8a0e81ed | `feat(config)`: `conn.populatePubs: false` en los tres `ssb-config` (HUB = bot; `engine-on` solo difiere en `pub`) |
| 29bd5f2e | `test(invariants)`: `link.tsv` (9 anclas de upstream, 6 del fork; `annex` 0 rotos) |
| bb45693b | `docs(protocolos)`: UPGRADE §0.2/§3.4/§4/§6, HUB §2/§3/§5/§11, ECOIN §2/§3/§9/§14, AGENTES §4, fichas §5 |
| 4ceef6b5 | `docs(plan)`: D-O38, CHANGELOG, backlog |

## 3. Gates locales

Stack `volumes-dev/` (identidades desechables), imagen local reconstruida con el keepalive (`f37e7e9d…`), 15:30-16:05 UTC.
`G = upgrade-gates.sh --local`; `X = docker exec -i -u oasis -e HOME=/home/oasis`.

| Gate | Comando | Salida |
|---|---|---|
| Sonda | `X -e SSB_ACTION=peers -e SSB_LINK_KEY=<pub> oasis-pub-wallet-bot … < ssb-probe.js` · `SSB_ACTION=seq` | `peersTotal 2, peersInbound 0, linkState "connected", linkInbound false` · `"seq": 31` (igual que antes) |
| pub-link | `--status` · `--ensure oasis-pub` · `--disconnect oasis-pub` → `--ensure` | JSON de pares y libreta · `before connected, did nothing` · `after absent` → `before absent, did connect, after connected` |
| lib-node | `node_probe_link oasis-pub-hub <feed> <pub>` · `node_probe_peers` · `node_probe_seq` · en destino `node_link`/`node_peers`/`node_pub_link` por `run` | `connected out` · `1 (0 in)` · `15` · hub `connected out · 1 (0 in)`, bot `connected out · 2 (0 in)`; drill por clave `ausente` → `--ensure` → `connected out` |
| D1 | `compose build oasis-pub` · `$G smoke oasis-pub-scriptorium:latest` | imagen `f37e7e9d…` · **`SMOKE OK`** (incluye el `ok` de «Enlace con el pub» en modo `backend`) |
| D2 | `$G up hub` · `$G up bot` · logs · `$G snapshot l1` | `healthy` a los 4 s ×2 · `🔗 Enlace con el pub: oasis-pub, primera comprobación a los 30 s y después cada 60 s (/app/pub/tools/pub-link.js)` + primera línea `[pub-link] {…"before":"connected"…}` en ambos · foto: pub `pares=2 (2 in)`, hub `pares=1 (0 in) enlace-pub=connected(out)`, bot `pares=2 (0 in) enlace-pub=connected(out)` |
| Criterio `check` | `GATE_PUB_ALIAS=hub GATE_LINK_NODES=bot $G check l0 --expect 0` · ídem `--wait --max 30 --every 10 --stable 10` | `bot … enlace-pub ausente → DESVIACIÓN: sin enlace con el pub (pub_link ausente)`, rc 1 · `… 13 s: rc=4` → `todavía no: sin enlace con el pub` → `GATE: DESVIACIÓN — el delta esperado no se alcanzó en 30 s`, rc 1 (nunca verde) |
| D3 | `--disconnect oasis-pub` en el bot → sonda cada 5 s → `$G check l1 --expect 0` | enlace `connected` **1 s** después de la caída (lo repuso el planificador local: con plazas libres marca al instante; el keepalive dijo `did:nothing`) · `GATE OK` |
| D4 (CA) | `$G up pub` (cambia de IP) → `$G check l1 --wait --expect 0 --max 240 --every 10 --stable 20` | `healthy` a los 4 s · **`GATE OK` a los 34 s** del `up`: hub y bot `enlace-pub connected(out)`, sin intervención |
| `link hub` | `$G link hub` | el HUB solo conocía al pub por IP (la del invite): `--ensure … --key` → `did: remember` de `net:oasis-pub:8009` + `connected`; libreta del HUB con la entrada por nombre · `LINK OK` |
| D6 (1.ª) | `$G link pub` con `remember autoconnect:true` → 60 s → sonda del pub | hub y bot `connected(in)`, pero en el pub **cada clave 2 veces** (su planificador marcó a nodos ya conectados) y los entrantes dejaron de marcarse `inbound`; 0 errores en los logs. **Riesgo previsto, confirmado → fallback de B1** |
| D6 (2.ª) | recrear hub y bot (limpia) · `$G link pub` (ahora `--ensure` desde el pub con `--autoconnect false`) | `pub → hub: did update`, `pub → bot: did update` (libreta a `autoconnect:false`, sin conectar: ya estaban) · pub: **1 conexión por clave**, entrantes `inbound:true` · bot sin enlace → `link pub` → `did nothing` (el planificador local llegó antes) · `LINK OK` |
| D7 | `upgrade-behaviour-diff.sh 37e0fc93 37e0fc93 --section annex` · duplicados | 15 filas `[link]`, **0 rotos** · 0 duplicados en los `.tsv` |
| hub-wallet | `hub-wallet.sh --local status` · `--local ready` | `pares:      2 (0 in) · pub: connected out` · `ok conectado al pub (connected out, por conn.peers() del bot)` + `info log del pub: CONNECTED` |
| deploy-status | `deploy-status.sh` (host, lectura) | `oasis-pub-hub connected out pares 4 (0 in)` · `oasis-pub-wallet-bot connected out pares 4 (0 in)` |

Lo que el ensayo local **no** reproduce: la saturación de las 4 plazas (el bot local solo conoce a nuestro pub), así que el
keepalive no llegó a tener que conectar (el planificador local siempre gana la carrera). Su lógica (`--ensure`) sí está
medida: `absent → connect → connected` en el drill de pub-link. La imagen local de D2-D4 llevaba el `pub-link.js`
anterior al arreglo de `process.argv` (el keepalive no pasa `--port`, así que no le afectaba); el host construye el final.

## 4. Delta de publicación

Local: ninguna publicación en ningún gate (recreaciones en la misma versión; todos los `check --expect 0` verdes).
Host: pendiente (§6).

## 5. Correcciones al protocolo

- **La capa pub no puede llevar `autoconnect`**: con él el planificador del pub marca a un nodo que ya está conectado y
  quedan dos conexiones por clave (ssb-conn-hub deduplica por dirección). `link pub` guarda la libreta sin `autoconnect`
  y conecta solo con el nodo al que le falte el enlace (`--ensure` desde el pub). D-O38, HUB §2 y UPGRADE §0.2 lo dicen así.
- **`ssb-config` lee `process.argv`**: cualquier herramienta que viaje por `node -` con opciones propias (`--port`) debe
  retirarlas antes de cargar `ssb_config.js`; la sonda no lo sufre porque va por variables de entorno. En `pub-link.js`.
- **`--ensure` necesita la clave cuando el nodo solo conoce al pub por IP** (la entrada que deja el invite): con `--key`
  crea la entrada por nombre de servicio y a partir de ahí el keepalive, que no sabe la clave, ya tiene su entrada.
  `link <alias>` la pasa siempre. HUB §3 (bootstrap) debería terminar con `link hub` por esta razón, no solo por medir.
- **`--disconnect` corta por clave**, no por dirección: un nodo tiene al pub por nombre y por IP, y cortar solo una no
  es una caída (medido: `--ensure` veía el enlace vivo por la otra).

## 6. Aplicación en el host

(pendiente: GO-1 … GO-3)

## 7. Seguimiento

(pendiente)
