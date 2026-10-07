# Protocolo de upgrade de Oasis (fork dockerizado)

> **Este repo es el sitio del upgrade** (`C:\S_LAB\o-sdk`,
> `https://github.com/alephscriptorium-eng/O_SDK.git`). No uses
> `BlockchainComPort` ni `alephscript-network-sdk` (archivado).

Subir el fork a una versión nueva de upstream (`epsylon/oasis`) sin perder identidad, sin publicar
nada que no esté previsto y sin romper las piezas que el fork ha puesto alrededor. Este protocolo
**orquesta**: dice qué se mide, en qué orden y con qué puerta. Lo particular de cada pieza vive en
su anexo (`HUB-PROTOCOL.md` §5, `ECOIN-PROTOCOL.md` §5, `../CLIENT-PROTOCOL.md` §4).

Deriva de los ciclos 0.8.3→0.8.8, 0.8.8→0.9.6, 0.9.6→1.0.8, 1.0.8→1.1.2, 1.1.2→1.1.4,
1.1.4→1.1.10, 1.1.10→1.2.1, 1.2.1→1.2.2 y 1.2.2→1.2.3. Se reescribió en el ciclo 1.1.4→1.1.10 (WP-O112) porque el protocolo anterior comprobaba bien
lo barato —que los guards de `src/` siguen puestos— y no comprobaba lo caro: que Oasis **se
comporta** igual. Sus greps decían «esto sigue existiendo», no «esto sigue haciendo lo mismo».

| Paso | Qué | Dónde | Puerta |
|---|---|---|---|
| §0 | Qué se sube, qué hay desplegado | host (lectura) | — |
| §1 | Preflight: de qué versión a cuál | repo | — |
| §2 | Overlay de `src/` + guards | rama `upgrade/oasis-X.Y.Z` | invariante de 6 ficheros |
| §3 | Qué cambia de comportamiento; derivados; gates locales | repo + Docker local | gates U0-U7 |
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
| **pub** | `server` | el sbot: `src/server/SSB_server.js` **y lo que carga** (en 1.1.10, 15 ficheros: también `banking_model.js`, `state-manager.js`, `typed_log.js`) | dependencias `ssb-*`, `ssb_config.js`, y lo que el sbot hace solo al arrancar (anunciar versión; publicar dirección si tuviera cartera a mano). Es el único cuyo reinicio se nota en la red |
| **nodo de soporte** (HUB, bots) | `backend` | todo `src/`: sbot embebido + `backend.js` con identidad propia y, en un bot de cartera, dinero | todo lo que el backend haga **solo** al arrancar o por temporizador, y todo lo que publique |
| **cliente** | `full` | todo `src/` + GUI con una persona delante + IA | lo anterior, más cada botón nuevo que publique |

