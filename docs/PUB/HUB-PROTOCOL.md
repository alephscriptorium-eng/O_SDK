# Protocolo del HUB clearnet (nodo de soporte)

> **Este repo es el sitio del HUB** (`C:\S_LAB\o-sdk`,
> `https://github.com/alephscriptorium-eng/O_SDK.git`). El HUB vive en
> `https://pub.escrivivir.co/c` y su puerta es la Sala 04 del Scriptorium (`/hub/`).

> **Estado · ACTIVADO 2026-09-13 19:55 UTC** en `pub.escrivivir.co` (WP-O46, rama
> `wp/O46-hub-nodo-soporte`). Cuenta de soporte `azofaifo-scriptorium-skin-bot-1` =
> `@KM+ZBipR18VSyjNTFjAOnsmz6EiobGYHb3ZCZ4ZxQYI=.ed25519`. Journal `--mode server+hub`
> 20:02 UTC. Plan, dosier y hallazgos de gates y deploy: `ARCHIVO/DISCO/oasis-clearweb/v2.md`
> + `dosier/`; reporte `plan/REPORTES/WP-O46-hub-nodo-soporte.md` (asientos D-O13/D-O14).
> Pendientes: ajuste de memoria a las 24 h (§7), caché a los 7 días (§6), rollback nivel 1
> no ensayado (decisión del custodio: deja `/c` sin servicio ~1 min).

Checklist operativo para **activar, operar, mantener en disco y llevar a través de
los upgrades** el HUB web de solo lectura de Oasis (`/c`, 16 tipos de contenido desde 1.1.2; 12 en 1.0.8,
`./clearnet.md`). Deriva del plan v2 del 2026-09-13 y de su revisión adversarial
(20 hallazgos, `dosier/05-revision-adversarial.md`).

> **Modelo mental.** El pub (`oasis-pub-scriptorium`, modo `server`) **solo replica**.
> El HUB lo sirve **otra cuenta SSB**, un *nodo de soporte*, en su propio contenedor
> `oasis-pub-hub`: **misma imagen** que el pub, `command: ["backend"]`, es decir
> `backend.js --public` con el sbot **embebido** y un `.ssb` propio en
> `/srv/oasis/oasis-hub`. Delante va `oasis-pub-hub-cache` (nginx, caché en disco
> acotada) y el Caddy compartido enruta **solo** `@hub`. El pub no cambia: ni imagen,
> ni entrypoint, ni servicio en el compose, ni un reinicio. Para la red SSB el HUB es
> un habitante más: redime un invite del pub, recibe follow-back y replica a hops 2.

## 0. Cómo hemos llegado aquí (evolución)

| Cuándo | Hito | Dónde queda |
|---|---|---|
| Oasis 1.0.x | Upstream añade el HUB clearnet: `/c`, modo `--public`, opt-in por habitante | `./clearnet.md` (doc upstream) |
| Ciclo 0.9.6→1.0.8 | Receta v0 en `UPGRADE-PROTOCOL.md` §8: proxy de Caddy **al backend del pub** con un modo `server-hub` del entrypoint (sbot + backend en el mismo contenedor). Nunca activada | retirada; queda como historia en §8 |
| 2026-09-13 · v1 | Plan «Sala 04»: backend dentro del contenedor del pub, supervisor sbot+backend, rebuild de ~3 GB, riesgo R0 (el getter de `SSB_server.js` podía crear un segundo sbot sobre el mismo `.ssb`) | `ARCHIVO/DISCO/oasis-clearweb/v1.md` |
| 2026-09-13 · v2 | Tres correcciones del custodio: **a)** el sbot del pub no se toca · **b)** el HUB es otra cuenta SSB en contenedor propio · **c)** estado y caché en el volumen de datos con utilidad de control. Revisión adversarial F1-F20 | `v2.md`, `dosier/` |
| ⏳ | Deploy WP-O46 (gates locales G1-G7 → VPS) | §10 de este doc + journal |

**El hallazgo que hizo posible la v2 sin tocar el pub**: `backend.js` no es un cliente
puro. `src/client/gui.js` requiere `SSB_server` y su getter **crea un sbot embebido** si
no existe (solo cae al socket unix si el arranque falla por LOCK). Con un `~/.ssb`
propio, `node backend.js` es un nodo SSB completo en un solo proceso. Lo que en la v1
era el riesgo R0 es en la v2 el mecanismo.

Tabla completa v1↔v2: `dosier/08-v1-vs-v2.md`.

## 1. Invariantes (lo que todo cambio futuro debe conservar)

- **El pub no se toca.** Ningún servicio nuevo monta nada de `/srv/oasis/oasis-pub`;
  el servicio `oasis-pub` del compose, su imagen y su entrypoint no cambian; el pub
  no se reinicia en ningún paso (deploy, upgrade del HUB, rollback).
