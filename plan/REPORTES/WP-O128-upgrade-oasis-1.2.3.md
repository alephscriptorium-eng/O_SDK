# WP-O128 · Upgrade a Oasis 1.2.3 en local

Rama `upgrade/oasis-1.2.3` (sobre `fix/upgrade-protocol-o127`) · 2026-10-07 ·
`OLD_REF=b1f7adfc` (1.2.2) · `NEW_REF=043f4634` (1.2.3, «Oasis release 1.2.3», 14:13 +0200 del
mismo día). Sin cambio de motor. **Aplicado en el host el mismo día** (§9) tras el ensayo local.

Antes del ciclo se corrigió el protocolo (WP-O127): `NEW_REF` por commit «release», audit de
parches de `node_modules`, instancia leída de `host.env`, seis cabeceras obligatorias en este
reporte. Este ciclo es el primero que las usa.

## 1. Estado de partida

Host (journal, 2026-10-05T18:27Z): pub en 1.2.2, `server+hub+wallet-engine-on+pub-snapshot-6h+phone-relay`.
No se corrió `deploy-status.sh` en esta sesión: el host entra en el reporte de aplicación.

Preflight (`upgrade-preflight.sh --from 1.2.2`), con `oasis-upstream/main` en `043f4634`:

```
LOCAL=1.2.2  UPSTREAM=1.2.3
DESPLEGADA=1.2.2  (journal, target=pub)   OBJETIVO=1.2.3
OLD_REF=b1f7adfc
NEW_REF=043f4634
Código que cambia por rol: pub en modo server = 7 de los 25 ficheros que carga · backends y cliente = 11024 (antes de separar activos) · dependencias vendorizadas (src/base) = 13
    pub: src/models/banking_model.js · peer_health.js · typed_log.js · workflows_model.js · src/server/network_pause.js · package.json · phone_module.js
Ciclo actual de red: 6 · caps.shs local coincide · nuestro pub: cycle=6 status=online
```

De los 11 024, 10 922 son teselas de mapa (`src/maps/tiles`: 5461 PNG borradas, 5461 JPG
añadidas; 24 → 32 MB), 9 cachés de mapa borradas y 8 GeoJSON nuevos (3,5 MB). Código: 90 ficheros
(`backend.js` +1354/−261, `long_text.js` nuevo, `pdf.js` +121, `middleware.js`,
`request_guards.js`, 21 modelos, 51 vistas, `server-config.json`). El preflight cuenta ahora los
activos aparte (WP-O127).

Línea base local (`upgrade-gates.sh --local backup pre123` con los nodos parados, arranque del
stack con la imagen `oasis-pub-scriptorium:latest` = 1.2.2, y `snapshot pre123` con los cinco
contenedores `healthy`):

```
== foto «pre123» (local) · 2026-10-07T12:42:56Z
  pub  running healthy  v1.2.2   server   log=db2 seq=11 registros=11 → cuadra · sbot=11
       tipos: contact=6 oasisVersion=5
  hub  running healthy  v1.2.2   backend  log=db2 seq=10 registros=10 → cuadra · sbot=10
       tipos: (cifrado)=1 about=2 contact=1 oasisVersion=5 pub=1
  bot  running healthy  v1.2.2   backend  log=db2 seq=24 registros=24 → cuadra · sbot=24
       tipos: about=4 contact=1 karmaScore=3 oasisVersion=5 pub=1 pubAvailability=7 ubiAllocation=2 wallet=1
       épocas=2026-09,2026-10 motor:pub=true
```

Como en el host: motor del bot encendido, época de octubre abierta (`ubiAllocation` debe quedar
en 0). Imagen vieja etiquetada `oasis-pub-scriptorium:1.2.2-vieja` (`8e277c0e06ec`).

## 2. Qué se entregó

| Commit | Pieza |
|---|---|
| `ada17d6e` | WP-O127: preflight (`--to`, release, `target=pub`, activos aparte), `upgrade-patches-audit.js`, sección `patches` y cabeceras en el `--check`, `lib-node.sh` con `REMOTE_DATA_ROOT`, claves opcionales de `host.env`, protocolo y trampas |
| `46bfdc4d` | overlay de `src/` desde `043f4634`, con `scripts/patch-node-modules.js` de upstream |
| `70f477be` | guards repuestos (solo `backend.js` había cambiado: dos edits sobre anclajes idénticos a 1.2.2) |

