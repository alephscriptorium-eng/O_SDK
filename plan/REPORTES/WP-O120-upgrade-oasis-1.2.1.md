# WP-O120 · Upgrade a Oasis 1.2.1 en local: overlay, build sobre `src/base`, gates con migración

Rama `upgrade/oasis-1.2.1` (sobre `wp/O119-medida-db2`) · 2026-10-04 · asiento D-O27 ·
`OLD_REF=f770dbb7` (1.1.10) · `NEW_REF=942d39c9` (1.2.1). **El host no se ha tocado.**

## 1. Estado de partida

`deploy-status.sh` del 2026-10-03: pub, HUB y bot en 1.1.10, `running healthy`, imagen al día;
directorio en verde, ciclo 6; `/` al 52 %, `/srv/oasis` al 23 %. Deriva: `Dockerfile`,
`docker-entrypoint.sh`, `.dockerignore` y `pub/docker-compose.pub.yml` del host distintos de `HEAD`.
Restos del ciclo anterior sin retirar: `src.old-1.1.4`, `src-1.1.4.tgz`, imagen `:1.1.4`.

Preflight: `LOCAL=1.1.10 UPSTREAM=1.2.1`; cambian 11 de los 17 ficheros que carga el pub; 125 de
backends y cliente; 19 145 vendorizados en `src/base`. Mismo ciclo de red.

Línea base local (`upgrade-gates.sh --local snapshot pre121`, identidades desechables):

```
  pub  running healthy  v1.1.10  server   log=flume seq=6 registros=6 → cuadra · sbot=6
  hub  running healthy  v1.1.10  backend  log=flume seq=7 registros=7 → cuadra · sbot=7
  bot  running healthy  v1.1.10  backend  log=flume seq=17 registros=17 → cuadra · sbot=17   motor:pub=true épocas=2026-09,2026-10
```

## 2. Qué se entregó

| Commit | Pieza |
|---|---|
| `38c45c7a` | `.gitignore` y `.gitattributes`: `src/base` se versiona entero y sin conversión de fin de línea |
| `17f7c2a0` | overlay de `src/` desde upstream `942d39c9` |
| `0aac9bdb` | guards repuestos e interruptor `OASIS_SNAPSHOT` |
| `67bb7608` | `Dockerfile` (Node 22, enlace a `src/base`, IA por `ARG`), entrypoint sin instalaciones en caliente y con parches idempotentes, `.dockerignore`, parcheador sincronizado |
| `61611713` | `OASIS_SNAPSHOT=off` en HUB y bot; configs regeneradas (`filesMod`; el idioma no se mueve) |
| `b458e3d8` | `upgrade-invariants.d/db2.tsv`; Files en el gate del HUB, en `hub.tsv` y en la Sala 04 |
| `a193b5a2` | scripts del cliente para log en flume o en db2 |
| `68e22ddc` | protocolos al día |

Invariantes del overlay:

```
$ git diff oasis-upstream/main --stat -- src/
 src/backend/backend.js            | 12 ++++--------
 src/backend/updater.js            |  4 ++--
 src/configs/blockchain-cycle.json |  4 ++++
 src/configs/snh-invite-code.json  |  2 +-
 src/server/ssb_config.js          | 23 ++++++++++++++++++++++-
 src/views/settings_view.js        |  5 ++---
 6 files changed, 35 insertions(+), 15 deletions(-)
$ git diff oasis-upstream/main --stat -- src/base | wc -l
0
$ git ls-files -s src/server/node_modules
120000 319d131ddbbd49f43b6a4b66c166f71c1fb1ecf7 0	src/server/node_modules
$ grep -m1 '"version"' src/server/package.json
  "version": "1.2.1",
```

## 3. Disposiciones del diff de comportamiento

`upgrade-behaviour-diff.sh f770dbb7 942d39c9`: 233 líneas, 183 piden disposición; `annex`: 42
invariantes, ninguno roto.

- **roles · código que carga el pub** (11). `gate` UM y U3: el pub migra y publica solo `oasisVersion` (+1); el cierre de requires trae `db2_legacy.js` y `snapshot_plugin.js`, que en modo `server` sirve un fichero que solo existe si el pub lo construye (WP-O122).
  IDs: `11e046cb` `bd892fc9` `9f6ad872` `4763d574` `ad3e9c63` `dd4c8958` `e6ef65b3` `aba81af3` `bf7df730` `7c250c58` `f870255c`