- **Identidad propia.** El `secret` del HUB nace en `/srv/oasis/oasis-hub/ssb-data` en
  el primer arranque; nunca se copia del pub. Feed id del HUB ≠ feed id del pub.
- **Solo lectura hacia fuera.** `--public` (todo no-GET → 403), nginx (405 a no-GET),
  Caddy enruta solo `/c`, `/c/*`, `/clearnet` y `/assets/{styles,themes,images}/*`.
  `OASIS_HUB_PUBLIC=false` existe **solo** para el bootstrap del invite y **nunca**
  con `@hub` activo en Caddy.
- **El feed del HUB solo contiene cuatro tipos propios, todos públicos**: `contact` (follow
  al pub), `pub` (lo publica ssb-invite al aceptar el invite, con la dirección del pub),
  `about` (§11) y `oasisVersion` (el backend lo publica al arrancar con feed no vacío). Cero
  `private`. Contraevidencia: `grep -a -c '"private":true' flume/log.offset` = 0 y los
  mensajes filtrados por `author` = feed del HUB no tienen otro `type`.
- **El pub solo publica el `contact` del follow-back** al redimir el invite (función
  normal de un pub). Secuencia del feed del pub antes/después = +1, una vez.
- **Todo el estado nuevo bajo `/srv/oasis/oasis-hub/*`** (volumen de datos, 40 GB).
  `df -h /` igual antes y después: sin rebuild, solo `docker pull nginx:alpine`.
- **Delta del fork en `src/`: cero.** El HUB vive en la zona *wholesale* (`pub/**`,
  `devops/**`). Los 4 guards de `UPGRADE-PROTOCOL.md` §2 siguen siendo los únicos.
- **`CA-ANTI-AUTORIDAD`** (D-O6): el opt-in viaja con el feed del habitante; el HUB no
  decide quién aparece y **no se lista a sí mismo** (su `about` no lleva `vis_*`).
- **La cuenta se declara con nombre de serie** (D-O14): `azofaifo-scriptorium-skin-bot-1`,
  convención `<nombre>-<tipo>-bot-<cardinal>`. Cada bot de soporte que se conecte al pub
  (vistas de hackería, parlamento, teatro…) toma el siguiente cardinal y se registra en §11.
- **Fail-open en topología, fail-closed en capacidades** (D-O7): cualquier nodo que
  replique puede servir un HUB; lo que no puede es escribir.

## 2. Piezas (fuente única) y contrato de rutas

| Pieza | Fichero | Qué fija | Estado |
|---|---|---|---|
| Servicios `oasis-hub` + `hub-cache` | `pub/docker-compose.pub.yml` | misma imagen, `command: ["backend"]`, env `OASIS_*`, `mem_limit`, healthcheck a `/c/inhabitant/@AAAA…=.ed25519` (**no** a `/c`, que es O(N·k)), sin `ports`, sin `profiles` | ⏳ WP-O46 |
| Identidad y replicación | `pub/config/hub/ssb-config` (bind `:ro` a `~/.ssb/config`) | `caps.shs` del ciclo, `pub:false`, `friends.hops:3` (D-O15: con 2 el HUB solo alcanzaba los 3 seguidos directos del pub y `/c` quedaba vacío; los habitantes con Clearnet están a 3 saltos, seguidos por La Plaza), **sin `seeds`** (un seed al pub mete su clave en `gossip.json` antes del invite y el backend responde `alreadyFederated` sin redimirlo; la conexión persistente la deja `hub-conn-fix.js` en `conn.json`), `connections` **completo** (`mergeDeep` reemplaza arrays enteros) con `incoming.net.host: 0.0.0.0` **obligatorio** (el entrypoint pasa `--host 0.0.0.0`; otro valor = crash loop «conflicting connection settings») | ✅ G2 |
| Normalizar `conn.json` tras el invite | `pub/tools/hub-conn-fix.js` (se copia al HUB con `docker cp`; `pub/tools` no está montado allí) | tras `invite.accept`, ssb-invite deja la dirección del pub **con el seed y sin `key`**: el HUB reconecta con la identidad desechable y el pub no replica; sin `key` nunca reconecta tras un reinicio. El script hace forget `addr:SEED` · remember `{key,type:pub,autoconnect}` · connect | ✅ G3 |
| Visor | `pub/config/hub/oasis-config.json` (bind `:ro`) | copia del de `src/configs/` con 6 claves fijadas: `aiMod/aiNavMod:off`, `walletPub.pubId:""`, `ssbLogStream.limit:20000`, `lanBroadcasting:false`, `themes.current:"Dark-SNH"` (en 1.0.8 el original ya trae `pubId:""` y `Dark-SNH` → **4 diferencias efectivas**) | ✅ escrito (G1) |
| Caché HTTP | `pub/config/hub/nginx.conf.template` | `proxy_cache_path … max_size=${HUB_CACHE_MAX_SIZE} inactive=7d`, caché negativa (404 30 s, 5xx 5 s, WP-O53), `proxy_hide_header` de las cabeceras del backend, `limit_req` por XFF, `location / { return 404; }`; en `/assets/*` y en `/c/assets/*` (visor 1.1.2) `proxy_ignore_headers Cache-Control` (koa-static manda `max-age=0`). En **local Windows** el cache dir es el volumen nombrado `hub_http_cache` (los bind mounts rompen `proxy_cache`); en el VPS es la ruta bind | ✅ G4 |
| Edge | `pub/caddy/Caddyfile` (bloque `@hub` del vhost del pub) | `reverse_proxy hub-cache:80`; `transport http {…}` en multilínea; `/qr/*` **fuera**; `/assets/*` entero **no** (`fanzine.css` es de la landing); desde 1.1.2 el visor usa `/c/assets/*`, ya cubierto por `/c/*`; `header {}` global intacto | ✅ G1/G4 |
| Variables | `pub/.env.vps.example`, `.env.local.example`, `.env.example`; `.env.prod` del VPS | `OASIS_HUB_{SSB_DATA,LOGS,HTTP_CACHE}_DIR`, `OASIS_HUB_{SSB_CONFIG,OASIS_CONFIG}_FILE`, `OASIS_HUB_ALLOW_HOST`, `HUB_CACHE_MAX_SIZE`, `OASIS_HUB_MEM_LIMIT`, `OASIS_HUB_NODE_OPTIONS`, `OASIS_HUB_PUBLIC` (comentada) | ⏳ |
| Validación de rutas | `pub/scripts/common.sh` (`validate_vps_persistent_paths`, `ensure_runtime_dirs`) · `devops/scripts/verify-debian13-base.sh` (`check_layout`) | las tres rutas `OASIS_HUB_*_DIR` absolutas bajo `/srv/oasis` en layout canónico | ⏳ |
| Control de disco | `devops/scripts/hub-disk.sh` (npm `devops:hub-disk`) | `status` · `check` · `prune-blobs` · `prune-cache` · `--json` (§6) | ⏳ |
| Puerta | `pub/site/hub/` (Sala 04) + vestíbulo `pub/site/scriptorium/` + Accesos en `pub/site/index.html` | estático, cero JS, plantilla `pub/site-templates/poster` | ⏳ |
| Gobierno | `plan/BACKLOG.md` WP-O46/WP-O47 · `plan/DECISIONES.md` D-O13 · `CHANGELOG.md` | | ✅ 2026-09-13 |