Invariantes del overlay (§2):

```
$ git diff 043f4634 --stat -- src/
 src/backend/backend.js | 12 ++++--------      src/backend/updater.js | 4 ++--
 src/configs/blockchain-cycle.json | 4 ++++    src/configs/snh-invite-code.json | 2 +-
 src/server/ssb_config.js | 23 +++++-          src/views/settings_view.js | 4 +---
 6 files changed, 34 insertions(+), 15 deletions(-)
$ git diff 043f4634 --stat -- src/base                       → vacío
$ git diff 043f4634 --stat -- scripts/patch-node-modules.js  → vacío
$ git ls-files -s src/server/node_modules                    → 120000
$ node --check src/backend/backend.js                        → ok
$ grep -m1 version src/server/package.json                   → 1.2.3
$ node devops/scripts/upgrade-patches-audit.js 043f4634
  aplicado=3 silencioso=6 pendiente=0 sin-anclaje=0 ausente=1   (exit 0)
```

El audit **antes** del overlay (script de 1.2.3 sobre el árbol de 1.2.2) daba 3 `pendiente`:
`ssb-conn/lib/conn-scheduler.js`, `ssb-gossip/index.js` (preferencia de dirección) y
`ssb-box/format.js`; son los tres ficheros que upstream cambió dentro de `src/base` en el commit
de 1.2.3. Tras el overlay, 0. El `ausente` es `src/AI/node_modules/@xenova/…` (se instala en el
build con `OASIS_AI=nav|full`; el `Dockerfile` corre el parcheador ahí).

## 3. Disposiciones del diff de comportamiento

`upgrade-behaviour-diff.sh b1f7adfc 043f4634` → `devops/logs/upgrade/diff-123.tsv`: 196 líneas,
129 a disponer. `annex`: 49 invariantes, ninguno roto (`db2`, `ecoin`, `hub`, `phone`).
`patches`: 10 parches de upstream, 0 pendientes tras el overlay (§2). Primer diff con la sección
`files` colapsando activos: la primera pasada emitía una línea por tesela y no terminó (§7).

**roles** (`9f6ad872 db75a40c ad3e9c63 0dfe1974 a7b2b8f1 aba81af3 46f6e16c`): 7 de los 25
ficheros que carga el pub. Leídos: `network_pause.js` (+94) rankea pares por versión y
grafo (`messagesByType('oasisVersion')` cada 10 min, `friends.graph`) y alterna entre dirección
normal y `.onion` cuando una falla: **solo lectura, no publica**; `peer_health.js` (+38) y
`typed_log.js` son índices; `phone_module.js` (+252) añade buzón de voz, aviso de sala y
`opusscript` (códec wasm, `require` opcional): graba audio **en el nodo llamado**, sin `publish`
en todo el fichero; `workflows_model.js` (2 líneas); `banking_model.js` abajo. → **gate U3**
(`pub:oasisVersion=+1` y nada más) y U6 invite (cambian `ssb-conn`, `ssb-gossip`, `ssb-box`).

**files** (`7c4df7de 96971fa6 8f9ba729 6ba1cf48 8338faff 31c17203 2737f850`): `long_text.js`
(troceo de textos largos en varios mensajes: **GUI**, lo dispara quien publica), mapas
reescritos de PNG generados con Python a SVG con teselas JPG y GeoJSON vendorizados; `cache/` y
las PNG viejas se van con el overlay limpio (`git rm -r src`). `no-afecta` a pub, HUB y bot; en
la imagen entran 32 MB de JPG que las PNG no entraban (`.dockerignore` excluye `*.png`).

