# WP-O138 · Upgrade a Oasis 1.2.8 (1.2.5 → 1.2.8; 1.2.6 y 1.2.7 quedan dentro del salto)

Rama `upgrade/oasis-1.2.8` (desde `main` 030c1012) · 2026-10-12 · `OLD_REF=560580d7` (1.2.5) ·
`NEW_REF=28fc1a68` (1.2.8, punta de `oasis-upstream/main`; es el commit «Oasis release 1.2.8»). Upstream
publicó 1.2.6 (96cab3b6, 2026-10-10), 1.2.7 (be4a160c) y 1.2.8 (2026-10-11). Decisiones del custodio
(2026-10-12): directo a 1.2.8, un `oasisVersion` por nodo; ciclo entero con GO por puerta; el host se
puede medir en solo lectura durante la preparación; rama desde `main`. **Sin cambio de motor**
(`annex` db2 íntegro): UM y UR no aplican.

**Alcance.** Pub, HUB y bot de cartera de la instancia Scriptorium. Fuera: el bot retro (nodo real en
la máquina operadora, D-O33: ningún gate lo recrea; subirlo pide PERMISO propio), el cliente (1.2.2,
D-O32), `ecoind`, la maint-ui (prohibida durante el ciclo) y `caps.shs` (ciclo 6: «mantener»).

## 1. Estado de partida

Host medido en solo lectura (`bash devops/scripts/deploy-status.sh`, 2026-10-12):

```
Journal (último): 2026-10-10T03:37:33Z target=pub oasisVersion=1.2.5 cycle=6 mode=server+hub+wallet-engine-on+pub-snapshot-6h+phone-relay
Pub vivo: oasis-pub-scriptorium Up 44 hours (healthy) · caps.shs OK
Nodos de Oasis (versión dentro del contenedor · modo · estado):
  oasis-pub-hub          1.2.5  backend  running healthy  imagen al día
  oasis-pub-scriptorium  1.2.5  server   running healthy  imagen al día
  oasis-pub-wallet-bot   1.2.5  backend  running healthy  imagen al día
Resto: oasis-pub-ecoin 0.0.4-1 (healthy) · hub-cache nginx (healthy) · panel-api · web (caddy)
src/ en disco del host: 1.2.5
Deriva: Dockerfile, docker-entrypoint.sh, Caddyfile, nginx.conf.template, configs de HUB y bot: igual que HEAD
        .dockerignore DISTINTO de HEAD (editado en el host)
        pub/docker-compose.pub.yml DISTINTO de HEAD; versión que el repo tuvo (d21fc7b8)
        (medido con HEAD = dev/26sm-exported; se repite desde esta rama en el paso 0 del §4)
Restos de rollback: /opt/oasis-scriptorium/src.old-1.2.3 · /srv/oasis/src-1.2.3.tgz · imágenes :1.2.3 y :pre-o132
Directorio: ciclo 6 · pub.escrivivir.co cycle=6 status=online [VERDE]
Disco: /srv/oasis=30% /=41% · capacity: 0 avisos
```

Preflight (`bash devops/scripts/upgrade-preflight.sh`, tras `git fetch oasis-upstream main`):

```
Branch: upgrade/oasis-1.2.8 · Working tree limpio
LOCAL=1.2.5  UPSTREAM=1.2.8   DESPLEGADA=1.2.5   OBJETIVO=1.2.8
OLD_REF=560580d7
NEW_REF=28fc1a68
Código que cambia por rol: pub en modo server = 8 de los 25 ficheros que carga · backends y cliente = 121 · activos = 18 · src/base = 2
    pub: opinion_categories.js · config-manager.js · banking_model.js · typed_log.js · viewer_filters.js · workflows_model.js · db2_legacy.js · package.json
Ciclo actual de red: 6 · caps.shs local coincide · nuestro pub: cycle=6 status=online
WARN x1: upstream por delante (el esperado)
```

Local: imagen `oasis-pub-scriptorium:latest` = `5cfdf8ddca7f` con 1.2.5 dentro; stack de ensayo parado
(44 h); `snapshot pre128` en §4 (U0).

## 2. Qué se entregó

| Commit | Pieza |
|---|---|
| `b6e3ad89` | Overlay limpio `git rm -r src && git checkout 28fc1a68 -- src/`, tal cual upstream. Se conservan `blockchain-cycle.json` y los guards de `ssb_config.js`, `updater.js` y `snh-invite-code.json` (upstream no los tocó: `git diff --shortstat 560580d7 28fc1a68` vacío en los tres). `scripts/patch-node-modules.js` sigue a upstream |
| `52b9cf76` | Guards repuestos en los tres ficheros que upstream sí cambió (`backend.js` +845/−697, `clearnet_view.js` +3/−3, `settings_view.js` +1/−2): `git apply --3way` del diff de guards de 1.2.5, **limpio en los tres**, sin conflictos |

