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

(pendiente)

## 5. Delta de publicación

(pendiente: local y host, por nodo)

## 6. Correcciones al protocolo

(pendiente; «ninguna» si no hubo)