`upgrade-preflight.sh` (§1) dice qué ficheros cambian para cada rol. Para el pub no cuenta una
carpeta sino el **cierre de requires** de `SSB_server.js` (`devops/scripts/upgrade-closure.js`): en
1.1.4→1.1.10 cambian 6 de los 15 ficheros que carga el pub, y 73 para backends y cliente.

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
| maint-ui | backend sobre el `.ssb` **del pub** | — | **prohibida durante el ciclo**: todo lo que un backend publica solo lo publicaría con la identidad del pub | — | lo que publique un backend |
| ecoind | imagen propia | RPC | no se recrea en un upgrade de Oasis | `ECOIN-PROTOCOL.md` | — |
| cliente | `full` + entrypoint (`persist_client_state`, `wire_wallet_config`, `setup_oasis_config`) | forma de `oasis-config.json`, loopback, contrato de IA | drill del cliente | `../CLIENT-PROTOCOL.md` §4-§5 | `oasisVersion` +1; `wallet` si hay cartera cableada sin publicar |
| dependencias vendorizadas | `src/base/node_modules` (desde 1.2; entra con el overlay) + enlace `src/server/node_modules` que crea el `Dockerfile` | qué paquetes trae upstream, sus binarios precompilados, la versión de Node que declara | el build prueba que el núcleo carga; invariante `src/base` idéntico a upstream | §2, §3.3 | — |
| parches de `node_modules` | `apply_node_patches` del entrypoint, sobre `src/base` | versiones de `ssb-ref`, `ssb-blobs`, `multiserver`; qué trae ya parcheado upstream en lo vendorizado y qué parchea su `scripts/patch-node-modules.js` (que el fork no ejecuta sobre el repo) | `upgrade-patches-audit.js $NEW_REF` (sección `patches` del diff): ningún `pendiente` · log de arranque: cada parche del entrypoint dice «patcheado» o «ya parcheado», ninguno «no se encontró» | §2, §3.3 | — |
| snapshot del pub | `pub/tools/snapshot-build.js`, que lanza el entrypoint del pub cada `OASIS_PUB_SNAPSHOT_HOURS` horas (`pub-snapshot.sh` para mirar o forzar) | formato `OASISSN1`, ruta de `snapshot_plugin.js`, RPC `createLogStream` | gate US (§3.4) · `pub-snapshot.sh status` | `HUB-PROTOCOL.md` §13 | — (construir no publica) |
| centralita del pub (Phone y Rooms, desde 1.2.2) | clave `phone` del ssb-config del pub + `phone.relay = false` en HUB y bots (`regen-node-configs.js`) | de dónde lee el plugin su política, `relay`, `relayOpen`, `roomMax`, RPC `roomInfo` | `annex` (phone) · `phone.roomInfo` devuelve el aforo fijado | `HUB-PROTOCOL.md` §14 | — (retransmitir no publica) |
| medida de los nodos | `lib-node.sh`, `pub/tools/log-bipf.js`, `pub/tools/ssb-probe.js` | formato del log, texto de la guarda de migración, RPC `createUserStream` | `annex` (db2) · `snapshot` cuadra en las tres fuentes | §3.4 | — |
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
  versión es el titulado `Oasis release X.Y.Z`, y **los dos** se resuelven así. La versión de
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
git checkout $NEW_REF -- scripts/patch-node-modules.js           # la copia del fork sigue a upstream (abajo)
# Guards cuyo fichero upstream NO tocó entre OLD_REF y NEW_REF: se recuperan tal cual.
git diff --stat $OLD_REF $NEW_REF -- <fichero>                   # vacío → git checkout HEAD -- <fichero>
# Guards cuyo fichero SÍ cambió: se reponen A MANO sobre el fichero nuevo (tabla de abajo).
```

Por qué `git rm` antes del checkout: `git checkout <tree> -- src/` sobreescribe pero **no borra**.
Desde 1.1.3 eso es crítico: `src/configs/state-manager.js` **migra** al arrancar a `~/.ssb/oasis/**`
cualquier fichero de estado que encuentre en `src/configs/` o en `~/.ssb/`; un resto viejo acabaría
encima del estado real.

Nunca `git checkout HEAD --` de un fichero que upstream cambió: recuperar la versión vieja rompe el
árbol nuevo. En Windows el overlay sale **CRLF** en el árbol de trabajo (`autocrlf`): detecta el
EOL antes de un reemplazo literal.

**`src/base` (desde 1.2).** Upstream vendoriza sus dependencias en `src/base/node_modules` y deja
`src/server/node_modules` como enlace simbólico a ellas. Entran con el overlay y se versionan
enteras, tal cual:

- `.gitignore` las re-incluye al final (`!src/base/**`) y `.gitattributes` les quita la conversión
  de fin de línea (`src/base/** -text`). Comprobación previa al overlay:
  `git ls-tree -r --name-only $NEW_REF src/base | git check-ignore --stdin --no-index | wc -l` → 0.
- **Nunca `npm install` en `src/server`** (escribiría a través del enlace) ni
  `scripts/patch-node-modules.js` sobre el repo. El enlace lo crea el `Dockerfile`.
- Algunos paquetes traen su propio `.gitattributes` (`* text=auto`): en Windows unos pocos ficheros
  salen en CRLF pese a la regla. No rompe el invariante (git normaliza al comparar), pero obliga a
  subir `src/` al host con `-c core.eol=lf` (§4).

Commits: uno para el overlay (con los ficheros editados a mano **tal cual vienen de upstream**) y
otro para los guards repuestos. Así el diff de los guards se lee solo.

| Fichero | Qué reponer sobre el fichero nuevo |
|---|---|
| `src/backend/backend.js` | **Dos edits.** (1) En `.post("/update")`: conservar `isLoopbackRequest` y `safeRefererRedirect`; sustituir las dos `exec` (`git reset --hard && git pull`, `sh install.sh`) por el `console.warn` del fork. (2) Interruptor de snapshots (D-O27): `const snapshotsOff = process.env.OASIS_SNAPSHOT === 'off';` antes de `runSnapshotBuild`, y `|| snapshotsOff` en la primera condición de `runSnapshotBuild` y de `bootstrapFromPub` |
| `src/server/ssb_config.js` | `mergeDeep` en vez del spread (`config = mergeDeep(config, configData)`); bloque `OASIS_SERVER_CONFIG_OVERRIDE` antes de `const megabyte`; `blobs.max` = 50 MB. Conservar `config.statePath` y `config.db2` de upstream |
| `src/backend/updater.js` | Los dos `console.log("...new code updates are available!...")` pasan a ser el mensaje del fork. Conservar el fix de ruta con `__dirname` |
| `src/views/settings_view.js` | El `form({ action: "/update" })` pasa a ser el `p(...)` informativo |
| `src/configs/snh-invite-code.json` | **Solo `url`** = dominio del pub de la instancia (D-O22): base de los enlaces de «compartir en clearnet». El invite de upstream se conserva |
| `src/configs/blockchain-cycle.json` | fork-only (marcador de ciclo; se preserva) |

Eso es **todo** lo que puede divergir de upstream dentro de `src/`: 5 guards y un fichero propio.
Fuera de `src/` el fork se mantiene entero (nunca overlay): `Dockerfile`, `docker-compose*.yml`,
`docker-entrypoint.sh`, `pub/**`, `devops/**`, `client/**`. `install.sh`/`oasis.sh` son
bare-metal: sincronizarlos con upstream es opcional.

**`scripts/patch-node-modules.js` es de upstream y se sincroniza.** Es el script con el que
upstream parchea sus dependencias en bare metal (`install.sh`). El fork no lo corre sobre el repo
(solo el `Dockerfile` sobre `src/AI`, con `OASIS_AI=nav|full`), pero es la **lista de lo que
upstream espera parcheado**: desde 1.2 lo vendorizado en `src/base` suele traer ya cada parche, y
cuando no lo trae, un nodo del fork correría sin él mientras el de upstream corre con él. Por eso:
(1) la copia del fork se trae de `$NEW_REF` en el overlay; (2) se mide, no se lee:

```bash
node devops/scripts/upgrade-patches-audit.js $NEW_REF   # ejecuta el script de upstream EN SECO sobre src/base
```

Un parche `pendiente` es lo vendorizado sin el parche: o lo aplica `apply_node_patches` del
entrypoint (§3.3) en la misma rama, o se dispone por escrito por qué no. `sin-anclaje` es
upstream contradiciéndose (su parche no casa con su propia dependencia): se dispone igual.
`ausente` en `src/AI/**` es normal (la pila de IA se instala en el build). Los tres parches del
entrypoint (`ssb-ref`, `ssb-blobs`, `multiserver`) no se retiran porque upstream los traiga: son
idempotentes y el log de arranque sigue siendo la prueba (§3.3). En el ciclo 1.2.3 la copia del
fork era la de 1.2.1 y nadie lo había notado: el audit lo saca como línea `patches` del diff.

### Verificación de invariantes (bloqueante)

```bash
git diff $NEW_REF --stat -- src/                  # exactamente 6 ficheros
git diff $NEW_REF --stat -- src/base              # vacío: lo vendorizado es el de upstream
git diff $NEW_REF --stat -- scripts/patch-node-modules.js   # vacío: la lista de parches es la de upstream
git ls-files -s src/server/node_modules           # modo 120000: sigue siendo un enlace
node --check src/backend/backend.js               # el edit a mano parsea
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
| `patches` | el `scripts/patch-node-modules.js` de `NEW_REF` ejecutado en seco sobre el árbol de trabajo (`upgrade-patches-audit.js`) | un `!` es un parche que upstream aplica y lo vendorizado no trae (§2) |

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
| `client/scripts/*`, `docker-entrypoint.sh` | cambia el contrato de IA, la forma de `oasis-config.json` o los módulos parcheados | rebuild del cliente; el entrypoint del **host** es el suyo (§0.3, deriva) |

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
```

| Gate | Qué | Comando | Salida esperada |
|---|---|---|---|
| **U0** | Línea base **como el host**: stack local en la versión vieja, con cada pieza en el mismo modo que en §0.3 (motor encendido si allí lo está, época del mes abierta). Copia del estado | parar nodos · `$G backup pre` · arrancar · `$G snapshot pre` | tres nodos healthy en la versión vieja; `seq` = `registros` = `sbot` en los tres |
| **U1** | Árbol | verificación de §2 · `annex` · `--check` del reporte | 6 ficheros · ningún `!` · 0 IDs sin disponer |
| **U2** | Imagen nueva | etiquetar la vieja (`docker tag …:latest …:X.Y.Z-vieja`) · `npm run build` (o el build del compose del pub) | build limpio; `node --check` dentro de la imagen |
| **U3** | Recrear en orden pub → HUB → bot y medir **qué publica cada uno** | `$G up pub` · `$G up hub` · `$G up bot` · `$G check pre --expect '…'` | `GATE OK` con el delta declarado (abajo) |
| **U4** | Visor por delante de la caché | recrear `hub-cache` si cambió la plantilla · `$G hub --strict` | `GATE OK`: MISS→HIT, idioma independiente del visitante, sin cruce, rutas nuevas |
| **U5** | Peor caso del bot: las páginas donde el backend refresca la cartera por su cuenta (`/banking`, `/transfers`, `/shops`, `/market`, `/school`) | `$G snapshot u5` · `$G worst` · `$G check u5 --expect 'bot:karmaScore=+0..1'` | `wallet` y `(cifrado)` no se mueven; misma dirección. **`/wallet` queda fuera a propósito**: en cualquier versión, con el motor encendido, republica la dirección (`../AGENTES.md` §4) |
| **U6** | Gates propios de las piezas que el diff ha tocado | invite (`HUB-PROTOCOL.md` §3, si cambian `ssb-*`; en local, abajo) · bootstrap de un bot nuevo (`ECOIN-PROTOCOL.md` §3, si cambia la publicación de la dirección) · drill del cliente (`../CLIENT-PROTOCOL.md` §5) | los de cada anexo |
| **U7** | Repetible | parar nodos · `$G restore pre --yes` · **volver a renderizar** la config del bot (`restore` repone también la renderizada vieja, que vive en `volumes-dev/`) · repetir U3 | mismo delta que la primera vez |
| **UM** | Solo si cambia el motor (§0.5). Migración sobre una **copia** de cada nodo, sin red | copia de `volumes-dev/.gates/pre/<nodo>/ssb-data` · contenedor efímero `--network none` de la imagen nueva en modo `server` · contar antes (`FULL_SCAN=1 node client/scripts/lib/inspect-log-offset.js`) y después (`pub/tools/log-bipf.js`) | guarda presente, `db2/log.bipf` existe, mismo nº de autores, registros = los de antes **+1** (el `oasisVersion` propio), 0 borrados |
| **UR** | Solo si cambia el motor. No-retorno | la imagen **vieja** en modo `server` sobre una copia ya migrada | el contenedor se cae; la guarda y `db2/log.bipf` no cambian (mismo sha256) |
| **US** | Snapshot del pub | `pub-snapshot.sh --local build` · `$G check <tag>` · un nodo desechable pide el snapshot antes y después de aceptar un invite; otro, con `OASIS_SNAPSHOT=off` | construir no publica; sin invite: `not allowed`; con invite, el log del nodo salta en segundos; con el interruptor, no |

**El delta declarado (U3).** Lo normal:

```
--expect 'pub:oasisVersion=+1 hub:oasisVersion=+1 bot:oasisVersion=+1,pubAvailability=+0..1'
```

- `oasisVersion=+1` por nodo, **también el pub**. `+0` significa que no subió de versión (imagen
  vieja, o un estado que ya había pasado por la nueva: `restore` antes de repetir).
- En el pub, cualquier otra cosa es una desviación: algo arrancó un backend sobre su `.ssb`.
- `pubAvailability=+0..1` solo con el motor encendido: al arrancar relee su último anuncio y vuelve
  a anunciar si pasaron más de 12 h o cambió el saldo. Cada anuncio gasta una dirección del
  keypool: `backup-ecoin.sh` antes y después (`ECOIN-PROTOCOL.md` §9).
- **Al subir a 1.2.2, `about=+1` en HUB y en cada bot** (una sola vez): el backend público anuncia
  `visibilityPrefs.phone = "off"`. No sale al arrancar sino con el primer refresco de fondo tras
  atender peticiones, así que el `check` hecho justo después de recrear no lo ve: se declara como
  `about=+0..1` en ese `check` y como `about=+1` en el de cierre (`HUB-PROTOCOL.md` §14).
- **Desde 1.2.3, `about=+0..1` en el bot** (y en el cliente) en cada recreación, también en la
  misma versión (§0.4, `clearnetSince`). En el HUB no: es público y no corre esa sincronización.
- `ubiAllocation` no se nombra: debe ser 0. Solo es 0 si la **época del mes ya está abierta** antes
  de subir (`épocas=` en la foto). Si no lo está, la abriría la versión nueva con sus reglas:
  irreversible y distinto; decídelo con el custodio antes.

- `(cifrado)` no se nombra: debe ser 0. El backend trae avisos automáticos (el «bot político», el
  de empleo, recordatorios) que se disparan con cualquier petición, también la del healthcheck, y
  se envían **a sí mismos un mensaje cifrado**. En un nodo de soporte van silenciados por config
  (`inboxMutedBots`, desde 1.1.10; `HUB-PROTOCOL.md` §2). Si aparece un cifrado, esa lista está
  incompleta o el nodo corre una versión que aún no la entiende.

**U6 en local, invite completo (desde el ciclo 1.2.3).** `test-invite.sh` solo tiene modo host;
en local se hace con un **nodo desechable** de la imagen nueva, sin volúmenes, en la red del
compose: `$G snapshot u6` · invite de un uso en el pub (`invite.create({ uses: 1, external:
'<dominio.con.punto>' })` por `ssb-client` dentro del contenedor del pub) y reescribir el host a
la IP del pub en el bridge · `docker run -d --network <red del compose> -e OASIS_SNAPSHOT=off …
<imagen> backend` · `ssb-probe.js` con `SSB_ACTION=invite-accept` desde el desechable ·
`$G check u6 --expect 'pub:contact=+1 hub:=0 bot:about=+0..1'` · `docker rm -f` del desechable.
Salida esperada: `accept: true`, el pub como par `connected`, y el pub publica **exactamente un
`contact`**. El invite lleva semilla: no se imprime. Todo `docker exec` a mano desde Git Bash lleva
`MSYS_NO_PATHCONV=1` **solo en esa orden** (`../AGENTES.md` §4).

**Cuándo medir.** Un nodo no publica todo «al arrancar»: el sbot anuncia versión a los 7 s, el motor
hace su primer tick a los 15 s, y los avisos automáticos esperan a la primera petición con los
índices listos (más de un minuto). `upgrade-gates.sh up` espera 90 s con una petición en medio. En
el host, el `check` que cuenta es el que se hace **al menos 5 minutos después** de recrear el
último nodo, y se repite en el cierre (`snapshot post`).

`check` exige además que el feed de cada nodo sea el mismo, que `Δsequence` == suma de Δ por tipo
(cifrados incluidos) y que el sbot vivo dé el mismo `sequence`. Si eso no cuadra responde
**NO MEDIBLE**: no es un verde.

**La medida lee los dos formatos de log.** `flume/log.offset` (JSON, con `grep`) y `db2/log.bipf`
(binario, con `pub/tools/log-bipf.js` dentro del contenedor). La foto dice cuál leyó (`log=flume` o
`log=db2`) y `check` enseña el cambio. Un log que no se puede leer es `?`, y `?` es NO MEDIBLE:
nunca un 0. Si el nodo publica entre la lectura del log y la pregunta al sbot, las dos fuentes no
cuadran: se repite la foto.

**Lo que el ensayo local no reproduce.** El `Dockerfile` y el entrypoint del host pueden no ser
los del repo (§0.3, «Deriva»). Por eso la imagen que se construye **en** el host se prueba allí
con un contenedor efímero antes de recrear ningún nodo (§4, paso 6).

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
| 1 | **Backups** | `backup-oasis-pub.sh` · `backup-ecoin.sh` (si hay cartera) · tgz de `ssb-data` de cada nodo de soporte · copia `*.bak-<etiqueta>-<fecha>` de cada fichero que vaya a cambiar (las de ficheros bajo `site/`, **fuera** de `site/`: esa carpeta se sirve al público). Si §0.3 dio **deriva** en `Dockerfile`, entrypoint, `.dockerignore` o compose y el ciclo los cambia: traerlos, diferenciarlos con el repo y converger **in place** (no afecta a nadie hasta el build o hasta recrear) | **GO-1** |
| 2 | **Disco** | retirar el rollback del ciclo **anterior** (tag de imagen, `src.old*`, tgz) · `docker image prune -f` · `docker builder prune -f`. Cada rebuild deja ~3 GB | |
| 3 | **Rollback de este ciclo** | `docker tag <imagen>:latest <imagen>:<ver-vieja>` · `tar -czf <datos>/src-<ver-vieja>.tgz src` | |
| 4 | **Subir `src/`** | ver abajo | |
| 5 | **Lo demás que viaja** (§3.2) que sea inocuo en la versión vieja: se sube y se aplica **ahora**, con los nodos todavía en la versión vieja, y se comprueba | p. ej. plantilla nginx: a un temporal del host · `nginx -t` en un contenedor desechable · in place · `$C up -d --no-deps --force-recreate hub-cache` · `$R hub` · salud de **todos** los vhosts del edge | |
| 6 | **Build y humo** | `$C build oasis-pub` (el pub sigue sirviendo) · humo de la imagen nueva (abajo) · si cambia el motor, **ensayo de migración** (abajo) · `df -h /` | |
| 7 | **Pub** | si cambia el motor: `$C stop oasis-pub` y tgz en frío de su `ssb-data` (se queda en el host) · `$C up -d --no-deps oasis-pub` · esperar a `healthy` (la migración ocurre antes de abrir el sbot) · `$R check pre --expect 'pub:oasisVersion=+1'` · invite · `/public/status` | **GO-2** (el pub se reinicia y publica `oasisVersion`; si cambia el motor, **sin retorno**) |
| 8 | **HUB** | sus configs in place · si cambia el motor, parar y tgz en frío · `$C up -d --no-deps oasis-hub` · `$R check …` · `hub-disk.sh prune-cache` · `$R hub --strict` (en ese orden: la caché guarda 404 de las rutas que la versión vieja no tenía) · ficheros del sitio que cambien: **uno a uno**, tras comprobar que el vivo es el del repo (`deploy-site.sh` sincroniza el sitio entero con `--delete`) | **GO-3** (publica `oasisVersion`) |
| 9 | **Bot de cartera** | plantilla in place y render (**con `sudo` en el host**: el destino es de otro uid y está a 400) · motor encendido: `hub-wallet.sh pause` (lo recrea en la versión nueva con el motor **apagado**) · `$R check …` (misma dirección, `wallet` sin cambios) · y entonces `hub-wallet.sh on --yes` · `$R check …` · `backup-ecoin.sh`. Motor apagado: `$C up -d --no-deps oasis-wallet-bot` · `$R check …` | **GO-4a** (`oasisVersion`) · **GO-4b** (encender: `pubAvailability`) |
| 9b | **Snapshot del pub** | no hay paso: lo reconstruye el propio pub desde que arranca (`OASIS_PUB_SNAPSHOT_HOURS`, `HUB-PROTOCOL.md` §13). Comprobar: `pub-snapshot.sh status` a los pocos minutos · `[snapshot]` en el log del pub · `$R check …` (construir no publica) | la **primera** vez que una instancia lo ofrece: GO (servicio nuevo desde el pub) |
| 10 | **Cierre** | `$R snapshot post` · `deploy-status.sh` · `capacity.sh` · `deploy-log.sh` (abajo) · ficha de instancia | |

Orden fijo: **pub → HUB → bots**. La imagen es compartida y un retag no recrea contenedores:
mientras no se recrea, cada nodo sigue en la versión vieja. `ecoind` no depende de la imagen de
Oasis y **no se recrea**.

**Paso 6, humo de la imagen.** El `Dockerfile` y el entrypoint del host pueden no ser los del repo
(§0.3): la imagen que se acaba de construir **allí** se prueba allí, antes de recrear a nadie, en
un contenedor que no toca nada: sin red, sin volúmenes (identidad y `.ssb` desechables dentro del
contenedor) y que se borra al acabar.

```bash
IMG=<imagen>:latest
docker run --rm --network none --entrypoint sh $IMG -c 'grep -m1 "\"version\"" /app/src/server/package.json; node --check /app/src/backend/backend.js && echo ok'
for mode in server backend; do
  cid=$(docker run -d --network none -e OASIS_SKIP_AI_MODEL=true -e OASIS_PUBLIC=true -e OASIS_OPEN=false -e HOME=/home/oasis -e SSB_PATH=/home/oasis/.ssb $IMG $mode)
  sleep 45
  docker inspect -f '{{.State.Status}}' $cid                                             # running
  docker logs $cid 2>&1 | grep -a -E 'Version: |parche|EROFS|Cannot find module|Error'  # versión nueva, 3 parches (patcheado o ya parcheado), ningún error
  [ $mode = backend ] && docker exec $cid curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3000/c   # 200
  docker rm -f $cid
done
```

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
grep '"url"' src.new/src/configs/snh-invite-code.json         # el dominio del pub (5.º guard)
ls src.new/src/configs/*.json                                 # ningún JSON de estado
# y cambiar. El destino del `mv` NO debe existir: `mv src src.old` con un src.old presente mete src DENTRO.
test ! -e src.old-<ver-vieja> && mv src src.old-<ver-vieja> && mv src.new/src src && rmdir src.new
```

**Antes del build, el `.dockerignore` del host.** El contexto de build es la raíz del repo del host y
`COPY . .` se lo lleva todo a la imagen. Debe excluir los rollbacks de `src` **con comodín**
(`src.old*`, `src.new*`: un `src.old` a secas no cubre `src.old-X.Y.Z`) y los env de producción de
la carpeta del compose (`<carpeta>/.env.*`: el patrón `.env.*` solo casa en la raíz). Comprobarlo
en la imagen construida, dentro del humo del paso 6: `ls -a` de la carpeta del compose no muestra
ningún `.env.prod*`. En la casa estuvo entrando hasta 2026-10-01 (WP-O114).

**Journal.** El `deploy.sh` del repo apunta el deploy al terminar; el del host es una copia vieja
que no se usa. Tras un deploy a mano, desde la máquina operadora:

```bash
bash devops/scripts/deploy-log.sh --target pub --host <dominio> --version X.Y.Z --caps-shs <shs> --cycle <n> --feed <feed> --mode <server|server+hub|server+hub+wallet-engine-on>
```

**Preservar siempre** (bind mounts): el `.ssb` de cada nodo (`secret` = identidad, `flume`, `blobs`,
`conn.json`, `oasis/**`) y `ai-models`. **Landing**: no se toca; lee versión y ciclo en vivo.

**Cliente** (`docker-compose.yml`, modo `full`): después del host y con otro GO si la identidad es
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
  `docs/PUB/*.example` + `deploy.md`, `devops/hosts/<instancia>/host.env` (`EXPECTED_SHS`,
  `SNH_FEED`), `pub/site/index.html` y los `ssb-config` de cada nodo de soporte
  (`pub/config/hub/ssb-config`, `pub/config/wallet-bot/ssb-config*`: rotan juntos, el follow entre
  ellos sobrevive); luego `pub-federation.sh announce` + `follow-solarnethub` + re-emitir invites.
  Cambiar `caps.shs` = red SSB distinta (los del cap viejo dejan de hacer handshake).

## 6. Healthcheck y rollback

- **Todos los nodos**: `upgrade-gates.sh --remote check pre --expect '…'` → versión nueva, healthy,
  mismo feed, delta declarado, sin errores en el log.
- **Pub**: `deploy-status.sh` → `caps.shs` OK; `pub:invite` funciona (canario del override
  `OASIS_SERVER_CONFIG_OVERRIDE`); `/public/status` da la versión nueva.
- **HUB**: `upgrade-gates.sh --remote hub --strict`; matriz pública de `HUB-PROTOCOL.md` §4;
  `hub-disk.sh check` → 0; sin `EROFS` en su log.
- **Bot de cartera**: misma dirección, `ismine: true`, **un** mensaje `wallet`; `hub-wallet.sh
  status`.
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
`--check` del diff de comportamiento las exige, y el ciclo 1.2.2 se cerró sin tres de ellas):

1. **Estado de partida**: salida de `deploy-status.sh` y de `snapshot pre`.
2. **Disposiciones**: una por ID del diff de comportamiento (§3.1); `--check` en verde.
3. **Qué viaja al host** (§3.2).
4. **Gates** U0-U7: comando y salida.
5. **Delta de publicación** medido en local y en el host, por nodo.
6. **Correcciones al protocolo**: cada tropiezo es un defecto de este documento y se arregla aquí.
   Si no hubo ninguno, la sección lo dice («ninguna»): una sección que falta no se distingue de
   un ciclo que no miró.

Un ciclo partido en dos reportes (local y host) lleva las seis en cada uno; lo que no aplica
(el delta del host en el reporte local) se dice en una línea.

Ciclos registrados (lo que cada uno cambió en el protocolo):

| Ciclo | Reporte | Lo que enseñó |
|---|---|---|
| 1.2.2 → 1.2.3 | `plan/REPORTES/WP-O127` (mejoras previas) · `WP-O128-upgrade-oasis-1.2.3.md` (local) | Lo que se afirmaba de memoria se mide: `NEW_REF` por commit «release», audit de parches en seco (la copia del fork del parcheador era la de 1.2.1), instancia de `host.env`, seis cabeceras. Una disposición leída («el bot publica un `about` al subir») salió falsa en U3: `syncClearnetSince` falla a los 3 s y lo reintenta en cada arranque (`about=+0..1` también en la misma versión). U6 completo en local con nodo desechable. El diff colapsa activos (10 922 teselas no son 10 922 disposiciones) |
| 1.0.8 → 1.1.2 | `plan/REPORTES/WP-O97-upgrade-oasis-1.1.2.md` · `HUB-PROTOCOL.md` §5.5 | primer ciclo con el HUB activo: `/c/assets`, rutas de detalle nuevas |
| 1.1.2 → 1.1.4 | `plan/REPORTES/WP-O105-upgrade-oasis-1.1.4.md`, `WP-O106-aplicacion-vps-1.1.4.md` · `ECOIN-PROTOCOL.md` §5.4 | `state-manager.js` y la mudanza de estado; quinto guard; `git archive` y CRLF |
| 1.2.1 → 1.2.2 | `plan/REPORTES/WP-O124-upgrade-oasis-1.2.2.md` (local, host y cliente) | Una disposición «acción de GUI» leída del código era falsa: el gate U5 destapó que HUB y bots publican un `about` de visibilidad con el primer refresco de fondo (`about=+0..1` en el `check` inmediato, `+1` en el de cierre). El sbot trae un plugin que hace de centralita: se acota por config, sin guard (`HUB-PROTOCOL.md` §14, `phone.tsv`). En el cliente, de ≤ 1.1.x a ≥ 1.2 hay cambio de motor |
| 1.1.10 → 1.2.1 | `plan/REPORTES/WP-O119-medida-db2.md`, `WP-O120-upgrade-oasis-1.2.1.md` (local), `WP-O121-capacidad.md`, `WP-O122-snapshots-pub.md`, `WP-O123-aplicacion-vps-1.2.1.md` (host: mismo delta que en local) · D-O27 | cambio de motor (flume → db2): migración de un solo sentido, sin rollback tras migrar; la medida daba 0 en silencio sobre el log nuevo; dependencias vendorizadas en `src/base` y un build que no instala nada; snapshots que nuestro pub sirve pero no construía; caché de blobs sin techo en un backend público |
| 1.1.4 → 1.1.10 | `plan/REPORTES/WP-O112-protocolo-upgrade.md` (este protocolo), `WP-O113-upgrade-oasis-1.1.10.md` (local), `WP-O114-aplicacion-vps-1.1.10.md` (host: mismo delta que en local) | el protocolo no medía comportamiento ni publicación. Todo nodo anuncia su versión (`oasisVersion`), también al volver atrás. Idioma por visitante en `/c` (D-O25). Avisos automáticos que se envían cifrados a uno mismo (`inboxMutedBots`). `GET /wallet` republica la dirección en un bot con el motor encendido. El primer `GET /banking` publica la dirección. El modelo de IA cambia bajo el mismo nombre |

## 8. HUB clearnet — ver `HUB-PROTOCOL.md`

Desde 1.0.x el pub puede servir un **HUB web de solo lectura** en `/c` con el contenido público de
los habitantes que hayan activado *Clearnet* en su perfil (`clearnet.md`). **En Docker no basta con
Caddy**: nuestro modo `server` arranca solo `SSB_server.js`, mientras que `oasis.sh server` de
upstream arranca sbot + `backend.js --public`. Cómo lo resolvemos, cómo se activa, cómo se mantiene
en disco y qué cambia en cada upgrade está en **`HUB-PROTOCOL.md`**.

Historia, para no repetirla: la receta que vivió aquí (ciclo 1.0.8) proxyaba **al backend del pub**
con un modo `server-hub` del entrypoint y enrutaba `/qr/*`. Se **retiró** el 2026-09-13 (D-O13) por
la v2: el HUB es un **nodo de soporte** con identidad propia en su propio contenedor
(`command: ["backend"]`, misma imagen, sin rebuild), el sbot del pub no se toca y `/qr/*` queda
fuera. Siguen valiendo, y están recogidos allí, los hechos del proxy: `/assets/*` entero colisiona
con la landing, `--allow-host` es obligatorio para `/clearnet`, las URLs de nuestro feed llevan
`%40%2F` sin decodificar y `/c/blob/*` es inmutable.