Verificación de invariantes (UPGRADE §2), tras `52b9cf76`:

```
git diff 28fc1a68 --stat -- src/                       → 7 files changed, 113 insertions(+), 33 deletions(-)  (idéntico al de 1.2.5)
git diff 28fc1a68 --stat -- src/base                   → (vacío)
git diff 28fc1a68 --stat -- scripts/patch-node-modules.js → (vacío)
git ls-files -s src/server/node_modules                → 120000 … (enlace)
node --check backend.js clearnet_view.js settings_view.js ssb_config.js updater.js → OK los cinco
grep -m1 version src/server/package.json               → "1.2.8"
node devops/scripts/upgrade-patches-audit.js 28fc1a68  → aplicado=6 silencioso=6 pendiente=0 sin-anclaje=0 ausente=1 (src/AI, normal) · rc=0
node pub/scripts/regen-node-configs.js --check         → HUB y bot «al día» · rc=0
```

## 3. Disposiciones

`bash devops/scripts/upgrade-behaviour-diff.sh 560580d7 28fc1a68`: 147 líneas, **73 con signo**; `annex`
53 invariantes `=`, **ningún `!`** (db2, ecoin, hub, phone). Cada ID con signo se dispone abajo. Las
lecturas que lo sostienen, en los hallazgos H1-H6.

### roles (8 `+`: lo que carga el pub en modo `server`)

- `e6ef65b3` `db2_legacy.js` → H1 (índice nuevo `oasisActivity`, RPC `activity.latest`/`tail`,
  paginado de las consultas, `createLogStream` con cota inferior) → **gate U3** (los tres nodos
  `healthy`, `seq = registros = sbot`) y **gate US** (el snapshot del pub se construye igual) ·
  **documentado** H1.
- `ad3e9c63` `typed_log.js` → la cola del log se pide por `activity.tail` y los resultados se cachean
  por punta del log (`cache.results`); lectura → **no-afecta** al feed; **gate U4** (el visor sirve lo
  mismo) y memoria del HUB en U3.
- `9f6ad872` `banking_model.js` → H2 (reequilibrio de RBU entre pubs; `pubAvailability` sin saldo si
  la cartera no responde) → **gate U3/U5** (`pubAvailability=+0..1`, `transfer` y `ubiAllocation` = 0)
  · **documentado** H2 (DECISIÓN antes de la dote).
- `11e046cb` `config-manager.js` → `getConfig()` con caché de 2 s, invalidada al escribir → **no-afecta**
  (nuestros nodos montan la config `:ro` y no la escriben).
- `8bd8630f` `opinion_categories.js` → mapa `messageTypes` (tipo de contenido → tipo de mensaje de
  opinión) → dato para H3 → **no-afecta** al pub (no vota nadie en modo `server`).
- `83e4f40f` `viewer_filters.js` → `isMutual` en paralelo (16) y por autor único: rendimiento →
  **no-afecta**.
- `0dfe1974` `workflows_model.js` → `courts` entra en un preset de módulos → **no-afecta**.
- `aba81af3` `package.json` → ver *deps*.

### routes (1)

- `3084235d` `POST /agenda/remove/:itemId` → acción de GUI; `publicModeGuard` bloquea los POST en HUB
  y bot (`OASIS_PUBLIC=true`) → **no-afecta** a los nodos; cliente: drill (CLIENT §5) cuando se suba.
  Ninguna ruta nueva bajo `/c/`: la plantilla de nginx y el Caddyfile **no cambian**.

### loopback (1)

- `d49b9c08` `GET /invites` → la vista recibe `canJoin: !config.public && isLoopbackRequest(ctx)`: el
  formulario de unirse a un pub solo se pinta en loopback y nunca en modo público. Más estricto →
  **no-afecta** (HUB y bot son públicos; nadie del fork la llama).

### publish (3)

- `e93a8f80`, `a7df8f82`, `5dac778b` `trending_model.js` → H3: votar una opinión deja de publicar un
  `tombstone` + una copia `updated` del contenido y pasa a publicar **un** mensaje `<tipo>Opinion`
  (`target`, `category`). Acción de GUI, nada la dispara sola → **no-afecta** a pub, HUB y bot;
  **gate U3** (0 mensajes fuera de lo declarado) · **documentado** H3.

### timers (8)

- `efba7d15` `backend.js` → H4: `kickRefresh()` a los 5 s del arranque, sin esperar a la primera
  petición → **gate U3** (lo que el refresco publica solo es lo ya declarado) y **gate U5**.
