# WP-O141 · Upgrade a Oasis 1.3.0 (1.2.8 → 1.3.0; la 1.2.9 queda dentro del salto)

Rama `upgrade/oasis-1.3.0` desde `main` a732b7c7 (merge de WP-O140). 2026-10-15. Primer ciclo con el **protocolo v3**
(`docs/PUB/UPGRADE-PROTOCOL.md`, WP-O140): `check --wait`, `smoke`, `expect.conf`, `--check --from-tsv`, `start_interval`.
Cada tropiezo del protocolo se apunta en §6 y se corrige en este mismo WP.

## 1. Estado de partida

**Host** (`deploy-status.sh`, 2026-10-15, solo lectura):

- Journal: último registro `target=pub`, `oasisVersion=1.2.8`, `gitSha=bf5df0eb`, 2026-10-11T23:39:17Z.
- Piezas vivas: `oasis-pub-scriptorium` (server), `oasis-pub-hub` (backend), `oasis-pub-wallet-bot` (backend): los tres
  **1.2.8**, `running healthy`, «imagen al día». `src/` en disco del host: 1.2.8. Resto: `ecoin` (0.0.4-1, healthy),
  `hub-cache`, `panel-api`, `web`, y dos contenedores ajenos (`scriptorium-vps-*`).
- **Docker Engine del host: 26.1.5** (≥ 25: el `start_interval` del compose puede viajar).
- Deriva: `Dockerfile`, entrypoint, Caddyfile y las configs de HUB y bot **iguales que HEAD**. `.dockerignore`
  **DISTINTO y fuera de la historia del repo** (editado en el host: lleva `src.old*`, `src.new*`, `OASIS_PUB/.env.*`,
  WP-O138 §8 paso 4) y `pub/docker-compose.pub.yml` DISTINTO (versión d21fc7b8: el repo añadió `start_interval` en
  WP-O140). Los dos entran en «qué viaja al host» (§3).
- Restos de rollback del ciclo anterior: `/opt/oasis-scriptorium/src.old-1.2.5`, `/srv/oasis/src-1.2.5.tgz`, imagen
  `:1.2.5` (se retiran en el paso 2 del host).
- Directorio: ciclo 6, cap `H5EC+…`, `pub.escrivivir.co` **VERDE** (`status=online`). Disco `/` 39 %, `/srv/oasis` 38 %;
  `hub-disk`, `ecoin-disk` (`wallet.dat` 600) y `capacity` OK, 0 avisos.

**Preflight** (`upgrade-preflight.sh --to 1.3.0`, tras `git fetch oasis-upstream`):

```
LOCAL=1.2.8  UPSTREAM=1.3.0  DESPLEGADA=1.2.8  OBJETIVO=1.3.0
OLD_REF=28fc1a68  (Oasis release 1.2.8)      NEW_REF=37e0fc93  (Oasis release 1.3.0, 2026-10-14; 1.2.9 = 02bccc44 queda dentro)
pub en modo server: 6 de los 25 ficheros que carga · backends y cliente: 58 · activos: 19 · src/base vendorizado
  pub: updater.js, config-manager.js, state-manager.js, banking_model.js, phone_number.js, server/package.json
caps.shs local = cap actual de la red (ciclo 6): MANTENER (§5)
WARN x1 (el esperado: upstream por delante)  rc=1
```

`SSB_server.js` no cambia → **sin cambio de motor**: UM y UR no aplican. `updater.js` cambia y lleva un guard: se
repone a mano (§2).

## 2. Disposiciones

`upgrade-behaviour-diff.sh 28fc1a68 37e0fc93` sobre el árbol con los guards repuestos (6 min 36 s en Windows):
174 líneas, 90 piden disposición, `annex` 0 rotos (antes de reponer los guards daba 15, todos ellos los propios guards
y el fichero del quinto). Agrupadas por causa:

**Guards y árbol (§2).** `files -` b7b8884b `snh-invite-code.json` borrado por upstream y `files +` 3ddb1206
`invite-codes.json` → **adaptado** e932835f: el quinto guard pasa a la entrada 0 de `invite-codes.json`, solo `url`
(D-O22; nota fechada en el asiento). `patches +` b7ade88a (upstream cambió su parcheador) → **adaptado** 33039560
(copia sincronizada) y medido: `upgrade-patches-audit.js 37e0fc93` → `aplicado=9 silencioso=7 pendiente=0
sin-anclaje=0 ausente=1` (el ausente es `src/AI`, normal). `roles +` 11e046cb, 7bbaee7e, 9f6ad872, aba81af3, bd892fc9,
ea7cb03a (seis ficheros que carga el pub en modo `server`: `config-manager`, `updater`, `banking_model`, `package.json`,
`state-manager`, `phone_number`) → **gate** U2 (`SMOKE OK` en modo `server`) y U3 (el pub publica `oasisVersion` y nada
más). `deps -/+` 71e18e8d, a9e0af13 (versión 1.2.8 → 1.3.0) → **gate** U3 (`oasisVersion=+1` por nodo).

**Dependencias vendorizadas.** `deps +` cc0f043c (4 ficheros en 3 paquetes: `on-wakeup` detecta suspensión con
`hrtime`; `ssb-db2/compat/history-stream` ordena por llegada; `ssb-invite` añade el RPC `invite.list` y su manifest)
→ **no-afecta** a `create`/`accept` (el diff solo añade `list`, que consume `pub_invites`); el canario del invite del
pub (`deploy-status.sh`, §6) se mide en el host como siempre.

**Publicaciones nuevas o movidas.** `files +` f84f81a5 (`src/models/pub_invites.js`, modelo nuevo) y `publish +`
fbed3ce0 (`pub_invites.announce`: `ssb.publish({type:'pub-invites'…})`) con `timers +` af0f7e52 y 4e42069e (`announcePubInvites` a los 60 s del arranque y cada 24 h) → **gate** U3: corre
solo en un backend con `pub: true` en su ssb-config (el bot de cartera con el motor encendido; el HUB no, y el pub no
carga backend) y `announce()` no publica si el nodo no tiene invites creados (`!next.total`). **No se declara**: si el
bot publica un `pub-invites`, `check --wait` lo corta como desviación y la decisión es del custodio. `publish -/+`
03ae07eb → 82e2ea9f (el `contact` de seguir pasa a `followInhabitant`, POST de la GUI), 95470ae6 → cd4f5caa, 9782fe9b,
e1cfa741 (`publishTribeExposure` al cambiar el nivel de un objeto de tribu: acción de la GUI), bda566b8 → b06a34d1
(`publishProfileEdit`, `POST /profile/edit`), 24217a5f → 74b03ef1 y 27e55506 → 987e851c (`tribe-open-invite` y su
tombstone: mismo mensaje, refactor del marcador; TEMPLATE §9) → **no-afecta** a los nodos de soporte: nadie usa su GUI
(su único tráfico es el healthcheck a `/c/inhabitant/…`) y el bot de plantillas está deprecated (D-O36).

**Superficie HTTP.** `routes -` 1e2c6644, 2006fc20, 256b1fe2, 3ec8afc5, 4876d433, 544678fd, 71352841, 80e4e1b9,
95e84c35, 9c3971f1, aaa697bc, f341ba99 (doce `POST …/join-code`, `/welcome/wish`, `/invites/inhabitant/follow`
retirados) y `routes +` c40a8c56, e0aca29f, f68a53f9 (`POST /welcome/theme`, `/welcome/community`, `/invites/join`)
→ **no-afecta**: POST de la GUI, ninguna bajo `/c/`; el edge solo enruta `/c/*` al HUB (HUB §2). `loopback -`
cd5e4c8d (`GET /invites` deja de ser solo-loopback) → **no-afecta** por lo mismo (no sale por el edge) y el HUB
corre `--public`. `timers +` f4927743 (`socket.setTimeout` de `pubAnswers`, sondeo TCP a pubs sugeridos) →
**no-afecta**: solo lo dispara `suggestedPubs({probe:true})` desde `GET /invites` y el estado de `/welcome` (GUI).

**Cabeceras y cookies (D-O25).** `headers -` 1d56e8e5 (`lang` de `/welcome`), `headers +` 6bdfb773 (cookie `theme`
que fija `POST /welcome/theme`), `headers -/+` fb1f6832 → ee16cad1 (`Cache-Control: no-store` del bootstrap, misma
cabecera, otra línea) → **no-afecta** a `/c` (rutas de la GUI) y **gate** U4: `hub --strict` ya pide `/c` con
`Cookie: language=it; theme=Clear-SNH` y exige la misma página.