```
/srv/oasis/                       volumen de datos (40 GB, ext4 por UUID en fstab)
├── oasis-pub/                    estado del pub (INTACTO)
├── teatro/                       obras estáticas (TEATRO-PROTOCOL)
└── oasis-hub/                    estado del nodo de soporte
    ├── ssb-data/                 secret · flume/ · blobs/ · ebt/ · conn.json · gossip.json · oasis-first-contact
    ├── logs/                     bind de /app/logs (sin escritores; simetría con el pub)
    └── http-cache/               proxy_cache de nginx (max_size + inactive=7d)
/opt/oasis-scriptorium/OASIS_PUB/ código y configs (disco de sistema, 25 GB, layout vivo pre-refactor)
    ├── docker-compose.pub.yml    + oasis-hub, hub-cache
    ├── caddy/Caddyfile           + bloque @hub
    └── config/hub/               ssb-config · oasis-config.json · nginx.conf.template
```

Regla de los binds **de fichero** (`Caddyfile`, `ssb-config`, `oasis-config.json`):
sobrescribir **in place** (`cat > fichero`), nunca reemplazar el inode (`mv`, editores
que hacen rename): el contenedor seguiría viendo el fichero viejo.

## 3. Activación (resumen; la secuencia completa está en `v2.md` «Secuencia de deploy»)