- `ce0da232`, `4920564d` `backend.js` → H5: el middleware espera hasta 1,2 s a que el sbot diga
  `ready` y, si no, sirve la página de indexado → **gate U3/U4** (`/c` 200 con contenido tras recrear
  el HUB; `prune-cache` antes de `hub --strict`, que ya es el orden del §4 paso 8).
- `801b595d` `backend.js` → `settleWithin`: tope de 400 ms a la comprobación de cartera de las páginas
  con chip de cartera → lectura → **no-afecta**; cubierto por **gate U5**.
- `2a073b5e` `main_models.js` → `blob.getResolved` ya no espera sin fin a `blobs.want`: devuelve `null`
  al vencer el `timeout` (30 s por defecto). Es la función del séptimo guard: un blob que no llega da
  404 en vez de colgar la petición → **gate U4** (prueba del séptimo guard).
- `4ddb98ba`, `12461658` `db2_legacy.js` → esperas con tope (3 s) de `ActivityIndex` → H1 → **gate U3**.
- `0f3fe489` `larp_model.js` → reintento de la academia solo con `larpMod=on` → **no-afecta** (HUB y
  bot no lo cargan en público; el pub no carga el backend).

### headers (4 IDs, 5 líneas)

- `2a5de416`, `52dd8943`, `5d061ce3`, `7b4d4c91` `backend.js` → `GET /image/:size/:blobId` guarda en
  memoria la miniatura ya redimensionada y la sirve con el mismo `Content-Type` y
  `Cache-Control: public, max-age=31536000, immutable` de antes. La respuesta sigue dependiendo solo
  de la URL; `/image/` no está bajo `/c/` ni lo enruta el edge → **no-afecta** a la caché compartida.

### env (1)

- `afa9b0ff` `OASIS_MOBILE` (4 → 5 usos) → un enlace de `graphos_view.js`; ningún compose la define →
  **no-afecta**.

### deps (3)

- `224f7f89`, `ed9dd9b2` versión 1.2.5 → 1.2.8.
- `5cc6c7f8` `src/base`: 2 ficheros. `moment/min/moment-with-locales.js` (corrección del locale
  kazajo) y `ssb-db2/indexes/plugin.js` (los índices guardan su progreso al menos una vez por segundo).
  Ningún `ssb-*` cambia de versión, `package.json` de dependencias sin cambios → los parches del
  entrypoint y el gate del invite no tienen motivo nuevo; U6 se repite igual (**gate U6**) · el flush
  por segundo → más escrituras durante el indexado, **gate U3** (arranque y `healthy`).

### outside (42)

- `65c44fee` `install.sh` (`ONNXRUNTIME_NODE_INSTALL_CUDA=skip`), `67d375cc` `oasis.sh` y `d998eb13`
  `scripts/oasis-pub.js` (orden `join <invite>` para un pub bare-metal): instaladores y CLI de
  upstream que el fork no usa (`pub/tools/*` hace ese trabajo) → **no-afecta**.
- `afc2198e` `scripts/patch-node-modules.js` → **adaptado** `b6e3ad89` (la copia del fork es la de
  `NEW_REF`; ver *patches*).
- Tests de upstream, que el overlay no trae y el fork no ejecuta → **no-afecta**: `597d595e`,
  `e59d18c5`, `c32b0057`, `eb0d23c5`, `7bca7c6a`, `fd450682`, `c27eb351`, `3f6324c0`, `c8ad869e`,
  `d5f8ab58`, `e039b630`, `917627f1`, `52d9d3fe`, `7ca79d45`, `431a2edc`, `d0abbf7b`, `4a0683a8`,
  `54f988e1`, `06a2ab4c`, `e43c5c25`, `d5bead9e`, `5c006e7f`, `67595977`, `2d02a331`, `7b4f2b8b`,
  `919e4b55`, `0e1b093b`, `1101ea11`, `9dac9833`, `9c90040a`, `ef96b084`, `cdec2b9b`, `8a359d0f`,
  `a19a5737`, `eada06b2`, `ed16397e`, `f5f24bee`, `2e7ce600`.

### patches (1)

- `b7ade88a` upstream añade un parche (el nº 4: `ssb-db2/indexes/plugin.js`, flush por segundo) →
  **adaptado** `b6e3ad89`: lo vendorizado en `src/base` ya lo trae (audit: `silencioso`, `pendiente=0`).
  Los tres del entrypoint no cambian.

### Hallazgos (lo que no se ve en el listado)

- **H1 · Índice nuevo de db2 en todo sbot (`oasisActivity`, versión 2).** `db2_legacy.js` registra
  `ActivityIndex` (última actividad por autor y los 64 últimos offsets) y un plugin `activity` con dos
  RPC (`latest`, `tail`). Se construye en el primer arranque recorriendo el log; **no es una migración
  del log** (`db2/log.bipf` no cambia; `annex` db2 `=`): un índice de más en `db2/indexes/` que una
  versión anterior ignoraría. `status()` gana `ready` (el log ha drenado). `createLogStream` no vivo
  con `gt`/`gte` lee hacia atrás con 10 min de margen; `snapshot-build.js` lo llama con
  `{ reverse: false }` sin cotas: no entra en esa rama (leído; lo mide US).