**Entorno y estado.** `env +` 5eddf10e (`OASIS_NETWORK_PAUSED` pasa a leerse también en el cálculo de `offline`,
`backend.js:305`) → **no-afecta**: ningún compose la define (`grep` vacío en `pub/docker-compose.pub.yml` y
`docker-compose.yml`). `state +` 06cd570a (`invites-used.json` en `content/`) → **documentado** aquí: estado nuevo que
un rollback de imagen no deshace (UPGRADE §6); en los nodos de soporte nace vacío.

**Fuera de `src/`.** `outside +` e502d18e (`.gitignore`), 67d375cc (`oasis.sh`), 2089d634 (`build-deb.sh`),
d998eb13 (`oasis-pub.js`), afc2198e (`patch-node-modules.js`, ya sincronizado) y los 18 `test/mods/*.test.js`
(0d4fbf70, 148eda3d, 2e7ce600, 3f6324c0, 45c6cbec, 574913e7, 7bca7c6a, 807d2a51, 8d8c3641, 917627f1, 9c90040a,
a34a372c, a8ecdb99, c27eb351, c8ad869e, dc5afb84, eb0d23c5, ed16397e) → **no-afecta**: camino bare-metal y tests de
upstream; el overlay no los trae (UPGRADE §2). `files +` 2e7812d6 (`src/client/assets/**`, 4 ficheros) →
**no-afecta**: estáticos de la GUI.

## 3. Qué viaja al host

- `src/` entero (1.3.0 + 7 guards), por `git archive` LF desde `upgrade/oasis-1.3.0` (§4 paso 4).
- `pub/docker-compose.pub.yml`: `start_interval: 3s` en pub, HUB y bot (WP-O140). Precondición medida: Engine 26.1.5.
  Sustituir in place tras `sha256` del vivo (la deriva es la versión d21fc7b8) y los nodos se recrean en el ciclo.
- `.dockerignore`: el del host llevaba a mano `src.old*`, `src.new*` y `OASIS_PUB/.env.*`; el repo las incorpora en
  este WP (`src.old*`, `src.new*`, `**/.env.prod*`) para que la deriva converja **hacia el repo**: in place antes del
  build (paso 1), y `smoke` lo comprueba (0 `secret`, 0 `.env*`).
- Nada más: ni plantilla nginx (ninguna ruta nueva bajo `/c/`), ni Caddy, ni configs de HUB/bot (`regen-node-configs`
  no cambia: `oasis-config.json` de upstream no trae claves nuevas que fijar — se comprueba en U1 con `annex`).

## 4. Gates U0-U7, UM, UR, US

Stack local sobre `volumes-dev/` (identidades desechables), `$G = upgrade-gates.sh --local`, 2026-10-15 13:56-14:10 UTC.
UM y UR no aplican (sin cambio de motor, §1).