```
G0  gates locales con npm run pub:local:up (G1 sintaxis · G2 arranque · G3 invite ·
    G4 caché/cabeceras · G5 aislamiento · G6 memoria · G7 hub-disk) — bloqueantes
1   VPS: líneas base (deploy-status, backup del pub, df/docker stats, secuencia del feed
    del pub, nº de contact) · mkdir /srv/oasis/oasis-hub/{ssb-data,logs,http-cache} con el
    uid de oasis · PRE-CREAR ssb-data/oasis-first-contact (evita el PM de bienvenida) ·
    OASIS_HUB_* en .env.prod (backup previo)
2   subir compose + config/hub/* + Caddyfile in place (SIN reload todavía) · docker pull nginx:alpine
3   bootstrap en dos fases, nada expuesto: OASIS_HUB_PUBLIC=false up -d --no-deps oasis-hub →
    invite.create en el pub → reescribir host a la IP DEL BRIDGE del pub (docker inspect; ssb-ref
    exige IP o dominio con punto, 'oasis-pub' no vale) → POST /settings/invite/accept con Referer
    (siempre 302: verificar POR ESTADO: conn.json del HUB + contact +1 en el pub) →
    hub-conn-fix.js 'net:oasis-pub:8008~shs:<KEY del pub>' (normaliza conn.json; sin esto no
    replica ni reconecta) → docker restart oasis-pub-hub y ver CONNECTED en el log del pub →
    POST /profile/edit (about: name=azofaifo-scriptorium-skin-bot-1 + descripción de §11, sin
    vis_*) → up -d --no-deps oasis-hub (PUBLIC=true) → POST invite/accept = 302 con
    ?error=…public mode… (400 sin Referer; nunca 200) = gate antes de exponer
4   up -d --no-deps hub-cache → MISS/HIT desde la red Docker → caddy validate + caddy reload
    → healthz de los 5 vhosts ajenos
5   site (Sala 04, vestíbulo, Accesos) con deploy-site.sh y fusión de los valores vivos
6   cierre: deploy-status · hub-disk.sh status --json · deploy-log.sh --mode server+hub ·
    a las 24 h ajustar OASIS_HUB_MEM_LIMIT · a los 7 días HUB_CACHE_MAX_SIZE/hops
```

Reglas fijas: **siempre** `docker compose --env-file .env.prod -f docker-compose.pub.yml up -d --no-deps <svc>`;
**nunca** el `deploy.sh` del VPS (hace `up --build` de todo); Caddy = `validate` + `reload`,
nunca `restart pub-web` (WP-O74); el healthcheck del compose no debe pegar a `/c`.

## 4. Verificación (matriz mínima, pública)

```bash
H=https://pub.escrivivir.co; FEED='%40%2FsnvahvaTP5obvdiYva9OX9NNnTSlUQbEUBSuDRzrZA%3D.ed25519'
c() { curl -sS -o /dev/null -w "%{http_code} %{content_type}  $*\n" "$@"; }
c $H/ ; c $H/assets/fanzine.css ; c $H/public/status         # landing intacta (estático)
c $H/c ; c "$H/c/inhabitant/$FEED" ; c $H/clearnet           # 200 · 200 (URI con %40%2F sin decodificar) · 302
curl -sI $H/c | grep -i x-cache-status ; curl -sI $H/c | grep -i x-cache-status   # MISS · HIT
curl -sI $H/c | grep -iE '^(x-frame-options|content-security-policy)' | sort | uniq -c   # 1 de cada; script-src 'none'
c -X POST $H/c                                               # 405 (nginx); 403 si llegara al backend
for p in settings profile publish update json/x qr/x; do curl -sI $H/$p | grep -ci x-cache-status; done   # 0 ×6
curl -s "$H/c/inhabitant/@nadie.ed25519" | grep -c "not accessible"   # 1 — es 200 por diseño upstream
```

En el VPS: `docker ps` → `oasis-pub-scriptorium`, `oasis-pub-hub`, `oasis-pub-hub-cache`
healthy · feed id del pub sin cambios · feed del HUB sin `private` · `df -h /` = línea base ·
`hub-disk.sh check` → 0. Aislamiento: `docker stop oasis-pub-hub` no afecta a `whoami`/`invite`
del pub; `docker stop` del pub deja `/c` sirviendo `STALE` desde la caché.

## 5. Upgrades de Oasis con el HUB activo (leer junto a `UPGRADE-PROTOCOL.md`)

El HUB **no añade guards** a `src/`, pero **depende de comportamientos de upstream que no
son API estable**. Un upgrade puede romperlo sin tocar ninguno de los 4 guards. Por eso:

**5.1 Antes del merge (preflight del HUB).** Sobre el árbol nuevo, cada línea debe dar ≥ 1:

```bash
grep -c 'exec node backend.js' docker-entrypoint.sh                       # modo backend (nuestro, wholesale)
grep -c "require('../server/SSB_server')" src/client/gui.js               # backend requiere el server…
grep -c 'get server()' src/server/SSB_server.js                           # …y el getter crea el sbot embebido
grep -c '\.env("OASIS")' src/client/oasis_client.js                       # OASIS_PUBLIC / OASIS_ALLOW_HOST / OASIS_OPEN
grep -c 'allow-host' src/client/oasis_client.js                           # --allow-host sigue existiendo
grep -c '"/c/inhabitant/:feedId"' src/backend/backend.js                  # ruta del healthcheck
grep -c '"/c/blob/' src/backend/backend.js                                # blobs content-addressed
grep -c 'visibilityPrefs' src/backend/backend.js                          # opt-in por habitante
grep -c 'oasis-first-contact' src/models/onboarding_model.js              # nombre del flag anti-PM de bienvenida
grep -c 'ssbLogStream' src/models/inhabitants_model.js                    # ventana de autores de /c
grep -c 'OASIS_SERVER_CONFIG_OVERRIDE' src/server/ssb_config.js           # guard del fork del que el HUB depende (0 en upstream: es nuestro)
grep -c 'mount("/c/assets"' src/client/middleware.js                     # 1.1.2+: assets del visor bajo /c/assets (location propia en nginx)
grep -on '/c/assets/[a-z]*\|/assets/[a-z]*' src/views/clearnet_view.js | sort -u   # subárboles que Caddy/nginx deben enrutar y cachear
git diff <tag-viejo> oasis-upstream/main -- src/backend/backend.js | grep -o '^+.*\.get("/c/[^"]*"'   # rutas /c/* nuevas → paridad en Sala 04
grep -n 'X-Frame-Options\|Referrer-Policy\|Permissions-Policy' src/client/middleware.js   # lista de proxy_hide_header
```