- **H2 · El motor de RBU reequilibra de otro modo (DECISIÓN antes de la dote).** En 1.2.5 un pub con
  excedente sobre `capPerEpoch` mandaba ECO a pubs **no disponibles**, con tope
  `REBALANCE_MAX_PER_EPOCH = 200` por época. En 1.2.8 el tope **desaparece**: cada pub con motor
  calcula la **media** de saldos (el suyo y los anunciados por los demás, corregidos por
  transferencias) y, si supera la media en más de un 5 %, reparte su exceso entre los pubs por debajo
  que hayan servido a `REBALANCE_MIN_CLAIMANTS` reclamantes elegibles. Cada envío es dinero real y un
  `transfer` publicado. **Hoy no mueve nada** en la casa (pool 0: sin exceso), pero cambia lo que hará
  el bot cuando reciba la dote. Además: `pubAvailability` sale **sin `balance` ni `pool`** si la
  cartera no responde (antes anunciaba 0), y un anuncio sin saldo conocido no cuenta para la lista de
  bancos de Banking → UBI. Leído, no medido con fondos.
- **H3 · Las opiniones pasan a ser mensajes propios.** `<tipo>Opinion` con `target` y `category`, en
  vez de tombstone + copia. Los modelos (57 ficheros) recomponen el recuento leyendo. Para el visor
  `/c` es lectura; lo mide U4.
- **H4 · El refresco de fondo arranca solo, y ahora publica el `karmaScore` del nodo (DESVIACIÓN en
  U3; DECISIÓN del custodio).** `refreshAll` corría con la primera petición no estática; ahora
  también a los 5 s del arranque. La primera versión de este párrafo decía «son las mismas llamadas
  que en 1.2.5»: **era falso** y lo destapó el gate. En 1.2.5 `ensureSelfAddressPublished()` y
  `getUserEngagementScore(viewer)` solo se llamaban desde `GET /activity` (`backend.js:6289-6290` de
  `560580d7`), una página que nadie visita en un HUB; en 1.2.8 upstream las mueve a `refreshAll`
  (`backend.js:14642-14643`). `getUserEngagementScore` publica un `karmaScore` propio si el valor
  **cambió** (o nunca se publicó) y han pasado **24 h** desde el último (`banking_model.js:1140-1163`).
  Consecuencia medida: el HUB local, que nunca había publicado uno, publicó `karmaScore = 4` a los
  ~35 s de arrancar en 1.2.8 (seq 14, tras su `oasisVersion` en seq 13). Consecuencia leída: todo
  backend (HUB, bots, cliente) publicará su `karmaScore` sin que nadie lo pida, **como mucho uno al
  día y solo cuando el valor cambie**, de forma indefinida. `ensureSelfAddressPublished` devuelve
  `present` si el mapa local ya tiene la dirección (bot) y `skipped` sin cartera (HUB): no cambia.
- **H5 · Página de indexado mientras el sbot no está `ready`.** Cualquier ruta, también `/c`, responde
  200 con la página «sincronizando» (refresco a 5 s) hasta que el log drena. `hub-cache` puede guardar
  esa página unos segundos tras recrear el HUB: el §4 paso 8 ya purga la caché antes de `hub --strict`.
- **H6 · `getResolved` con tope.** El séptimo guard (D-O31) se apoya en `blob.getResolved`: en 1.2.8
  un `want` que no llega devuelve `null` a los 30 s en vez de dejar la petición abierta. Mejor para el
  HUB; el guard no se toca.

## 4. Qué viaja al host

Lista cerrada de este ciclo (lo que no está aquí **no se sube**):

| Qué | Cómo | Después |
|---|---|---|
| `src/` (overlay + guards, `52b9cf76`) | `git -c core.autocrlf=false -c core.eol=lf archive` → `src.new` → comprobaciones → `test ! -e src.old-1.2.5 && mv` | `build` + humo (§4 paso 6) |

**No viaja**: compose, `Dockerfile`, `docker-entrypoint.sh`, `nginx.conf.template`, `Caddyfile`,
`pub/config/**` (`regen-node-configs.js --check` al día; `git diff main --stat` vacío en compose,
entrypoint y Dockerfile), `pub/panel-api`, sitio. La deriva de `.dockerignore` y del compose que da
`deploy-status.sh` se vuelve a medir desde esta rama en el paso 0 del §4.

## 5. Gates