| Gate | Comando | Salida |
|---|---|---|
| **U0** | `docker tag :latest :1.3.0-nueva` · `:1.2.8-vieja` → `:latest` · nodos parados · `$G backup pre130` · `compose up` · `$G snapshot pre130` | copia 3,1 MB; pub 15 · hub 14 · bot 30, los tres «cuadra · sbot=», v1.2.8; `healthy` a los 4 s / 0 s / 0 s. (El compose local lleva ya `start_interval`; la única diferencia con el desplegado es esa, inocua para la línea base) |
| **U1** | `git diff 37e0fc93 --stat -- src/` · `-- src/base` · `-- scripts/patch-node-modules.js` · `git ls-files -s src/server/node_modules` · `node --check` ×5 · `upgrade-patches-audit.js 37e0fc93` · `--check --from-tsv` | **7 ficheros** (113+/33−) · vacío · vacío · `120000` · ok · `pendiente=0 sin-anclaje=0` · «todas las líneas tienen disposición» (75 IDs, 2,5 s). `annex`: 0 rotos |
| **U2** | `compose build oasis-pub` · `$G smoke oasis-pub-scriptorium:latest` | imagen `1db4cf4c…` · `SMOKE OK`: 1.3.0, `node --check` ×3, enlace a `src/base`, **0 `secret`**, nada del fork en `/app`, `server` socket a los 2 s, `backend` `GET /c` 200 a los 2 s, 3 parches ×2, 0 errores ×2 |
| **U3** | `$G up pub` · `$G up hub` · `$G up bot` · `$G check pre130 --wait` | `healthy` a los 4 s cada uno, **23 s** en total · `GATE OK (delta esperado y sequence estable 60 s; 70 s en total)`: pub `oasisVersion+1` · hub `oasisVersion+1` · bot `oasisVersion+1`, **nada más** (ni `karmaScore`, ni `about`, ni `pub-invites`) |
| **U4** | `compose up -d --no-deps oasis-pub oasis-hub hub-cache pub-web` · `$G hub --strict` | `GATE OK`, 16 ok: MISS→HIT, una CSP, idioma «es» igual con de/es/fr y cookies, `?lang=`, **0 cruces en 18 peticiones de 6 idiomas**, `?lang=ar`, selector de tema, `?theme=` Clear/Matrix/desconocido, enlaces con `lang` (27) y `theme` (36), variante `?theme=` en caché, 0 cruces de tema en 9, `/c?type=files` 200, sitemap 13 URLs https, RSS feed/files https |
| **U5** | `$G snapshot u5` · `$G worst` · `$G check u5 --wait --expect 'bot:karmaScore=+0..1'` | 5 GET → 200 · `GATE OK` (71 s): los tres Δ0; `wallet` y `(cifrado)` quietos, misma dirección |
| **U6** | — | no aplica: `ssb-invite` solo añade `invite.list` (§2); el canario del invite se mide en el host (§6 del protocolo) |
| **U7** | parar · `$G restore pre130 --yes` · `render-wallet-bot-config.sh pub/.env.local` · `up` ×3 · `$G check pre130 --wait` | `healthy` a los 4 s ×3 (20 s) · `GATE OK` (70 s): **mismo delta que la primera vez** (`oasisVersion+1` ×3, nada más) |
| **US** | `$G snapshot us2` · `pub-snapshot.sh --local build` · `$G check us2 --expect 0` · `status` | `{"ok":true,"messages":216,"feeds":6,"boxed":5,"bytes":67818}` · `GATE OK`: los tres Δ0 (construir no publica) · snapshot de hace 0 h, reconstrucción cada 6 h |

Tiempo del camino feliz local (U0+U3+U5+U7, sin el build ni el diff): ≈ 6 min; en WP-O138 el mismo tramo rondaba los 20.

## 5. Delta de publicación

**Local** (U3 y U7, idénticos): pub `oasisVersion+1` · HUB `oasisVersion+1` · bot `oasisVersion+1`. Nada de lo declarado
como `+0..1` salió (`karmaScore`: los tres lo habían publicado hace < 24 h; `about`: el bot ya llevaba su `clearnetSince`;
`pubAvailability`: 12 h sin cumplir) y **el `pub-invites` nuevo no salió** (el bot local no ha creado invites: `total=0`).

**Host**: pendiente (§8).

## 8. Aplicación en el host (2026-10-15 UTC)

Una orden por paso (UPGRADE §4), parada ante cualquier salida distinta de la esperada. Estado de partida: §1 y foto
`pre130` (remote, 14:08:20Z): pub 1.2.8 `server` · HUB 1.2.8 `backend` · bot 1.2.8 `backend` (`pubAvailability=51`,
`ubiAllocation=16`, `wallet=1`), los tres `seq = registros = sbot`, arrancados hace 3,6 días.