- **files · `src/maps/cache/*.png`** (9). `no-afecta`: nueve PNG que upstream subió a git; es una caché que el backend ya escribía en 1.1.10. Su crecimiento en runtime se mide en WP-O121.
  IDs: `87bb89f5` `f79d89af` `c28dbb70` `8027674d` `9cb53d7c` `f0d7bd0d` `28f89aae` `af5e7054` `78cdeaa7`
- **files · `src/AI/package*.json`** (2). `adaptado` en `67bb7608`: la IA sale del núcleo; el `Dockerfile` la instala solo con `OASIS_AI=nav|full`.
  IDs: `c813c62b` `0a46eb94`
- **files · `src/server/node_modules`, `db2_legacy.js`, `snapshot_plugin.js`** (3). `adaptado` en `67bb7608` (el enlace se crea en el build) y `gate` UM (motor nuevo). Asiento D-O27.
  IDs: `df41e51d` `3f912b03` `869b591e`
- **files · modelos y vista nuevos (Files, caché de blobs, descargas)** (4). `no-afecta` a pub, HUB y bot: los ejecuta un backend con una persona delante. Lo que hacen solos está en `timers`; lo que publican, en `publish`.
  IDs: `4ccff921` `3f8a5e43` `ff8b7498` `352e67c5`
- **routes · `/c/files/:id`** (1). `gate` U4 (`/c?type=files`, `/c/rss/files`) y `adaptado` en `b458e3d8`: invariante en `hub.tsv`, fila en la Sala 04. nginx y Caddy no cambian: cae en la location genérica.
  IDs: `7fd24b6d`
- **routes · caché de blobs en Ajustes** (2). `documentado` en `docs/PUB/CAPACIDAD.md` (WP-O121): en un backend público el recolector está apagado por defecto.
  IDs: `ba3bb859` `32e41e00`
- **routes · resto (Files, PeerTube, torrents, PDF de pads, `gpg.asc`, vista previa del feed)** (28). `no-afecta` a los nodos de soporte: son rutas de la GUI. El HUB solo expone `/c/*` (Caddy y nginx no enrutan otra cosa) y en `--public` todo lo que no es GET responde 403; el bot no tiene ruta pública. En el cliente son botones nuevos que solo actúan al pulsarlos.
  IDs: `30b3c5da` `dc753151` `ea610c40` `005bc12f` `69cf0510` `14319377` `454ac8a8` `d731792e` `b1a3a69e` `7a4074c1` `0c5b7bc3` `5901bc8f` `2c65dcfa` `695c0c5e` `3a7d0b7f` `632565b2` `5886dce0` `9c019f43` `abeee0e6` `c0c50849` `3a118b55` `845a24b4` `e7b87aa2` `a9c5274e` `2e8a2ddd` `90a41490` `e3d6d2a1` `0da647a8`
- **publish · `files_model.js`** (5). `no-afecta` a los nodos de soporte y `gate` U3/U5: las cinco publicaciones cuelgan de `POST /files/*`; ninguna corre al arrancar ni por temporizador (delta medido: solo `oasisVersion`).
  IDs: `1a0e389c` `602dce10` `74703fe7` `b0b01b6e` `1a0e389c`
- **timers · construcción de snapshots** (2). `adaptado` en `0aac9bdb` y `61611713`: `OASIS_SNAPSHOT=off` en HUB y bot. `gate` U3: tras más de 2 min arriba, `oasis/content/` no tiene ningún `snapshot*.oasissn`.
  IDs: `4c43fd79` `93c50bae`
- **timers · recolector de la caché de blobs** (3). `documentado` en `docs/PUB/CAPACIDAD.md` (WP-O121): con `--public` el límite es `pubMaxMB = 0` y el recolector no hace nada; el límite se fija a propósito en las configs de HUB y bot.
  IDs: `c043cce4` `d685ea28` `0dd6bb4a`
- **timers · migración del log** (1). `gate` UM: espera a que desaparezca el log viejo antes de escribir la guarda.
  IDs: `bacad167`
- **timers · resto (descargas de torrents, tiempo de espera de PeerTube)** (3). `no-afecta`: solo arrancan con una acción de la GUI en un backend no público.
  IDs: `bc39af9f` `3a80bc84` `59c9fcf0`