**routes** (15): `b3e99589 da9f88e4 b7fa9387 5786a1fa 1ac673f3 457e9291 f80e87d2` son siete
GET de detalle bajo `/c/` (calendars, campaigns, emergencies, housing, maps, rooms, tribe): salen
al clearnet por la `location` genérica `^/(c|clearnet)` de `nginx.conf.template`, sin tocar la
plantilla ni el edge → **gate U4** (`hub --strict`, y se piden las siete a mano: 200 o 404 según
haya contenido, nunca 500). Sala 04 del sitio: tipos nuevos, pendiente (§8). `ae326af5`
(`GET /maps/:id/pdf`) no está bajo `/c/`: no sale. `caf8083c da4dbd7e c327413a 2b9d7b46`
(POST de borrado) publican `tombstone`; `a838af35` (`POST /clearnet/item/:id`) publica
`clearnetItem`; `32f339fc 656fa53a` (compartir mapa, alcance de contenido de tribu): **acciones
de GUI** tras `isLoopbackRequest` o formulario, nada las dispara solo → `no-afecta` a HUB y bot;
en el cliente son botones nuevos (CLIENT §4).

**publish** (43 IDs: `00b83734 046bde62 081b921c 089eef74 129a6ab2 21d25b6a 238ff82d 25d457d2
2d644586 317772f2 32a25c00 34cd218b 37f94d40 38433d0b 392058fc 3ada0e46 461b9f43 56b0f2a6
5afd07cc 63d2dad4 77f23a9b 7b767d95 7e60247b 85467a7b 9539aa23 97dfbebb a7b98fcb abfaf8f1
c57671e3 c5aaa591 c8aadbac c8abcd9d cdfe68ad d38e42c9 d8843550 de9d3097 e81e65ce ea3b635e
eeba20be effc578a f2ee3aaa f72f0a37 fee675c9`):

- **`cdfe68ad` + `e5a96064`/`1b9b992f` (timers): `syncClearnetSince()`.** A los 3 s de arrancar
  un backend **no público**, lee sus `visibilityPrefs`; si existen y no llevan `clearnetSince`,
  publica **un `about`** con los prefs actuales más esa fecha y deja un marcador
  (`clearnet-since.json`). El bot tiene prefs desde 1.2.2 (`phone: off`): **publicará un `about`
  al subir, una vez**. El HUB es público: no lo ejecuta. El cliente, si tiene prefs. Leído, y se
  **mide**: → **gate U3** con `bot:about=+1` declarado. En el host, GO-4a lo lleva escrito.
- `77f23a9b`, `7b767d95`, `d38e42c9` (`clearnetItem`, `tombstone`): acciones de GUI (rutas de
  arriba). `no-afecta`.
- `f72f0a37 081b921c effc578a c8aadbac c8abcd9d 34cd218b 38433d0b 3ada0e46 461b9f43`
  (`publishTribeExposure`, `tribes_content_model`): alcance de contenido de tribus, desde
  formularios. `no-afecta`.
- `392058fc 089eef74 129a6ab2 00b83734 abfaf8f1 56b0f2a6` (`long_text`, `mailing`, `pm`):
  troceo de textos largos al publicar o enviar privado; misma acción, más mensajes si el texto
  pasa del límite. Los avisos automáticos del backend siguen silenciados (`inboxMutedBots`):
  → **gate U3/U5** (`(cifrado)` = 0).
- `5afd07cc 317772f2 7e60247b a7b98fcb 238ff82d c57671e3 85467a7b 37f94d40 ea3b635e 32a25c00`
  (`banking_model`): reclamaciones de RBU (`publishUbiClaimResult`, `publishBankClaim`,
  `publishUbiTransfer`) reordenadas, mismo flujo a petición de un reclamante; `publishPubAvailability`
  es la misma línea movida. En el bot con motor encendido lo que se publica solo sigue siendo
  `pubAvailability` (+0..1) → **gate U3/U5** (`ubiAllocation` = 0 con la época abierta).
- `25d457d2 fee675c9 21d25b6a c5aaa591 d8843550 de9d3097 046bde62 63d2dad4 e81e65ce 2d644586
  eeba20be f2ee3aaa 97dfbebb 9539aa23` (blog, forum, main_models, comentarios, PM): refactor
  (`seal`, `publishErrorText`, `try/catch`) de publicaciones que ya existían, todas desde la GUI.
  `no-afecta`.