Si alguna cambia, la pieza afectada de §2 se adapta **en la misma rama del upgrade** y el
gate G4 (cabeceras/URI) se repite en local. `hub-conn-fix.js` depende de la API de ssb-conn
(`conn.forget/remember/connect/peers`) y del comportamiento de ssb-invite: si el upgrade
cambia `ssb-conn` o `ssb-invite` en `src/server/package.json`, repetir el gate G3 en local
(invite + `docker restart` + CONNECTED en el log del pub) antes de subir. Cambios típicos que hay que esperar de
upstream: nombre del flag de bienvenida (→ el HUB publicaría un PM en el siguiente
arranque), rutas nuevas bajo `/c/*` (→ paridad de tipos en la Sala 04), cabeceras nuevas
del backend (→ duplicadas con Caddy hasta añadirlas a `proxy_hide_header`), claves
nuevas en `oasis-config.json`.

**5.2 Ficheros derivados de upstream que se regeneran en cada upgrade.**

- `pub/config/hub/oasis-config.json` **es una copia** de `src/configs/oasis-config.json`
  con 6 claves fijadas (4 difieren del original en 1.0.8; si upstream cambia un default, la
  cifra cambia, las claves no). Tras el overlay: copiar el nuevo y re-aplicar las 6; comprobar
  que el diff son **solo** esas claves:
  `diff <(node -e 'console.log(JSON.stringify(require("./src/configs/oasis-config.json"),null,1))') <(node -e 'console.log(JSON.stringify(require("./pub/config/hub/oasis-config.json"),null,1))')`.
- `pub/config/hub/ssb-config` reemplaza **arrays enteros** de `src/configs/server-config.json`
  (`mergeDeep`): si upstream cambia `connections.incoming/outgoing`, replicar el cambio.
- **Rotación de ciclo** (`UPGRADE-PROTOCOL.md` §5): `caps.shs` también vive en
  `pub/config/hub/ssb-config`. Añadirlo al lockstep. Cambiar el cap no rompe el follow
  (está en los logs), pero HUB y pub deben rotar juntos.

**5.3 Deploy del upgrade con el HUB activo.** La imagen es compartida: tras
`build oasis-pub` y `up -d --no-deps oasis-pub`, el HUB sigue corriendo la imagen
**vieja** (Docker no recrea contenedores por un retag). Orden:

```bash
C="docker compose --env-file .env.prod -f docker-compose.pub.yml"
$C build oasis-pub && $C up -d --no-deps oasis-pub        # pub primero (UPGRADE §4)
bash devops/scripts/deploy-status.sh                       # pub healthy, feed id igual
$C up -d --no-deps oasis-hub                               # HUB después; hub-cache no cambia
docker logs --since 2m oasis-pub-hub | grep -iE 'EROFS|Another Oasis|error'   # nada
docker exec oasis-pub-hub grep -o '"id": *"[^"]*"' /home/oasis/.ssb/secret   # mismo feed id del HUB
bash devops/scripts/hub-disk.sh prune-cache                # si el upgrade reindexó: no servir indexingView 60 s
# matriz §4 · deploy-log.sh … --mode server+hub
```

Mientras el HUB se recrea, `/c` sirve `STALE` desde nginx; el pub no depende del HUB.
**Rollback** del upgrade con HUB: retag de la imagen vieja + `up -d --no-deps --no-build oasis-pub oasis-hub`.

**5.5 Hechos del ciclo 1.0.8→1.1.2 (2026-09-17).** Todos los greps de §5.1 ≥ 1 sobre el árbol
nuevo; `ssb-*` en `src/server/package.json` sin cambios (G3 no se repitió); `oasis-config.json` y
`server-config.json` sin cambios upstream (la copia del HUB no se regeneró; diff = las 4
diferencias efectivas); cabeceras del backend iguales (`proxy_hide_header` intacto).
Lo que sí cambió y cómo se adaptó:

- El visor pasa de `/assets/images` a **`/c/assets/images`** (`app.use(mount("/c/assets", assets))`
  nuevo en `middleware.js`). Caddy `/c/*` ya lo cubría; en nginx caía en la `location` genérica de
  `/c` **sin** `proxy_ignore_headers Cache-Control` → MISS perpetuo. Se añadió `location ~ ^/c/assets/`
  (1 d). Las rutas `/assets/(styles|themes|images)` se mantienen por compatibilidad.