Stack local (`pub/docker-compose.pub.yml` + `pub/.env.local`, `volumes-dev/`, identidades desechables),
2026-10-11/12, `G="bash devops/scripts/upgrade-gates.sh --local"`. Tres nodos (`GATE_NODES` por defecto: sin retro).
`E='pub:oasisVersion=+1 hub:oasisVersion=+1,karmaScore=+0..1 bot:oasisVersion=+1,pubAvailability=+0..1,about=+0..1,karmaScore=+0..1'`.

| Gate | Comando | Resultado |
|---|---|---|
| **U0** línea base | nodos parados · `$G backup pre128` (3,1 M) · `compose up -d --no-build --wait` con la imagen 1.2.5 (`5cfdf8ddca7f`; el compose no cambia en el ciclo) · `$G snapshot pre128` | tres nodos `healthy` en 1.2.5, `log=db2`, `seq = registros = sbot`: pub 14 (`contact=7 oasisVersion=7`) · HUB 12 (`(cifrado)=1 about=2 contact=1 oasisVersion=7 pub=1`) · bot 28 (`about=4 contact=1 karmaScore=3 oasisVersion=7 pub=1 pubAvailability=9 ubiAllocation=2 wallet=1`, dirección `EYMWF4ED…`, épocas `2026-09,2026-10`, `motor:pub=true`) |
| **U1** árbol | §2 · `annex` · `--check` | 7 ficheros · 53 invariantes `=`, ningún `!` · audit `pendiente=0` · `upgrade-behaviour-diff.sh 560580d7 28fc1a68 --check` de este fichero: «todas las líneas tienen disposición … y el registro lleva las seis cabeceras», rc=0 |
| **U2** imagen | `docker tag …:latest …:1.2.5-vieja` · `compose build oasis-pub` · humo con `docker run --rm --network none --entrypoint sh` | Primer build `88237f84ebfd`: **traía `/app/volumes-real` con el `ssb-data` del bot retro, `secret` incluido** (§7; `.dockerignore` no lo excluía). Corregido en `b3ff2d9e`, reconstruido → `34cce18f8c3f` (1,57 GB): versión 1.2.8; `node --check` de `backend.js`, `clearnet_view.js`, `db2_legacy.js`; `src/server/node_modules → ../base/node_modules`; guard 7 (1), guard 6 (4 y 2), `blobs.max = 50`, `url` del 5.º guard; **0 ficheros `secret`**, sin `volumes-*`, sin `.env*` en `/app/pub`. La imagen contaminada ya no existe (`docker image inspect` falla) y no arrancó ningún contenedor |
| **U3** recrear y medir | `$G up pub` · `$G up hub` · `$G up bot` · `$G check pre128 --expect '…'` | `healthy` a los 5-10 s. Con el delta del plan: **`GATE: DESVIACIÓN`** — `hub … Δseq=2 · karmaScore+1 oasisVersion+1 → karmaScore+1 no esperado` (H4). Parada, causa leída y medida (`karmaScore = 4`, seq 14), DECISIÓN del custodio: **aceptarlo y declararlo**. Con `$E`: pub `oasisVersion+1` · HUB `karmaScore+1 oasisVersion+1` · bot `oasisVersion+1` → **`GATE OK`**. Logs: `ssb-ref` y `multiserver` «patcheado», `ssb-blobs` «ya parcheado», 0 errores (`EROFS|EACCES|ReferenceError|TypeError|Cannot find module`), `Blob size limit: 50 MB`, «Admin access» 1 en HUB y bot y 0 en el pub (no copiado). `db2/indexes` del pub: `oasisActivity` presente junto a `base contacts ebt keys oasisLinks`. Memoria: HUB 71 MiB / 1,5 GiB · bot 71 MiB · pub 39 MiB |
| **U4** visor | `$G hub --strict` | **`GATE OK`** (16 comprobaciones): 200, MISS→HIT, una CSP, idioma independiente del visitante, `?lang=`, 18 concurrentes sin cruce, selector y `?theme=`, 36 enlaces con `lang` y 45 con `theme`, variante de tema cacheada aparte, `?type=files`, sitemap 15 URLs https, RSS |
| **U4** séptimo guard | blob `&8DZ+…` referenciado en `/c`: `docker exec hub rm` → `GET /c/blob` directo al HUB (`Host: localhost`) → buscar el fichero | Primer intento con el HUB **sin pares** (artefacto del stack local, como en WP-O135: `conn.json` con IPs viejas): **404 a los 30,03 s** (el tope nuevo de `getResolved`, H6: antes la petición quedaba abierta). Tras `hub-conn-fix.js 'net:oasis-pub:8009~shs:<KEY>'` → `connected`: el blob vuelve solo (el `want` pendiente se cumple); borrado otra vez → **200, 17 316 B, 0,07 s** y el fichero está de nuevo en el contenedor (Oasis lo escribe en `blobs/sha256/f0/f0367e…`, no en la ruta de sbot `f0/367e…`). Blob no referenciado (`&AAAA…`) → **404** |
| **U5** peor caso del bot | `$G snapshot u5` · `$G worst` · `$G check u5 --expect 'bot:karmaScore=+0..1,about=+0..1 hub:karmaScore=+0..1'` | `/banking`, `/transfers`, `/shops`, `/market`, `/school` → 200. **Δseq = 0 en los tres**; `wallet`, `(cifrado)` y dirección sin moverse → `GATE OK` |
| **U6** invite completo | `$G snapshot u6` · `invite.create({uses:1, external:'gate.example.org'})` por `ssb-client` en el pub · host → IP del pub en el bridge · `docker run -d --name oasis-gate-u6-desechable --network oasis-pub-scriptorium_oasis_pub_net -e OASIS_SNAPSHOT=off … backend` · `ssb-probe.js` `SSB_ACTION=invite-accept` · `$G check u6 --expect 'pub:contact=+1 hub:karmaScore=+0..1 bot:about=+0..1,karmaScore=+0..1'` · `docker rm -f` | desechable `running` en 1.2.8; `"accept": true`, pub `connected`; **pub `contact+1`**, HUB y bot 0 → `GATE OK`. El invite no se imprimió (solo su forma: host y puerto 8009). Desechable retirado |
| **US** snapshot | `$G snapshot us` · `pub-snapshot.sh --local status` · `--local build` · `$G check us` | «cada 6 h, dentro del contenedor»; el pub ya lo había reconstruido solo al arrancar en 1.2.8 (67 213 B, 212 mensajes, 6 feeds); build `{"ok":true,"messages":216,"feeds":6,"boxed":5,"bytes":67866,"ms":176}`; Δseq = 0 en los tres → `GATE OK` (H1: `createLogStream` sin cotas sigue sirviendo) |
| **U7** repetible | `compose stop` de los tres · `$G restore pre128 --yes` · `render-wallet-bot-config.sh pub/.env.local` (rc=0) · `$G up pub|hub|bot` · `$G check pre128 --expect "$E"` | `healthy` a los 5 s. **Mismo delta que la primera vez**: pub `oasisVersion+1` · HUB `karmaScore+1 oasisVersion+1` · bot `oasisVersion+1` → `GATE OK`; 0 errores en los tres logs |