**timers** (`0824d194 2d52c249 2f0dcf78 339c9ad1 47e723f3 4f7d334b 50431717 54016f1a 5916f9b8
70ea8850 a3217256 b1a8d440 be715ecb ec033c19`; `1b9b992f e5a96064` arriba): `network_pause.js`
(ranking cada 10 min, escucha del hub de conexiones) y `phone_module.js` (timbre, buzón, sala):
no publican. `banking_model` sube el timeout del RPC por método; `phone_model` reintenta la
suscripción. `no-afecta` (coste: medir CPU del pub a las 24 h en el host, `capacity.sh`).

**env** (`e0114d5c`): `OASIS_MAP_TILES` (ruta de teselas) nueva; ningún compose la define:
default de upstream. `no-afecta`.

**config** (`cfdb04b9 94fe47d5 3227a211 9ecab6c9 cc8eaf15 0f505645`): `server-config.json`
abre `connections.outgoing.onion: [{transform: shs}]` (marcar `.onion` de otros pubs). Orden de
fusión en `ssb_config.js` (guard): `~/.ssb/config` ← `server-config.json` ← override. Los tres
nodos del pub montan `OASIS_SERVER_CONFIG_OVERRIDE=/home/oasis/.ssb/config`, su `ssb-config`
lleva `"onion": []` y `mergeDeep` sustituye arrays enteros: **pub, HUB y bot siguen sin salir por
Tor** (no hay proxy Tor en el stack). `documentado` aquí y en HUB-PROTOCOL §5.2; **DECISIÓN del
custodio** si algún día se quiere: añadir el elemento a `pub/config/ssb/config` y proxy. El
cliente (`docker-compose.yml`) no tiene override: hereda el default y marcará `.onion` sin Tor
(falla y alterna a la dirección normal: `tryOtherAddress`) → drill del cliente (§8).

**deps** (`e9ea88bd d4328350 1dab3462 546d72ef`): versión; `opusscript` (wasm, sin binario
nativo) y 13 ficheros en 5 paquetes vendorizados (`lodash`, `opusscript`, `ssb-box`, `ssb-conn`,
`ssb-gossip`: los tres `ssb-*` son los parches de upstream ya aplicados). → gate U2 (el build
carga el núcleo) y U6 invite.

**outside**: `e502d18e` (`.gitignore` de upstream quita `src/maps/cache/`; el del fork no la
tiene) `no-afecta`; `65c44fee` (`install.sh`: espejo de modelos) bare-metal, `no-afecta`;
`afc2198e` + `b7ade88a` (`patches`): `adaptado` en `46bfdc4d` (copia sincronizada, audit 0
pendientes); tests de upstream (`0c33296f 0d4fbf70 253e341f 289dd69f 2e7ce600 4a0683a8 4f1ccd7c
52d9d3fe 57190f53 5e7baf16 807d2a51 882e0d16 9c90040a a34a372c b00767c0 bdadcc72 dc5afb84
e039b630 eb0d23c5`): el fork no los ejecuta, `no-afecta`.

```
$ bash devops/scripts/upgrade-behaviour-diff.sh b1f7adfc 043f4634 --check plan/REPORTES/WP-O128-upgrade-oasis-1.2.3.md
# 196 líneas; 129 piden disposición en el registro del ciclo (signo + - !)
# todas las líneas tienen disposición en plan/REPORTES/WP-O128-upgrade-oasis-1.2.3.md y el registro lleva las seis cabeceras   (exit 0)
```

## 4. Qué viaja al host

- `src/` entero (con `src/base` y las teselas JPG: 32 MB más que antes; `git archive -c core.eol=lf`).
- `scripts/patch-node-modules.js` (sincronizado; lo corre el `Dockerfile` solo con IA).
- `.dockerignore`: excluye `ARCHIVO/**` (en la máquina operadora entraba un kit de instalador de
  205 MB en el contexto de build; en el host, converger in place si hay deriva).
- **Nada más**: `oasis-config.json` del HUB y la plantilla del bot salen «al día» de
  `regen-node-configs.js`; los `ssb-config` de los nodos no cambian (DECISIÓN de arriba: sin
  Tor); `nginx.conf.template` y `Caddyfile` no cambian (rutas nuevas bajo el prefijo que ya
  enrutan).