- **Cuatro rutas de detalle nuevas**: `/c/bookmarks/:id`, `/c/feed/:id`, `/c/market/:id`, `/c/wiki/:id`
  (12 → 16 tipos; la guía upstream `clearnet.md` lista 15, omite bookmarks). Paridad en la Sala 04.
- **`/c/qr/:feedId`** nuevo (PNG con `Cache-Control: no-store`): entra por `/c/*` y nginx no lo cachea.
  Codifica `http://localhost:3000/qr-action/follow/…` (`QR_ACTION_BASE` es constante): inútil desde el
  clearnet pero inocuo. La política no cambia: `/qr/*` sigue fuera.
- Opt-in por habitante: tres claves nuevas en `visibilityPrefs` (`clearnetMarket`, `clearnetFeed`,
  `clearnetWiki`); `/profile/clearnet-toggle` desaparece (activar cualquier módulo hace público al
  habitante; apagarlos todos lo retira).
- `onboarding_model.js`: el flag `oasis-first-contact` sigue; añade `adopt(feedId)`. `SSB_server.js`:
  el detalle técnico de lock/corrupción solo se imprime con `--debug`/`OASIS_DEBUG`.
- Overlay en Windows: con `core.autocrlf` los ficheros nuevos salen **CRLF** en el árbol de trabajo;
  `git diff` normaliza, pero un reemplazo literal con `\n` no casa. Detectar el EOL antes de editar.

**5.4 Si cambia la identidad del pub** (recuperación, `RECOVERY-PROTOCOL.md`): el HUB apunta
al pub por clave en `conn.json`. Con el HUB parado, vaciar `conn.json` y `gossip.json` (la
clave vieja en `gossip.json` haría que el nuevo invite respondiera `alreadyFederated`) y
repetir el bootstrap del invite (§3 paso 3). El `secret` del HUB no cambia.

## 6. Disco: mantener el tamaño del HUB

| Ruta (bajo `/srv/oasis/oasis-hub/`) | Crece con | Podable | Quién acota |
|---|---|---|---|
| `ssb-data/flume/log.offset` | replicación (hops 2, incluye `.box` privados ilegibles) | **no** | `friends.hops` en `ssb-config` |
| `ssb-data/flume/*` índices, `ssb-data/ebt/` | el log | sí (rebuild automático) | — |
| `ssb-data/blobs/` | cada `GET /c/blob/<id>` ausente (`blobs.want`, hasta 30 s) + blobs replicados | **sí**: content-addressed, `want` repone al siguiente GET | `hub-disk.sh prune-blobs`, `blobs.max` 50 MB (guard del fork) |
| `http-cache/` | tráfico web | sí | nginx `max_size` + `inactive=7d`; `prune-cache` |
| stdout de los contenedores (`/var/lib/docker`, **disco de sistema**) | tráfico y replicación | sí | `logging.max-size/max-file` del compose |

**Herramienta**: `bash devops/scripts/hub-disk.sh <cmd>` (npm `devops:hub-disk`), SSH al
VPS vía `lib-host.sh`, read-only salvo `prune-*`:

| Comando | Qué hace | Cuándo |
|---|---|---|
| `status` | `df -h / /srv/oasis`, opciones del mount (`noatime`), `du` de flume/blobs/cache/logs y del pub (comparativa), nº de blobs, `docker stats`, `docker system df` | semanal y antes/después de cualquier deploy |
| `check` | umbrales `HUB_DISK_SOFT_PCT=75` / `HUB_DISK_HARD_PCT=90` sobre `/srv/oasis` **y** `/` → exit 0/1/2 | `deploy-status.sh` lo imprime; cron del host |
| `prune-blobs [--older-than N=30] [--dry-run]` | borra blobs no accedidos en N días (`-atime`; con `noatime` cae a `-mtime`). Nunca toca `flume/`, `secret`, `conn.json`, `gossip*.json` | soft en `/srv/oasis` |
| `prune-cache` | vacía `http-cache/` + `nginx -s reload` | tras un rebuild de índices; casi nunca por espacio |
| `--json` | `{ts, srvOasisPct, rootPct, hubFlumeBytes, hubBlobsBytes, hubCacheBytes}` | apéndalo a `devops/logs/hub-disk.jsonl` (no versionado) |

**Cadencia**: `status --json` en el cierre del deploy (línea base), a las 24 h, a los 7
días y después **semanal**; `check` en cada `deploy-status`. Con 30 días de `--json` se
decide el tope duro (WP-O47).

**Árbol de decisión** (`check` ≠ 0):