| # | Paso | Hecho | Puerta |
|---|---|---|---|
| 1 | Backups | pub → `devops/backups/oasis-pub/20261015T141217Z` (archivo de `ssb-data`); `wallet.dat` → `devops/backups/ecoin/20261015T141604Z` (86 016 B, sha256 `1556c3b4…`, hot). En el host `oasis-hub.bak-o141-2026-10-15.tgz` (919 MB) y `oasis-wallet-bot.bak-o141-2026-10-15.tgz` (176 MB), root 600, `/srv/oasis` 41 %. `docker-compose.pub.yml.bak-o141-2026-10-15` y compose in place = blob de HEAD (`d9ff6862…`, 3 `start_interval`; el vivo era el blob de d21fc7b8 `1626b470…`, +7/−1 líneas frente a HEAD: `start_interval` y comentarios). `.dockerignore` del host **no se toca** (§6). **Tropiezo**: el guion del operador fijó como «esperado» otro blob y no paró ante el sha distinto antes de escribir; el `.bak` previo y el diff vivo→repo (solo líneas añadidas) lo cubrían | **GO-1** (solo paso 1) |
| 2 | Disco | 0 contenedores sobre `:1.2.5` → `rm` de `src.old-1.2.5` y `src-1.2.5.tgz`, `rmi :1.2.5` (`ca6c85a7`), `image prune` 0 B, `builder prune` 512 MB; `/` 39 % → 35 % | |
| 3 | Rollback | `oasis-pub-scriptorium:1.2.8` = `28b8db7a` (= `latest`) · `/srv/oasis/src-1.2.8.tgz` (94 MB, 600) | **GO pasos 2-4** |
| 4 | `src/` | `git archive` LF de `upgrade/oasis-1.3.0` → `src.new` (24 143 ficheros, 287 MB). Antes del `mv`: 1.3.0, 0 CR en `backend.js` e `is-map`, enlace a `src/base` + `ssb-db2`, 5.º guard (`url` de la entrada 0 de `invite-codes.json`), 6.º (4 + 2), 7.º (1), `blobs.max 50`, solo 4 JSON en `configs/`, `src.old-1.2.8` no existía. `mv src src.old-1.2.8` · `src/` = 1.3.0 | |
| 5 | Lo demás que viaja | nada (el compose ya está in place desde el paso 1; `.dockerignore` del host se conserva) | |
| 6 | Build y humo | `compose build oasis-pub` → `latest` = `e561a64f` (1,06 GB), `:1.2.8` = `28b8db7a`; `/` 39 %. `$R smoke oasis-pub-scriptorium:latest` → primera pasada **FALLA del gate, no de la imagen**: marcaba `/app/docs` (copia de la documentación de upstream del layout del host) y tres `.env*.example` que el `.dockerignore` del host re-incluye a propósito; el protocolo no pide excluir `docs/` ni los `*.example`. Gate corregido (§6) y repetido → **`SMOKE OK`**: 1.3.0, `node --check` ×3, enlace a `src/base`, **0 `secret`**, 0 `.env` reales, `server` socket a los 2 s, `backend` `GET /c` 200 a los 2 s, 3 parches ×2, 0 errores ×2. Los tres nodos siguen `healthy` en `28b8db7a` | **GO paso 6** |
| 7 | Pub (14:25:40Z) | `up -d --no-deps --no-build oasis-pub` → `healthy` a los **4 s** (imagen `e561a64f`; log: `Version: 1.3.0`, tres parches, sin errores). `$R check pre130 --wait --max 900 --expect 'pub:oasisVersion=+1 hub:karmaScore=+0..1 bot:karmaScore=+0..1,pubAvailability=+0..1'` (para HUB y bot, aún en 1.2.8, su `+0..1` vigente): primera foto a los 7 s NO MEDIBLE (seq 25, el sbot escribía), desde los 33 s `rc=0` con pub 26, `prematuro` hasta los 300 s de `--min-age` → **`GATE OK (… 319 s en total)`**: pub `oasisVersion+1`, HUB Δ0, bot Δ0. `/public/status` → `1.3.0`, `running`, `healthy`, invite público presente (121 caracteres, no copiado) | **GO-2** |
| 8 | HUB (14:32:27Z) | configs sin cambio (regen al día). `up -d --no-deps --no-build oasis-hub` → `healthy` a los **6 s** (1.3.0, tres parches, `Media cache limit: 2048 MB`, «Admin access» presente y no copiado, 93 MiB / 768). `$R check pre130 --wait` (delta vigente de los tres) → **`GATE OK` (296 s)**: pub `+1`, **HUB `oasisVersion+1`** y nada más, bot Δ0. `hub-disk.sh prune-cache` (2,05 GB → 0, `nginx -s reload`) · `$R hub --strict` contra `https://pub.escrivivir.co` → **`GATE OK`**, 16 ok: MISS→HIT, una CSP, idioma «es» estable, **0 cruces en 18 peticiones de 6 idiomas**, tema por `?theme=`, 165 enlaces con `lang` y 174 con `theme`, sitemap 180 URLs https, RSS 36 + 4 | **GO-3** |
| 9a | Bot (14:39:02Z) | plantilla sin cambio (regen al día): sin render. `hub-wallet.sh pause` → 1.3.0 con `pub=false`, `healthy` a los 0 s (tres parches, «Admin access» presente y no copiado, 165 MiB / 768); `hub-wallet status`: `wallet=1`, cartera `EYdruX…` (la misma), saldo 0, `ecoind` healthy. `$R check pre130 --wait --expect '… bot:oasisVersion=+1,karmaScore=+0..1,about=+0..1'` → **`GATE OK` (292 s)**: **bot `oasisVersion+1 karmaScore+1`** (declarado; 3,6 días sin publicarlo), `motor: pub=true → pub=false`, `wallet` y `(cifrado)` quietos, misma dirección; pub y HUB sin cambios desde su paso. **Sin `pub-invites`** | **GO-4a** |