## 5. Gates

Stack local (`pub/docker-compose.pub.yml` + `pub/.env.local`, `volumes-dev/`, identidades
desechables), 2026-10-07, `G="bash devops/scripts/upgrade-gates.sh --local"`.

| Gate | Comando | Resultado |
|---|---|---|
| **U0** línea base | nodos parados · `$G backup pre123` (670 K) · `up -d --no-build` de pub, web, HUB, caché, ecoind y bot con la imagen 1.2.2 · `$G snapshot pre123` | tres nodos `healthy`, `seq = registros = sbot` (pub 11, HUB 10, bot 24); motor `pub=true`, épocas `2026-09,2026-10` (§1) |
| **U1** árbol | §2 · `annex` · `patches` · `--check` | 6 ficheros · 49 invariantes sin `!` · 10 parches sin `pendiente` · `--check` sale 0 con 129 IDs dispuestos y las seis cabeceras |
| **U2** imagen | `docker tag …:latest …:1.2.2-vieja` · `compose build oasis-pub` (`OASIS_AI=none`) · humo | build limpio, `nucleo vendorizado: carga en node v22.23.3`; 1,6 GB (`a7508c3db6c8`; la vieja 1,58 GB); dentro: versión 1.2.3, `node --check` de `backend.js` y `phone_module.js`, ningún `.env*` en `/app/pub`, sin `/app/ARCHIVO`, `/app/src/maps` 47 MB |
| **U3** recrear y medir | `$G up pub` · `$G up hub` · `$G up bot` · `$G check pre123 --expect 'pub:oasisVersion=+1 hub:oasisVersion=+1 bot:oasisVersion=+1,about=+0..1,pubAvailability=+0..1'` | `healthy` a los 10 s (pub), 50 s (HUB), 50 s (bot). Delta: **`oasisVersion+1` por nodo y nada más** → `GATE OK`. Parches del entrypoint: `ssb-ref` y `multiserver` «patcheado», `ssb-blobs` «ya parcheado», ninguno «no se encontró». La primera declaración (`about=+1` en el bot, por lectura de `syncClearnetSince`) dio DESVIACIÓN por defecto: §5.1 |
| **U4** visor | `$G hub --strict` · las 7 rutas nuevas por la caché | `GATE OK` (10 comprobaciones: 200, MISS→HIT, una CSP, idioma independiente del visitante, `?lang=`, 16 concurrentes sin cruce, `?type=files`, sitemap y RSS https). `/c/{calendars,campaigns,emergencies,housing,maps,rooms,tribe}/x` → 200 por la caché; `/c/maps`, `/c/rooms`, `/c/tribes` → 404 (no hay listado). Sin tocar `nginx.conf.template` |
| **U5** peor caso del bot | `$G snapshot u5` · `$G worst` · `$G check u5 --expect 'bot:karmaScore=+0..1,about=+0..1'` | `/banking` 200; `/transfers` 302 → `?filter=all` (canónico), `/shops`, `/market`, `/school` 302. **Δseq = 0 en los tres**: `wallet` y `(cifrado)` no se mueven, misma dirección. `GATE OK` |
| **U6** invite (completo por primera vez) | `$G snapshot u6` · `invite.create({uses:1, external:'gate.example.org'})` en el pub, host → IP del bridge · desechable `docker run --network <red> -e OASIS_SNAPSHOT=off <imagen> backend` · `ssb-probe.js` `invite-accept` · `$G check u6 --expect 'pub:contact=+1 hub:=0 bot:about=+0..1'` | desechable en 1.2.3 con los tres parches; `accept: true`, pub `connected` como par; **pub `contact+1`**, HUB y bot 0 → `GATE OK`. Receta ahora en UPGRADE §3.4 |
| **US** snapshot | `$G snapshot us` · `pub-snapshot.sh --local status` · `--local build` · `$G check us` | «cada 6 h, dentro del contenedor»; build `{"ok":true,"messages":51,"feeds":5,"boxed":3,"bytes":12851,"ms":307}`; el desechable con el interruptor no hizo bootstrap; Δseq = 0 en los tres → `GATE OK` |
| **U7** repetible | `compose stop` de los tres · `$G restore pre123 --yes` · `render-wallet-bot-config.sh .env.local` · U3 otra vez | `restore` repone la copia; `stop` devolvió «did not receive an exit event» pero los tres pararon (143/143/137). Recreados: `healthy` a los 15/35/40 s. **Mismo delta que la primera vez** (`oasisVersion+1` por nodo, nada más) → `GATE OK` |