1. `/srv/oasis` ≥ 75 %: `status` → ¿qué domina?
   - `http-cache/` → bajar `HUB_CACHE_MAX_SIZE` en `.env.prod` y `up -d --no-deps hub-cache`
     (nginx purga solo hasta el nuevo tope).
   - `blobs/` → `prune-blobs --dry-run`, luego `prune-blobs`. Después de una poda grande,
     un reinicio del HUB es más rápido (el entrypoint hace `chown -R` de `blobs/` en cada arranque).
   - `flume/` → el log replicado **no se poda**. Opciones por orden: `friends.hops` 3→2 en
     `ssb-config` + `up -d --no-deps oasis-hub` (acota el crecimiento futuro, no reduce lo
     replicado) · como último recurso, con el HUB parado, vaciar `ssb-data/` **conservando**
     `secret`, `config`, `conn.json`, `gossip.json`, `oasis-first-contact` y dejar que
     re-replique (identidad y follow intactos; `/c` sirve `indexingView` mientras tanto →
     `prune-cache` al terminar).
   - `oasis-pub/` (el pub, no el HUB) → no es de este protocolo; `pub/BACKLOG.md` «métricas de disco».
2. `/` ≥ 75 %: el HUB **no** escribe en `/` salvo los logs json de Docker (ya acotados).
   Es presión de imágenes/builder: `docker system df`, `docker image prune -f && docker builder prune -f`
   (`UPGRADE-PROTOCOL.md` §4).
3. ≥ 90 % en cualquiera: hacer lo anterior **ahora**; si es `/srv/oasis`, `prune-cache` da
   aire inmediato sin coste (la caché se rehace sola).

**Nunca borrar**: `secret` (identidad del HUB), `config`, `conn.json`/`gossip*.json`
(cómo encuentra al pub), `oasis-first-contact`. **Backup**: el HUB es re-derivable de la
red; lo único que vale la pena copiar una vez, tras el bootstrap, es `secret` + `conn.json`
(`devops/backups/oasis-hub/`, no versionado). Sin ellos el rollback nivel 2 es «cuenta
nueva + otro invite», no una pérdida.

**Tope duro** (imagen loop de tamaño fijo o cuota ext4 sobre `/srv/oasis/oasis-hub`) y
`mem_limit` del pub → WP-O47, con datos de 30 días.

## 7. Memoria (el riesgo real del VPS de 4 GB)

`oasis-hub` arranca con `mem_limit` generoso (`OASIS_HUB_MEM_LIMIT`, 1536m) y
`NODE_OPTIONS=--max-old-space-size` ≈ 0,7·límite. A las 24 h: `docker stats` →
`mem_limit = ceil(1,5 · pico)` (mín. 768m). Presupuesto:
`pub + mem_limit + 128m (nginx) + ~150m (caddy) + ~100m (panel) ≤ 3 GB`. Si no cabe, el
orden de rebajas es **`ssbLogStream.limit` → hops 3→2 → nunca el pub** (con hops 2 `/c` se
queda sin habitantes salvo que el pub siga directamente a gente con Clearnet). El pub hoy no tiene
`mem_limit`: un pico del HUB puede empujarlo al OOM-killer → WP-O47.

## 8. Rollback

- **Nivel 1 (< 2 min, sin tocar el pub)**: restaurar `caddy/Caddyfile.bak-hub-<fecha>` in place
  + `caddy validate` + `caddy reload` → `/c` deja de existir públicamente. Opcional
  `$C stop oasis-hub hub-cache`.
- **Nivel 2 (retirar)**: `$C rm -sf oasis-hub hub-cache`; restaurar
  `docker-compose.pub.yml.bak-hub-<fecha>`; `/srv/oasis/oasis-hub` se conserva (identidad
  reutilizable) o se borra si se abandona la cuenta. El `contact` del pub hacia el HUB queda
  en su log (append-only); opcional `unfollow`.
- El `.ssb` del pub no está montado en ningún servicio nuevo: ningún rollback lo toca.

## 9. Realidad del VPS — leer antes de tocar

- Layout vivo `/opt/oasis-scriptorium/OASIS_PUB` (pre-refactor, **sin git**); `.env.prod`
  solo allí. `host.env` dice `…/pub` → exporta `REMOTE_REPO_DIR=/opt/oasis-scriptorium/OASIS_PUB`
  antes de los scripts de `devops/` (nota en `UPGRADE-PROTOCOL.md` §0).
- **Dentro de la imagen viva el árbol también es pre-refactor**: `ssb-admin.js` está en
  `/app/OASIS_PUB/tools/ssb-admin.js`, no en `/app/pub/tools/…` (MODULE_NOT_FOUND en el deploy
  del 2026-09-13). Es la ruta que usa el `scripts/whoami.sh` vivo. Cuando se migre el layout y se
  reconstruya la imagen, volverá a `/app/pub/tools/`.
- El compose vivo tiene el mount del Teatro añadido a mano (`TEATRO-PROTOCOL.md` §6):
  subir el compose del repo **diffeado** contra el vivo, con backup `*.bak-hub-<fecha>`.