- **headers** (32). `gate` U4 y `no-afecta` a la caché: son `Content-Disposition`, `Content-Range`/`Accept-Ranges`, `Refresh` y `Cache-Control` de descargas y de páginas de la GUI. Ninguna hace depender la respuesta del visitante (no hay `Accept-Language`, cookies ni `Vary` nuevos); lo que cambia la respuesta viaja en la URL (`?name=`, `?download=`), que es la clave de la caché.
  IDs: `7e57c111` `441bd350` `eb1b4240` `25c9f97b` `98cc75f4` `b774e8b2` `77fde478` `90aa57d3` `baac6b97` `367c7881` `3ced57dc` `ee16cad1` `a576fe1a` `fa119033` `a576fe1a` `fa119033` `d9205539` `d9205539` `ef012d75` `1d9cd6ef` `0b85f607` `1d9cd6ef` `d75f6efc` `d92c98e2` `45bab966` `d6b4cbf5` `d6b4cbf5` `c4858c10` `6afcd2e6` `00844962` `6afcd2e6` `7cca8dd0`
- **state** (3). `documentado` en `UPGRADE-PROTOCOL.md` §0.2 y `CAPACIDAD.md`: `blob-access.json` y los dos ficheros de snapshot viven en `oasis/content/`. Con el interruptor, HUB y bot no los crean (medido en U3).
  IDs: `3549189c` `a1e5c2f1` `aef72e7b`
- **config** (5). `adaptado` en `61611713`: `filesMod` entra en las configs regeneradas; el cambio del idioma por defecto (`en` → `es`) no mueve ningún nodo porque HUB y bot conservan el suyo.
  IDs: `499c95d7` `7a624a9a` `02b7156e` `0d42df26` `2491ca0e`
- **deps · Node** (2). `adaptado` en `67bb7608`: `node:22-bookworm-slim`.
  IDs: `76ded215` `ebc0beb8`
- **deps · dependencias vendorizadas y cambios de `package.json`** (45). `gate` U2 (el build prueba que el núcleo carga desde `src/base`), U3 (arranque y parches en el log) y U6 (invite). Los plugins que desaparecen (`ssb-db`, `ssb-query`, `ssb-backlinks`, `ssb-links`, `ssb-about`, `ssb-private`, `ssb-search`…) los sustituye `db2_legacy.js`; el tooling del fork no usaba ninguna de sus RPC salvo `getLatest` (corregido en WP-O119). La IA (`node-llama-cpp`, `@xenova/transformers`, `onnxruntime-node`) pasa a `src/AI`.
  IDs: `3fbafa6f` `b5ebffa9` `cdce8473` `6683e0ff` `5f46975b` `42f019ff` `6e3b1511` `7a590e2f` `c2f4a720` `d32cee09` `925ee443` `6826e4d3` `a5fe4937` `e60686e6` `c83364a4` `c8d57e17` `cc926d79` `3af18cf7` `dc5d7002` `8708fbb7` `4cace75e` `a4b85b88` `74926e76` `f731cd88` `816180e9` `900878d5` `73a505a8` `aac8c90c` `1111832f` `d14cfa96` `acd9a6eb` `7ddd723a` `6c65b7ad` `962d2c6d` `5adf9798` `7420f205` `b34e0888` `29eff339` `f7207a1c` `1ed3fff4` `518ba093` `8d83a4e8` `64f8b951` `3f2b3d08` `77a481ed`
- **outside · `.gitignore` y `scripts/patch-node-modules.js`** (2). `adaptado` en `38c45c7a` (reglas para `src/base`) y `67bb7608` (parcheador sincronizado con upstream).
  IDs: `e502d18e` `afc2198e`
- **outside · instaladores y tests de upstream** (20). `no-afecta`: `install.sh`, `oasis.sh`, `build-deb.sh` y `build-base.js` son del camino bare-metal o sirven para regenerar `src/base`, cosa que el fork no hace; los tests no viajan en el overlay.
  IDs: `65c44fee` `67d375cc` `cc279094` `2089d634` `253e341f` `597d595e` `eb3341f1` `caf14b4a` `b53d5335` `b5a2342b` `e039b630` `8fea07e0` `6e0aabcc` `fc49556a` `83c40863` `5e7baf16` `c4b68f60` `01cc7d7c` `d6e17003` `cb5fdaad`

## 4. Qué viaja al host (para WP-O123)

- `src/` entero, ahora con `src/base` (241 MB en disco) y el enlace `src/server/node_modules`:
  `git -c core.autocrlf=false -c core.eol=lf archive`.
- Ficheros de build: `Dockerfile`, `docker-entrypoint.sh`, `.dockerignore`,
  `scripts/patch-node-modules.js`. Los tres primeros **derivan** en el host: hay que traerlos,
  diferenciarlos y converger. Con el `Dockerfile` viejo la imagen haría `npm install` y no usaría
  `src/base`.
- `pub/docker-compose.pub.yml` (deriva en el host): `OASIS_SNAPSHOT=off` en HUB y bot; límites de
  WP-O121.