No aplican UM ni UR (no cambia el motor: `db2.tsv` en verde).

### 5.1 Hallazgo: el `about` de `clearnetSince` del bot no sale (y puede salir en cualquier arranque)

La disposición `cdfe68ad` (§3) decía que el bot publicaría un `about` al subir: `syncClearnetSince`
corre a los 3 s de arrancar un backend no público, y el bot tiene `visibilityPrefs` desde 1.2.2
sin `clearnetSince` (comprobado con la misma consulta de `backlinks` que usa el código: con los
índices calientes responde en 452 ms con los prefs). Medido: **no publicó** ni al subir ni en un
segundo arranque en la misma versión, y no existe el marcador `clearnet-since.json`. A los 3 s
los índices de db2 aún no responden, el `.catch(() => null)` se lo traga y el código no deja
marcador, así que **lo reintenta en cada arranque**. Consecuencias:

- se declara `bot:about=+0..1` en **cada** recreación del bot (y del cliente), también en la misma
  versión, hasta que salga una vez; el HUB no (público);
- §0.4 del protocolo («recrear en la misma versión no publica nada») tiene desde 1.2.3 esa
  excepción; corregido;
- en el host, GO-4a lleva escrito ese `about` (texto: los prefs vigentes más `clearnetSince`).

## 6. Delta de publicación

Local, por nodo, desde `pre123` (1.2.2) hasta el cierre de U7:

| Nodo | Esperado | Medido en U3 | Medido en U7 | Host (§9) |
|---|---|---|---|---|
| pub (`server`) | `oasisVersion` +1 | `oasisVersion` +1 (seq 11 → 12) | `oasisVersion` +1 | `oasisVersion` +1 (seq 19 → 20) |
| HUB (`backend --public`) | `oasisVersion` +1 | `oasisVersion` +1 (seq 10 → 11) | `oasisVersion` +1 | `oasisVersion` +1 (seq 15 → 16) |
| bot (`backend`, motor encendido) | `oasisVersion` +1, `about` +0..1, `pubAvailability` +0..1 | `oasisVersion` +1 (seq 24 → 25); `about` +0, `pubAvailability` +0 | `oasisVersion` +1; `about` +0, `pubAvailability` +0 | `oasisVersion` +1 (seq 65 → 66); `about` +0, `pubAvailability` +0 |

Además, en U6 el pub publicó el `contact` del invite (esperado, solo si se usa) y en U5/US nadie
publicó nada. `ubiAllocation` y `(cifrado)`: 0 en todo el ciclo, en local y en el host. **Mismo delta en el
host que en local.**

## 7. Correcciones al protocolo

Aplicadas en esta rama (además de WP-O127, que fue antes del ciclo):

1. **`upgrade-behaviour-diff.sh`, sección `files`**: una línea por tesela (10 922) no es
   información y, con ~6 procesos por línea, el script no terminaba en Windows (es el «proceso
   huérfano dos horas» de WP-O120 §8). Los activos (`src/maps/{tiles,cache,data}`,
   `src/client/assets`) se colapsan en una línea por carpeta y signo con el recuento: de más de
   una hora a 17 s.
2. **§0.4 y §3.4**: el `about` de `clearnetSince` (§5.1): `bot:about=+0..1` en cada recreación.
3. **§3.4, U6 en local**: receta del invite completo con nodo desechable (antes «parcial: solo
   modo host»).
4. **`AGENTES.md` §4**: `MSYS_NO_PATHCONV=1` delante de cada `docker exec` a mano (sin él, «could
   not connect to sbot» en las tres sondas y pareció un fallo de 1.2.3); exportada en la sesión
   rompe el `curl` del gate `hub` (todo `000`), como ya anotó WP-O124.