- `site/scriptorium/index.html` vivo lleva dos valores propios: fusionar, no pisar.
- Caddy frontea 6 vhosts: tras el `reload`, `healthz` de los 5 ajenos.
- `su` es PID 1 en la imagen: SIGKILL a ~2 s del `stop`; afecta también al HUB (los índices
  de flume se reconstruyen solos).

## 10. Registro

**Activación 2026-09-13 (registro).** Journal: `deploy-log.sh … --version 1.0.8 --cycle 6 --mode server+hub`
a las 20:02:48 UTC (gitSha `7ed4641`). Línea base de disco (`devops/logs/hub-disk.jsonl`, no versionado):
`{"ts":"2026-09-13T20:01:43Z","srvOasisPct":15,"rootPct":49,"hubFlumeBytes":211139,"hubBlobsBytes":0,"hubCacheBytes":92927,"hubMemMiB":112}`.
Memoria al cierre: HUB 113 MiB / 1,5 GiB · pub 88 MiB · Caddy 74 MiB · nginx 5 MiB. Feed del pub sin
cambios (`contact` +1 hacia el HUB). Pub `StartedAt` 2026-09-12 17:02 UTC antes y después: **no se
reinició**. Backups en el VPS con sufijo `.bak-hub-2026-09-13` (compose, `.env.prod`, Caddyfile,
`tools/hub-conn-fix.js`, `site/index.html`, `site/scriptorium/index.html`) y
`config/hub/ssb-config.bak-hub-2026-09-13-seeds`. Reporte: `plan/REPORTES/WP-O46-hub-nodo-soporte.md`.
Pendiente: revisión adversarial con la contraevidencia de `dosier/05` · merge a `main`.

**Desviaciones del plan durante el deploy** (todas corregidas en la rama y en `v2.md`):
ruta viva de `ssb-admin.js` en la imagen (`/app/OASIS_PUB/tools/`, §9) · `seeds` retirado del
`ssb-config` (bloqueaba el invite con `alreadyFederated`) · `hub-conn-fix.js` filtraba la entrada
con seed por host (`7ed4641`) · el contador de `contact` del pub con `grep -c` no se mueve en un log
binario (usar `grep -a -o | wc -l` o buscar `"contact":"<HUB_ID>"`) · el site se subió fichero a
fichero con merge a tres bandas en vez de `deploy-site.sh` (riesgo 10 del plan).

Cada upgrade posterior: §5 completo + una línea del journal con `--mode server+hub`.
Cada semana: §6 `status --json`. Riesgos abiertos heredados del plan (`v2.md` «Riesgos y
decisiones abiertas»): `robots.txt` para `/c/blob/`, 200 que parecen 404 (upstream, WP-O83),
`Cache-Control` en los HTML de `/c`, indexing gate cacheado 60 s tras rebuild.

## 11. Serie de bots de soporte (registro)

Convención de identidad (D-O14): **`<nombre>-<tipo>-bot-<cardinal>`**. El nombre es propio
(Azofaifo), el tipo dice qué vista conecta al pub (`scriptorium-skin` = piel web del Scriptorium),
el cardinal es único en la serie del pub y no se reutiliza. Cada bot es una cuenta SSB propia con
su `.ssb` en `/srv/oasis/<servicio>/`, redime su invite, se declara en su `about` y **no se lista a
sí mismo**. Al dar de alta uno nuevo: fila aquí, su `about` sigue la plantilla, mismo patrón de
contenedor propio + estado en el volumen de datos.

| # | `name` (about) | Tipo | Qué sirve | Contenedor · estado | Feed id | Alta |
|---|---|---|---|---|---|---|
| 1 | `azofaifo-scriptorium-skin-bot-1` | `scriptorium-skin` | HUB clearnet `/c` (Sala 04) | `oasis-pub-hub` · `/srv/oasis/oasis-hub` | `@KM+ZBipR18VSyjNTFjAOnsmz6EiobGYHb3ZCZ4ZxQYI=.ed25519` | 2026-09-13 (WP-O46) |
| 2… | `azofaifo-<tipo>-bot-<n>` | hackería · parlamento · teatro… | la vista que conecte | uno por servicio | | por decidir |

Plantilla del `about` (multipart `name` + `description`, `POST /profile/edit` en fase
`OASIS_HUB_PUBLIC=false`, sin `vis_*`):

```
name:        azofaifo-scriptorium-skin-bot-1
description: Azofaifo · bot scriptorium-skin nº 1. Cuenta de soporte de pub.escrivivir.co:
             sirve la piel web de solo lectura (/c) con lo que cada habitante marcó como
             clearnet. No publica por nadie ni escribe en el pub: replica y muestra.
             Serie: otros bots conectarán las vistas de hackería, parlamento o teatro.
```

El `about` es append-only: un cambio posterior publica otro `about`, el anterior queda en el log.