No aplican UM ni UR (no cambia el motor: `db2.tsv` en verde).

## 6. Delta de publicación

Local, por nodo, desde `pre128` (1.2.5), medido dos veces (U3 y U7): **pub `oasisVersion+1`** (más `contact+1` por el
invite de U6) · **HUB `oasisVersion+1` + `karmaScore+1`** · **bot `oasisVersion+1`** (ni `pubAvailability`, ni
`about`, ni `karmaScore` salieron: el bot ya tenía tres `karmaScore` y su valor no cambió).

Declarado para el host (decisión del custodio sobre H4, 2026-10-12):

```
pub:oasisVersion=+1 hub:oasisVersion=+1,karmaScore=+0..1 bot:oasisVersion=+1,pubAvailability=+0..1,about=+0..1,karmaScore=+0..1
```

Después del ciclo, HUB y bot podrán publicar un `karmaScore` propio como mucho una vez al día y solo si el valor
cambia: deja de ser una desviación en los `check` posteriores.

**Medido en el host** (`upgrade-gates.sh --remote check pre128 --expect '…'`, foto base 23:11:50Z, `post128`):

```
pub  v1.2.5 → v1.2.8 · Δseq=1 · oasisVersion+1 → ok                          (seq 24 → 25)
hub  v1.2.5 → v1.2.8 · Δseq=2 · karmaScore+1 oasisVersion+1 → ok             (seq 17 → 19)
bot  v1.2.5 → v1.2.8 · Δseq=3 · karmaScore+1 oasisVersion+1 about+1 → ok     (seq 75 → 78)
GATE OK
```

Mismo delta que en local para pub y HUB. En el bot real salieron además el `karmaScore` (su valor había cambiado
desde el 2026-10-05) y el `about` de `clearnetSince` que 1.2.3 intentaba en cada arranque (UPGRADE §0.4): los dos
declarados como `+0..1`. `wallet` = 1, dirección `EYdruX…`, `pubAvailability` = 44 y `ubiAllocation` = 16 sin
moverse, también tras encender el motor.

## 7. Correcciones al protocolo

Hechas en esta rama salvo donde dice «pendiente»:

- **`.dockerignore` no excluía `volumes-real/`** (`b3ff2d9e`). La carpeta nació en WP-O135 (D-O33) y el
  primer build local posterior metió en la imagen la identidad real del bot retro. Lo cazó el humo de U2
  (`ls /app`), antes de arrancar nada. UPGRADE §3.4 U2 debe decir que el humo comprueba **0 ficheros
  `secret`** en la imagen (`find / -xdev -name secret`), no solo la ausencia de `.env*`; y AGENTES §2.9, que
  un nodo real en la máquina operadora vive en una carpeta excluida del contexto de build.
- **Una disposición leída volvió a salir falsa** (H4): «son las mismas llamadas que en 1.2.5». El diff de
  comportamiento no ve una llamada que **cambia de sitio** (de una ruta de GUI a un temporizador): no es una
  línea `publish` nueva. Es el tercer ciclo en que lo destapa U3 y no la lectura (1.2.2, 1.2.3, 1.2.8).
  Pendiente: que `upgrade-behaviour-diff.sh` saque en `timers` las funciones que pasan a llamarse desde el
  refresco de fondo.
- UPGRADE §3.4 (delta declarado): desde 1.2.6, `karmaScore=+0..1` en HUB y en cada bot, al subir y en
  cualquier `check` posterior separado más de 24 h.
- Prueba del séptimo guard: el fichero reaparece en la ruta de Oasis (`blobs/sha256/<2>/<64 hex>`), no en la
  de sbot (`<2>/<62 hex>`); buscar con `find -name '<hex>*'`.

- `docs/roles/mantener.md`, tabla «Qué hará el agente», paso 3: dice «las cinco diferencias» y
  «exactamente seis ficheros»; son 7 guards y 7 ficheros desde WP-O135.
- `docs/PUB/INSTANCIA-SCRIPTORIUM.md` §3: el párrafo de versión decía 1.2.3 con el host en 1.2.5 (el cierre de
  WP-O135 no lo actualizó): corregido a 1.2.8.
- En Windows el overlay (`git rm -r src && git checkout`) tarda más de 5 minutos y
  `upgrade-behaviour-diff.sh` otro tanto: no es una desviación; anotado en la fila del ciclo (UPGRADE §7).
- El `check` de cierre «al menos 5 minutos después de recrear el último nodo»: el primero de esta sesión se
  hizo a los 3 minutos por un error de cuenta del operador; se repitió pasado el plazo (§8, paso 10).

## 8. Aplicación en el host (2026-10-11 UTC, GO-1 … GO-4b)

Una orden por paso (UPGRADE §4). Estado de partida: §1 y foto `pre128` (remote, 23:11:50Z): pub 24 · HUB 17 ·
bot 75 (`motor:pub=true`, épocas `2026-09,2026-10`); los tres `seq = registros = sbot`. El compose del host es el
de la rama (`git diff d21fc7b8 HEAD -- pub/docker-compose.pub.yml` vacío: el «DISTINTO» es fin de línea).