5. **`.dockerignore`**: `ARCHIVO/**` entero fuera del contexto de build (un kit de instalador
   con `.deb` de 205 MB, ignorado por git y no por Docker, iba a entrar en la imagen).
6. **HUB-PROTOCOL §5.2**: la fusión de `server-config.json` y la DECISIÓN de Tor (§3, `config`).

7. **`test-invite.sh`**: llevaba `/app/pub/tools` fijo; en el host la carpeta del compose es `OASIS_PUB/` y
   el canario del invite fallaba desde WP-O123 (que lo probó a mano). Ahora deriva la ruta de
   `REMOTE_REPO_DIR` (`REMOTE_TOOLS_DIR` para forzarla).

Tropiezos de herramienta sin corrección (anotados): Docker Desktop respondió «tried to kill
container, but did not receive an exit event» al parar los nodos en U7 (pararon igual: pub y HUB
con 143, el bot con 137, como en WP-O124); el CLI de Docker tarda hasta 30 s por orden en esta
máquina y un `docker ps` filtrado puede salir vacío a medias. En el host: el clasificador de permisos
de la sesión (modo «auto») denegó toda escritura por shell remoto, también una orden sola; el ciclo
siguió al salir de ese modo. No es un defecto del protocolo (una orden por paso ya era la regla) sino
del modo de permisos con que se abre la sesión: un ciclo de host no se empieza en modo «auto».

## 8. No medido / pendiente

- **Cliente** (`docker-compose.yml`, modo `full`): drill de CLIENT §5 y `client:test-ai` con
  `OASIS_AI=full`; en 1.2.3 el cliente hereda `outgoing.onion` (sin override) y puede publicar el
  `about` de `clearnetSince` si tiene prefs. Journal con `--target client` (nuevo).
- Sala 04 del sitio: **hecho** el 2026-10-07 (23 tipos y nota de 1.2.3; el vivo era igual al repo por
  sha256 y se sustituyó in place, `685d5a48…`). HUB-PROTOCOL §1 al día.
- Tor: **decidido** por el custodio el 2026-10-07: no; `onion: []` en los tres nodos del pub.
- Cliente: el custodio decidió no subirlo en este ciclo; sigue en 1.2.2.
- Phone: una llamada real por el pub (pendiente desde WP-O124); buzón de voz nuevo en 1.2.3, sin
  probar.
- `capacity.sh` a las 24 h en el host: `network_pause.js` barre `oasisVersion` cada 10 min.
- Backups de ciclos anteriores en `/srv/oasis/*.bak-o106..o124*.tgz` y `*.cold-o123*` (≈4,5 GB): sacarlos
  a almacenamiento cifrado fuera de la máquina y retirarlos (pendiente desde WP-O123).
- Medida a las 24 h en el host (`capacity.sh`, memoria del pub con el ranking de pares).
- El stack local queda **encendido** en 1.2.3 (tres nodos, caché, ecoind, web, panel).

## 9. Aplicación en el host (2026-10-07, GO-1..GO-4b del custodio)

Una orden por paso (§4 del protocolo). Estado de partida medido: pub, HUB y bot en 1.2.2 `healthy`,
imagen al día, directorio en verde (ciclo 6), deriva solo en `.dockerignore`, 6 restos de rollback,
`/` 54 %, `/srv/oasis` 36 %. Foto `pre123` (remote, 16:49Z): pub 19 · HUB 15 · bot 65, los tres
`seq = registros = sbot`; motor `pub=true`, épocas `2026-09,2026-10`.