- `pub/config/hub/oasis-config.json` y `pub/config/wallet-bot/oasis-config.json.tpl` (in place +
  render del bot).
- `pub/tools/` (`snapshot-build.js`, `log-bipf.js`, `ssb-probe.js`): viajan dentro de la imagen.
- `pub/site/hub/index.html` (Sala 04).
- No viajan: nginx y Caddy (sin cambios).

## 5. Gates

| Gate | Resultado |
|---|---|
| U0 | línea base en 1.1.10 (§1) · copia `volumes-dev/.gates/pre121` (755 K) |
| U1 | 6 ficheros · `annex` sin `!` · `--check` de este reporte (abajo) |
| U2 | imagen `oasis-pub-scriptorium:latest` = 1.2.1, **1,58 GB** (la 1.1.10: 4,46 GB). El build prueba que el núcleo carga desde `src/base` |
| humo | contenedores efímeros sin red: `server` y `backend` `running`; Node v22.23.3; enlace `/app/src/server/node_modules -> ../base/node_modules`; `GET /c → 200`; `/app/pub` sin ningún `.env*` |
| **UM** | migración sobre copia sin red (abajo) |
| **UR** | la 1.1.10 sobre un `.ssb` migrado se cae y no escribe (abajo) |
| U3 | `GATE OK` con el delta declarado (abajo) |
| U4 | `hub --strict`: `GATE OK`, con `/c?type=files` y `/c/rss/files` |
| U5 | `worst` + `check u5-121 --expect 'bot:karmaScore=+0..1'`: sin publicaciones, `GATE OK` |
| U6 · invite | funciona sobre db2 (abajo, con WP-O122) |
| U7 | `restore pre121 --yes`, render del bot, repetir U3: mismo delta, `GATE OK` |

**UM** · copia de `volumes-dev/.gates/pre121/<nodo>/ssb-data`, imagen nueva, `--network none`, modo `server`:

```
oasis-pub        · flume: registros=30 autores=3 seq=6  · migrado en 36 s  · db2: S 7  T 31 D 0 A 3 · lector del cliente: format=db2 registros=31 seq=7  tailOk=true bad=0 · db2/: 131K
oasis-hub        · flume: registros=29 autores=3 seq=7  · migrado en 79 s  · db2: S 8  T 30 D 0 A 3 · lector del cliente: format=db2 registros=30 seq=8  tailOk=true bad=0 · db2/: 131K
oasis-wallet-bot · flume: registros=30 autores=3 seq=17 · migrado en 103 s · db2: S 18 T 31 D 0 A 3 · lector del cliente: format=db2 registros=31 seq=18 tailOk=true bad=0 · db2/: 131K
```

Cada log pasa de N a N+1 registros: el `oasisVersion` propio y nada más. Mismos autores, ningún
borrado. Tres lectores coinciden: `inspect-log-offset.js` sobre flume, `pub/tools/log-bipf.js` en
el contenedor y el lector del cliente en la máquina. La guarda queda escrita:
`OASIS: this log was migrated to ssb-db2 (/home/oasis/.ssb/db2/log.bipf) on 2026-10-03T22:44:12.120Z.`
Los tiempos incluyen el arranque del contenedor con la máquina cargada; con logs de 21 KB la
migración tiene un coste fijo de decenas de segundos.

**UR** · imagen `oasis-pub-scriptorium:1.1.10-vieja`, modo `server`, sobre la copia migrada del pub:

```
estado 1.1.10 sobre .ssb migrado: exited exit=7      (ERR_OUT_OF_RANGE en flumelog-offset al leer la guarda)
antes : d81ae93e9c40bfe3 3684a8fd0bf570e5     (sha256 de db2/log.bipf y de flume/log.offset)
ahora : d81ae93e9c40bfe3 3684a8fd0bf570e5
```

Se cae antes de abrir el sbot: no publica. Deja directorios de índices vacíos en `flume/`.

**U3** · `up pub`, `up hub`, `up bot`, `check pre121 --expect 'pub:oasisVersion=+1 hub:oasisVersion=+1 bot:oasisVersion=+1,pubAvailability=+0..1'`:

```
  pub  running healthy  v1.2.1   server   log=db2 seq=7 registros=7 → cuadra · sbot=7     tipos: contact=3 oasisVersion=4
  hub  running healthy  v1.2.1   backend  log=db2 seq=8 registros=8 → cuadra · sbot=8     tipos: (cifrado)=1 about=1 contact=1 oasisVersion=4 pub=1
  bot  running healthy  v1.2.1   backend  log=db2 seq=18 registros=18 → cuadra · sbot=18  tipos: about=3 contact=1 karmaScore=2 oasisVersion=4 pub=1 pubAvailability=4 ubiAllocation=2 wallet=1
  pub  v1.1.10 → v1.2.1 · Δseq=1 · oasisVersion+1 · log: flume → db2 → ok
  hub  v1.1.10 → v1.2.1 · Δseq=1 · oasisVersion+1 · log: flume → db2 → ok
  bot  v1.1.10 → v1.2.1 · Δseq=1 · oasisVersion+1 · log: flume → db2 → ok
GATE OK
```