## 6. Correcciones al protocolo

- **U4 en local necesita `pub-web` levantado, no solo `hub-cache`**: el puerto 8088 lo publica el edge local; con el
  edge parado todo da `000` y el gate falla por el stack, no por el HUB. La tabla de §3.4 lo dice ahora.
- **US exige los tres nodos de `GATE_NODES` en marcha** (el log db2 solo se lee con el contenedor arriba): con el bot
  parado, `check` da NO MEDIBLE aunque pub y HUB cuadren. Correcto, pero conviene decirlo en la fila de US.
- **El quinto guard cambia de fichero** (`invite-codes.json`, entrada 0): tabla de §2, comprobación de `src.new` en §4 y
  `pub.tsv` actualizados en este WP (45c6a5f0). La regla «guards cuyo fichero SÍ cambió se reponen a mano» cubría el
  caso, pero no el de un fichero **borrado y sustituido**: añadido a §2.
- **`smoke` era más estricto que el protocolo**: fallaba por `docs/` y por `.env*.example` en `/app`, que U2/§4 no
  prohíben (el host re-incluye los `.example` a propósito). El gate mide ahora lo que el protocolo dice: `.env*` sin los
  `*.example`, y sin `docs/` en la lista. `/app/docs` en la imagen del host es lastre, no secreto: hallazgo para E0.
- **La deriva de `.dockerignore` no es convergible mientras el host tenga otro layout** (`OASIS_PUB/` ≠ `pub/`): el del
  host es el correcto para su raíz y ya cumple §4; `deploy-status` lo marcará DISTINTO hasta la migración (E0). El paso 1
  del protocolo debe decir «converger **si el layout es el mismo**; si no, comprobar que el del host cumple §4».
- **«Un comando por paso» también vale para el operador.** En GO-4b encadené `hub-wallet.sh on --yes` → `check --wait` →
  backup → `snapshot post130` → **journal** → `deploy-status` en un solo guion. El `on` **abortó en precondiciones** (el
  pub no veía al bot conectado) pero el guion siguió: el `check` salió verde (el estado era el de 9a, legítimo) y el
  journal registró `wallet-engine-on` **con el motor apagado** (14:48:18Z). Detectado al leer la salida parcial; la
  tarea se detuvo (ya tarde) y el journal lleva desde las 14:53:34Z una línea correctora `wallet-engine-off`. El
  journal es `devops/logs/deploy-history.jsonl` (local, fuera de git). Regla para §4: tras cualquier orden que **pueda
  abortar por precondición** (`hub-wallet.sh on`, `pause`), el siguiente paso espera a leer su salida; el journal se
  escribe solo tras el `check` del estado **real**.
- **La precondición «el pub lo ve conectado» de `hub-wallet.sh on` destapó un problema previo al ciclo**: el sbot del
  bot llevaba sin conectar con nuestro pub desde 2026-10-14T23:02Z (`conn.json`: `stateChange`, `failure: 0`,
  `autoconnect: true`) mientras mantenía cuatro pubs externos (`conn.peers()`); el HUB sí reconectó en 5 s tras cada
  recreación. TCP del bot al pub en orden (`connect ok 172.18.0.4`). `snapshot`/`check` no lo ven: miden lo publicado,
  no la conectividad. Hallazgo para el backlog: que `hub-wallet.sh status` (o la foto) diga a qué pares está conectado
  cada nodo de soporte, y mirar el planificador de `ssb-conn` (`maintainConnections(quota…)`, `MAX_STAGED_PUBS = 3`).
- **`.dockerignore` del repo** no tenía las reglas que §4 exige al del host (`src.old*`, `src.new*`, `.env.prod*`):
  el repo las lleva desde este WP y la deriva converge hacia el repo.