| # | Paso | Hecho | Puerta |
|---|---|---|---|
| 1 | Backups | pub → `devops/backups/oasis-pub/20261007T164923Z`; `wallet.dat` → `devops/backups/ecoin/20261007T165121Z` (81 920 B, sha256 `42915e8f…`) y, tras encender, `…/20261007T174217Z` (`062cb9d4…`); en el host `/srv/oasis/oasis-hub.bak-o128-2026-10-07.tgz` (813 MB, sin `http-cache`) y `oasis-wallet-bot.bak-o128-2026-10-07.tgz` (78 MB), 600; `.dockerignore.bak-o128-2026-10-07`. Deriva de `.dockerignore` convergida in place: solo se añaden las 4 líneas de `ARCHIVO/**` (diff con su `.bak`) | GO-1 |
| 2 | Disco | retirados `src.old-1.1.10`, `src.old-1.2.1`, `src-1.1.10.tgz`, `src-1.2.1.tgz`, imágenes `:1.1.10` y `:1.2.1`; `image prune` 0 B, `builder prune` 3,6 GB. `/` pasa del 54 % al 35 % | |
| 3 | Rollback | `oasis-pub-scriptorium:1.2.2` = `9b49a2cb36d6` (la `latest` de entonces) · `/srv/oasis/src-1.2.2.tgz` (99 MB, 600) | |
| 4 | `src/` | `git archive` con `core.eol=lf` de `upgrade/oasis-1.2.3` → `src.new` (324 MB, 24 918 ficheros + 1 enlace = 24 919 trackeados). Antes de cambiar: versión 1.2.3, 0 CR en `backend.js` e `is-map`, enlace a `src/base`, `ssb-db2` y `opusscript` vendorizados, dominio del pub en `snh-invite-code.json`, solo 4 JSON en `configs/`, 5461 teselas JPG. `test ! -e src.old-1.2.2 && mv …` | |
| 5 | Lo demás que viaja | nada (§4 del reporte) | |
| 6 | Build y humo | `compose build oasis-pub` → `84828fc054c6`, `nucleo vendorizado: carga en node v22.23.3`, `OASIS_AI=none`. Humo: 1.2.3, `node --check` de `backend.js` y `phone_module.js`, ningún `.env.prod` en `/app/OASIS_PUB`, sin `/app/ARCHIVO`, `src/maps` 47 MB; `server` y `backend` efímeros `running` con los tres parches en orden; `/c` → 200 | |
| 7 | Pub | 17:17:43Z `up -d --no-deps oasis-pub` → `healthy` a los 30 s. `check pre123 --expect 'pub:oasisVersion=+1'` → `GATE OK` (HUB y bot 0). Invite bien formado (canario del override; `test-invite.sh` corregido, §7). `/public/status` → 1.2.3 tras el TTL de 5 min del panel. 0 errores en el log | GO-2 |
| 8 | HUB | 17:22:58Z `up -d --no-deps oasis-hub` → `healthy` a los 60 s. `hub-disk.sh prune-cache` (1,2 GB → 0) · `hub --strict` → `GATE OK` (sitemap 167 URLs, RSS 30 + 3, todas https) · las 7 rutas nuevas 200 por Caddy → caché (MISS → cacheable, una CSP). `check` a los 5 min: `hub:oasisVersion=+1`, sin `about`. `hub-disk check` OK; 0 errores | GO-3 |
| 9 | Bot | 17:34:21Z `hub-wallet.sh pause` → 1.2.3 con `pub=false`, `healthy`, misma dirección `EYdruX…`, parches en orden. `check` a los 5 min: `oasisVersion+1`, `about` +0, `wallet` = 1, `(cifrado)` quieto. 17:40:35Z `hub-wallet.sh on --yes` → `pub=true`, «PUB engine on» = 1. `check` a los 5 min: `pubAvailability` +0 (último anuncio reciente, saldo 0), `ubiAllocation` 0 | GO-4a · GO-4b |
| 9b | Snapshot del pub | lo reconstruyó solo a los 2 min de arrancar: 17:19:48Z, 5601 mensajes, 92 feeds, 2,0 MB; «cada 6 h» | — |
| 10 | Cierre | `snapshot post123`: pub 20 · HUB 16 · bot 66, los tres cuadran. `deploy-status.sh`: tres nodos 1.2.3 `healthy`, imagen al día, `src/` 1.2.3, restos de rollback = los de este ciclo (3). `capacity.sh`: 0 avisos. Journal: `oasisVersion 1.2.3`, `gitSha 112f492a`. Ficha de instancia al día | |

Pub sin sbot ≈ 30 s; HUB ≈ 60 s; bot ≈ 2 × 50 s. Nada publicado con identidad real fuera de lo
declarado: **un `oasisVersion` por nodo**. Delta idéntico al del ensayo local.