Ningún `(cifrado)` nuevo, misma dirección ECOin, mismas épocas. Con más de dos minutos arriba,
`oasis/content/` de HUB y bot solo contiene `content_favorites.json`: el interruptor funciona.
Parches en el log de arranque: `ssb-ref patcheado`, `ssb-blobs ya parcheado (viene así en
src/base)`, `multiserver unix-socket patcheado`. `hub-wallet.sh --local status` cuenta sobre db2
(`wallet=1 about=3 pubAvailability=4 ubiAllocation=2`) y enseña el último anuncio.

**Con esto queda validado lo que WP-O119 dejó sin medir**: `log-bipf.js`, `node_log_format` y la
sonda con `createUserStream`, sobre nodos reales en db2.

## 6. Delta de publicación

| Nodo | Local (medido, dos pasadas) | Host |
|---|---|---|
| pub | `oasisVersion` +1 | pendiente (WP-O123) |
| HUB | `oasisVersion` +1 | pendiente |
| bot | `oasisVersion` +1 · `pubAvailability` +0 | pendiente |

## 7. Lo que no se ha medido

- **Drill del cliente** (`CLIENT-PROTOCOL.md` §5) y `npm run client:test-ai`: no se ha construido la
  imagen del cliente con `OASIS_AI=full` ni ejercido `import-identity.sh` y `sync-only.sh` contra
  un origen db2. Los lectores del cliente sí están medidos sobre logs db2 (UM). **Hay que hacerlo
  antes de subir el cliente**; no bloquea el host.
- **Bootstrap completo de un bot nuevo** (HUB §3): medido solo que, con `OASIS_SNAPSHOT=off`, el
  invite no arranca desde snapshot.
- Los caminos `--remote` de los scripts nuevos o cambiados.
- El tamaño real de los logs del host y lo que tarda su migración: lo da el ensayo del paso 6.

## 8. Hallazgos

- **Fin de línea en `src/base`.** Cinco paquetes (`is-map`, `is-set`, `is-weakset`,
  `railroad-diagrams`, `ssb-ref`) traen un `.gitattributes` con `* text=auto`, que gana a la regla
  del fork: 64 ficheros salen en CRLF en Windows. No rompe el invariante ni la imagen local (es
  JavaScript). Al host, `git archive` con `-c core.eol=lf`.
- **El `Dockerfile` hacía `chown -R /app`**: con `src/base` habría duplicado la capa. Quitado.
- **`apply_node_patches` no era idempotente** (anidaba un `try` por reinicio del mismo contenedor).
- **El pub local no da invites** («Server has no public ip address»): anuncia `localhost`. No es
  una regresión. Trampa nueva en `AGENTES.md` §4.
- **El edge local intenta sacar certificados reales** al arrancar `oasis-pub-web` con el
  `Caddyfile` de la instancia: falla (no es el host), pero conviene no dejarlo corriendo.
- **Proceso huérfano**: cortar una tarea no mata a sus hijos; el primer diff de comportamiento
  siguió vivo dos horas. Se paró a mano.
- En la máquina de ensayo hay 49 GB de imágenes y 36 GB de caché de build de Docker.

## 9. Correcciones al protocolo

Aplicadas en `68e22ddc`: `UPGRADE-PROTOCOL.md` §0.2 (piezas nuevas), §0.5 (cambio de motor), §2
(`src/base`, segundo edit de `backend.js`, invariantes), §3.3, §3.4 (UM, UR, US; la medida lee dos
formatos), §4 (convergencia de la deriva, ensayo de migración, parada y copia en frío, `core.eol`),
§6 (rollback acotado), §7. `AGENTES.md` §1, §3 y §4. `HUB-PROTOCOL.md` §6, §12 y §13. `ECOIN`,
`RECOVERY`, `CLIENT`.

## 10. Seguimiento

- WP-O123: aplicación en el VPS. Empieza por traer y diferenciar los ficheros de build del host.
- Drill del cliente y `client:test-ai` antes de subir el cliente.
- Las ramas `wp/O119-medida-db2` y `upgrade/oasis-1.2.1` no están en `main` ni en el remoto.