| # | Paso | Hecho | Puerta |
|---|---|---|---|
| 1 | Backups | pub → `devops/backups/oasis-pub/20261011T231341Z`; `wallet.dat` → `devops/backups/ecoin/20261011T231544Z` (86 016 B, `e4135803…`) y tras encender `…/20261011T233445Z` (`7353874f…`); en el host `oasis-hub.bak-o138-2026-10-11.tgz` (857 MB) y `oasis-wallet-bot.bak-o138-2026-10-11.tgz` (98 MB), 600, solo `ssb-data` | **GO-1** |
| 2 | Disco | los tres nodos corrían `:latest` (`ca6c85a7bd14`): retirados los tags `:1.2.3` y `:pre-o132`, `src.old-1.2.3` y `src-1.2.3.tgz`; `image prune` 0 B, `builder prune` 840,5 MB; `/` 41 % → 35 % | |
| 3 | Rollback | `oasis-pub-scriptorium:1.2.5` = `ca6c85a7bd14` · `/srv/oasis/src-1.2.5.tgz` (94 MB, 600) | |
| 4 | `src/` | `git archive` LF de `upgrade/oasis-1.2.8` (`bf5df0eb`) → `src.new` (24 138 ficheros, 287 MB). Antes del `mv`: 1.2.8, 0 CR en `backend.js` e `is-map`, enlace a `src/base` + `ssb-db2` vendorizado (con `lastFlushAt`), `url` del 5.º guard, guard 6 (4 + 2), guard 7 (1), `blobs.max 50`, solo 4 JSON en `configs/`; `.dockerignore` del host con `src.old*`, `src.new*` y `OASIS_PUB/.env.*`. `mv src src.old-1.2.5` | |
| 5 | Lo demás que viaja | nada (§4) | |
| 6 | Build y humo | `compose build oasis-pub` → `28b8db7aaaa5` (1,06 GB); `/` 39 %. Humo sin red: 1.2.8, `node --check` de `backend.js` y `clearnet_view.js`, enlace, guard 7, **0 `secret`**, 0 `.env.prod`, sin `src.old`; `server` y `backend` efímeros `running`, sin errores, `Blob size limit: 50 MB`, `GET /c` 200. Los tres nodos seguían `healthy` en `ca6c85a7bd14` | |
| 7 | Pub (23:23:39Z) | `up -d --no-deps --no-build oasis-pub` → `healthy` a los 30 s. `check pre128 --expect 'pub:oasisVersion=+1'` → **`GATE OK`** (HUB y bot Δ0). Tres parches, 0 errores, `ssb-data` a 700, `db2/indexes/oasisActivity` construido. `/public/status` → 1.2.8, `healthy`, invite público presente (121 caracteres, no copiado). El HUB reconectó por la IP del bridge y recibió el seq 25 | **GO-2** |
| 8 | HUB (23:25:38Z) | `up -d --no-deps --no-build oasis-hub` → `healthy` a los 61 s. Config del bind = repo (`f16cc0ce…`), `Media cache limit: 2048 MB`, «Admin access» en el log (no copiado), 0 errores, 197 MiB / 768. `check`: pub `+1`, **HUB `oasisVersion+1 karmaScore+1`**, bot Δ0 → `GATE OK`. `hub-disk.sh prune-cache` (592 MB → 0) · `hub --strict` contra `https://pub.escrivivir.co` → **`GATE OK`** (16 comprobaciones; 157 enlaces con `lang`, 166 con `theme`; sitemap 191 URLs https; RSS 35 + 4) | **GO-3** |
| 9 | Bot (23:29:39Z / 23:32:44Z) | `hub-wallet.sh pause` → 1.2.8 con `pub=false`, `healthy`; config del bind = render del host (`15eec31d…`), «Admin access» presente, 0 errores, 173 MiB / 768. `check`: **`oasisVersion+1 karmaScore+1 about+1`**, `wallet` = 1, dirección `EYdruX…`, `(cifrado)` quieto → `GATE OK`. `hub-wallet.sh on --yes` (`ready` en verde; aviso de saldo 0, época `2026-10` ya abierta) → `pub=true`, «PUB engine on»; `check` con `pubAvailability=+0..1`: **no republicó**, `ubiAllocation` = 16 → `GATE OK`. `backup-ecoin.sh` después | **GO-4a · GO-4b** |
| 10 | Cierre | `snapshot post128`: pub 25 · HUB 19 · bot 78, cuadran · `deploy-status.sh`: tres nodos 1.2.8 `healthy` «imagen al día», `src/` 1.2.8, pub VERDE en el directorio (ciclo 6), `/` 39 %, `/srv/oasis` 31 %, `capacity` 0 avisos · journal | |

Pub sin sbot ≈ 30 s; HUB ≈ 61 s; bot ≈ 2 × 90 s. **Nada publicado con identidad real fuera de lo declarado.**
El bot retro (máquina operadora) y el cliente no se han tocado: siguen en 1.2.5 y 1.2.2.

## 9. No medido / pendiente

1. **H2 (reequilibrio de RBU sin tope por época): DECISIÓN del custodio antes de la dote.** Leído en el código,
   no medido con fondos. Con saldo 0 no hace nada.
2. Bot retro (nodo real local, 1.2.5): subirlo publica su `oasisVersion` y, por H4, un `karmaScore`. PERMISO
   aparte. Mientras no se decida, **no hacer `compose up` de ese servicio**: la imagen local `:latest` ya es 1.2.8
   y lo recrearía (un `docker start` del contenedor existente sigue en 1.2.5).
3. Cliente dockerizado: sigue en 1.2.2 (D-O32).
4. Rollback de este ciclo en el host (`:1.2.5`, `src.old-1.2.5`, `src-1.2.5.tgz`): se retira en el siguiente
   (UPGRADE §4 paso 2). En `/srv/oasis` quedan además tgz de datos de ciclos anteriores (`*.bak-o128`,
   `*.bak-o135`, `oasis-pub.cold-o123`, ~2,4 GB) que nadie ha pedido retirar.
5. Los backups de esta sesión (`devops/backups/oasis-pub/20261011T231341Z`, `…/ecoin/20261011T231544Z` y
   `…/20261011T233445Z`) son material de claves sin cifrar en el portátil: a la cripta.
6. Caché de build local: la capa `COPY . .` del primer build (con `volumes-real/`) puede seguir en la caché de
   BuildKit de la máquina operadora, que es donde ya vive ese `secret`. `docker builder prune` la retira.
7. `upgrade-behaviour-diff.sh` no ve una llamada que se muda a un temporizador (§7): mejora pendiente.
