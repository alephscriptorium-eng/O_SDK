Mapa de estado --- o-sdk (infra vieja vs. nueva)
==============================================

Repo: `c:\S_LAB\o-sdk` - Solo lectura - Fecha de exploración: 2026-07-25

* * * * *

0 - Resumen ejecutivo (lo que hay que saber antes de leer el detalle)
---------------------------------------------------------------------

| Eje | INFRA VIEJA (a migrar) | INFRA NUEVA (ya adoptada) |
| --- | --- | --- |
| Cuenta git | `github.com/escrivivir-co/*` | `github.com/alephscriptorium-eng/O_SDK` |
| Dominio web del repo | --- | `o-sdk.escrivivir.co` (Pages + CNAME) |
| Dominios de servicio | `pub.escrivivir.co`, `*.scriptorium.escrivivir.co` | `*-sdk.escrivivir.co` (solo `o-sdk` por ahora) |
| Registry npm | (npmjs público implícito) | `https://npm.scriptorium.escrivivir.co` (scopes `@alephscript`, `@zeus`) |
| Repos obsoletos citados | `aleph-scriptorium`, `alephscript-network-sdk`, `BlockchainComPort`, `scriptorium-vps`, `node-red-alephscript-sdk`, `para-la-voz-sdk` | --- |

**Frontera clara**: la raíz del repo (`README.md`, `docs/`, `CHANGELOG.md`, `.npmrc`, `.github/`) **ya está migrada** al esquema nuevo. `pub/site/` **está entero en el esquema viejo** --- es la superficie con más deuda.

**Corrección a la premisa del encargo**: la afirmación de que *«hackería ya enlaza al dominio nuevo»* es **FALSA**. Grep de `-sdk\.escrivivir\.co` sobre todo `pub/site/` → **0 coincidencias**. `pub/site/hackeria/index.html` enlaza únicamente a `escrivivir-co.github.io` y `github.com/escrivivir-co` (líneas 231-233, 264). El único `*-sdk.escrivivir.co` del repo es `o-sdk.escrivivir.co` y vive fuera de `pub/site/`.

* * * * *

1 - Mapa de vhosts / subdominios
--------------------------------

Fuente única: `c:\S_LAB\o-sdk\pub\caddy\Caddyfile` (107 líneas, 6 vhosts). Montado read-only en el contenedor `pub-web` (caddy:2-alpine) --- `pub/docker-compose.pub.yml:68`.

| # | Vhost | Fichero:línea | Backend / contenido | ¿Existe en este repo? |
| --- | --- | --- | --- | --- |
| 1 | `{$OASIS_PUB_WEB_HOST}` → default **`pub.escrivivir.co`** | `pub/caddy/Caddyfile:1` | `/public/*` → `reverse_proxy pub-panel-api:8787` (línea 12); resto → estático `root /srv/site` + `try_files` SPA-fallback (líneas 15-19) | **SÍ**. `pub-panel-api` está definido en `pub/docker-compose.pub.yml:34-56` (build `./panel-api`, código en `pub/panel-api/src/server.mjs`). El estático es el bind `./site:/srv/site:ro` (línea 69) = `pub/site/` |
| 2 | **`scriptorium.escrivivir.co`** | `pub/caddy/Caddyfile:26` | `/healthz` → `respond 200` (34-37); resto → `reverse_proxy scriptorium-nodered:1880` (39) | **NO**. Ningún compose del repo define `scriptorium-nodered` (verificado sobre los 3 composes: `docker-compose.yml`, `pub/docker-compose.pub.yml`, `pub/blobstore-sidecar/deploy/compose.blobstore.fragmento.yml`). **Externo** |
| 3 | **`admin.scriptorium.escrivivir.co`** | `pub/caddy/Caddyfile:42` | mismo upstream `scriptorium-nodered:1880` (56), con `X-Robots-Tag noindex,nofollow,noarchive` (48). Es el editor Node-RED en modo write/projects | **NO --- externo** |
| 4 | **`mcp.scriptorium.escrivivir.co`** | `pub/caddy/Caddyfile:59` | `reverse_proxy scriptorium-mcp-devops:3003` (72). MCP Streamable HTTP + Bearer | **NO --- externo** |
| 5 | **`npm.scriptorium.escrivivir.co`** | `pub/caddy/Caddyfile:75` | `reverse_proxy scriptorium-verdaccio:4873` (89), `X-Robots-Tag noindex` (81) | **NO --- externo**. Es el registry que consume `.npmrc` |
| 6 | **`rooms.scriptorium.escrivivir.co`** | `pub/caddy/Caddyfile:92` | `reverse_proxy scriptorium-rooms:3010` (105). Socket.IO / WSS `/runtime` | **NO --- externo** |

**Nota de acoplamiento (importante para la migración)**: el comentario `pub/caddy/Caddyfile:22-24` lo declara explícitamente --- *«Edge productivo compartido: este Caddy `pub-web` de pub. Upstreams esperados en la red Docker `oasis_pub_net` con aliases `scriptorium-*`»*. Es decir, **este repo posee el edge TLS de 5 servicios cuyo código vive en otro repo** (`escrivivir-co/scriptorium-vps`). `devops/MIGRATION-2026-07.md:36` avisa: *«No reinicies `pub-web` (Caddy) a ciegas: sirve más vhosts»*.

**Vhosts NO presentes** pese a aparecer en diagramas: no hay vhost para `o-sdk.escrivivir.co` (eso lo sirve GitHub Pages, `docs/public/CNAME:1`), ni para `escrivivir.co` raíz.

**Puertos publicados** (`pub/docker-compose.pub.yml`): `pub-web` 80/443 (64-66); `pub-panel-api` sólo `127.0.0.1:8787` (50); `oasis-pub` SSB 8008 (20); `pub-frontend` (profile `frontend`, `127.0.0.1:8080`) --- su contexto de build `${PUB_FRONTEND_DIR:-./frontend}` apunta a `pub/frontend/` que **no existe en el repo** (superficie muerta).

* * * * *

2 - Superficies web `pub/site/`
-------------------------------

### 2.0 - Qué es cada página

| Ruta | Fichero | Qué es |
| --- | --- | --- |
| `/` | `pub/site/index.html` (441 l.) | **Landing pública del pub**. Estética fanzine. Tarjeta "PUB CARD" con host/pubkey/connect/invite rellenados en vivo desde `/public/status` (línea 361) y estado de red desde `/public/network` (390). Incluye dos diagramas ASCII: topología local (285-293) y cableado Caddy + extensión Scriptorium (299-321) |
| `/admin/` | `pub/site/admin/index.html` (411 l.) | **Panel de control local**, estático + JS. Habla con `pub-panel-api` (`/api/pub/status`, `/api/pub/logs`, `/api/pub/restart`) con Bearer token metido a mano. Default API base `127.0.0.1:8788` (local) / `:8787` (VPS). **No enlaza a GitHub ni a dominios externos** --- es la única página limpia de deuda |
| `/hackeria/` | `pub/site/hackeria/index.html` (369 l.) + `catalog.json` (487 l.) | **Sala 01 --- catálogo del taller**. Renderiza `catalog.json` por fetch (337). 8 categorías, ~35 ítems (plugins/SDKs/agentes). Tiene bloque de error con "fuentes canónicas" que apunta a GitHub |
| `/scriptorium/` | `pub/site/scriptorium/index.html` (527 l.) + `catalog.json` + `README.md` | **Vestíbulo**. Puertas a Hackería y Parlament + **PEER CARD** (federación Node-RED vía rooms) + diagrama "Stack - Scriptorium VPS" (404-439). Hace fetch cross-origin a `https://rooms.scriptorium.escrivivir.co/healthz` (506) |
| `/parlament/` | `pub/site/parlament/index.html` (626 l.) + `README.md` | **Sala 02 --- teatro layer2**. Doc conceptual: Room/Firehose/Arrakis BOE/Future-machine, 4 actores, ciclos 60/7/15, ejemplos JSON de `boe.block#0` y `summary_out`. 6 "referencias DRY" que son deep-links a un repo externo |

**Hallazgo estructural**: `pub/site/hackeria/catalog.json` y `pub/site/scriptorium/catalog.json` son **byte-idénticos salvo una línea** --- `"url"` (`:15`: `.../hackeria/` vs `.../scriptorium/`). Ambos declaran `"catalog": "Hackería Scriptorium"` (`:3`). El de `scriptorium/` es un duplicado huérfano: `scriptorium/index.html` **no hace fetch de ningún catalog.json** (no tiene `loadCatalog`). 487 líneas duplicadas a mantener por error.

* * * * *

### 2.a - Enlaces a la cuenta vieja `github.com/escrivivir-co/...`

Todos en `pub/site/`. **17 enlaces** en 6 ficheros:

| Fichero:línea | Destino |
| --- | --- |
| `pub/site/index.html:338` | `github.com/escrivivir-co/aleph-scriptorium/blob/main/LICENSE.md` (footer) |
| `pub/site/index.html:339` | `escrivivir-co.github.io/aleph-scriptorium/` (footer) |
| `pub/site/index.html:341` | `escrivivir-co.github.io/para-la-voz-sdk/` (footer "Demo SDK") |
| `pub/site/hackeria/index.html:231` | `.../aleph-scriptorium/blob/main/.github/plugins/registry.json` |
| `pub/site/hackeria/index.html:232` | `.../aleph-scriptorium/blob/main/.gitmodules` |
| `pub/site/hackeria/index.html:233` | `escrivivir-co.github.io/aleph-scriptorium/` |
| `pub/site/hackeria/index.html:264` | footer (3 enlaces en una línea: LICENSE.md + pages + para-la-voz-sdk) |
| `pub/site/hackeria/catalog.json:14` | `"repo": "https://github.com/escrivivir-co/aleph-scriptorium"` |
| `pub/site/hackeria/catalog.json:374` | `"url": "https://escrivivir-co.github.io/aleph-scriptorium/"` (ítem `gh-pages`) |
| `pub/site/scriptorium/catalog.json:14` | idéntico al anterior |
| `pub/site/scriptorium/catalog.json:374` | idéntico al anterior |
| `pub/site/scriptorium/index.html:313` | `raw.githubusercontent.com/escrivivir-co/scriptorium-vps/...` (bootstrap, ver §2.e) |
| `pub/site/scriptorium/index.html:349` | `github.com/escrivivir-co/node-red-alephscript-sdk/blob/integration/beta/scriptorium/NOD-RED-FED-NOTES/NOTA-AMIGO-DESDE-CERO.md` |
| `pub/site/scriptorium/index.html:519-522` | footer (3 enlaces) |
| `pub/site/parlament/index.html:575, 580, 585, 590, 595, 600` | 6 deep-links a `github.com/escrivivir-co/aleph-scriptorium/blob/integration/beta/scriptorium/VibeCodingSuite/...` (README, Parliament.md, ScriptorioumRoom.md, Firehose.md, ArrakisBoe.md, Future-machine.md) |
| `pub/site/parlament/index.html:623` | footer (3 enlaces) |

Fuera de `pub/site/`, quedan referencias a `escrivivir-co` en:

-   `LICENSE:7` y `LICENSE:96` --- `github.com/escrivivir-co/vibe-bitacora` (proyecto matriz de la licencia AIPL). Semánticamente correcto mantenerlo si el repo matriz sigue ahí.
-   `docs/public/legacy.html:328, 332, 333, 334, 341, 376, 382` --- 7 enlaces a `escrivivir-co/alephscript-network-sdk` (hackaton_261225). Es una página *legacy* servida como asset estático de Pages.
-   `archive/**` --- histórico, ver §2.b.
-   `BASE-3-MECANISMO.md:21` --- patrón de **ceguera** (ver nota abajo).
-   `CHANGELOG.md:50` --- afirma *«referencias a `escrivivir-co` retiradas de README y portal»* --- cierto para README/portal VitePress, **falso para `pub/site/` y `docs/public/legacy.html`**.

> **Nota de gobierno relevante**: `BASE-3-MECANISMO.md:21` declara `mundo.ceguera = /(escrivivir-co\/|pub\.escrivivir\.co|@tMJzSfcZ|secret\b)/` --- *«la cara pública no filtra la cuenta origen anulada, el host del pub privado ni material de identidad»*. Es decir, la propia doctrina del repo ya marca `escrivivir-co/` como **cuenta anulada que no debe aparecer en superficie pública**. `pub/site/` viola ese filtro en 17 sitios.

* * * * *

### 2.b - Referencias a repos / nombres obsoletos

**En superficie viva (`pub/site/`)** --- pocas pero visibles:

| Fichero:línea | Referencia obsoleta |
| --- | --- |
| `pub/site/hackeria/catalog.json:336` | `"source": "BlockchainComPort/"` (ítem `network` / PLG-WIR-04) |
| `pub/site/scriptorium/catalog.json:336` | idéntico (duplicado) |
| `pub/site/hackeria/catalog.json:385` y `scriptorium/catalog.json:385` | `"source": "O_SDK/pub/"` --- nombre de carpeta del repo nuevo pero como si fuera submódulo del monorepo viejo |
| `pub/site/hackeria/catalog.json:10` y `scriptorium/catalog.json:10` | `"agents": "ARCHIVO/DEVOPS/Funcional.md"` --- layout del monorepo viejo; todos los `links.data` (`ARCHIVO/PLUGINS/...`) apuntan a rutas que no existen aquí |
| `pub/site/scriptorium/index.html:313` | repo `scriptorium-vps` |
| `pub/site/scriptorium/index.html:349` | repo `node-red-alephscript-sdk` |

**En `archive/`** (histórico declarado, no operativo) --- `alephscript-network-sdk` aparece **284 veces**: `archive/pub/README_CHAT.md` (107), `archive/HACKATON_GUIDE.md` (92), `archive/devops/pub-federation.md` (74), `archive/README-SCRIPTORIUM.md` (3), `archive/devops/remote-logs.md` (2), `archive/session-backlog/ECOIN_DOCKER_HANDOFF_REPORT_2026-04-28.md` (2), `archive/session-backlog/SESION-BACKLOG-EXPANSION.md` (2), `archive/session-backlog/SESION-BACKLOG.md` (1), `archive/README.md` (1). Casi todas son **rutas locales de disco** (`C:\Users\aleph\OASIS\alephscript-network-sdk\...`), no URLs → no son deuda de enlaces rotos.

`archive/README.md:9-16` ya documenta la tabla de equivalencias vieja→nueva, incluyendo `| repos BlockchainComPort, alephscript-network-sdk | alephscriptorium-eng/O_SDK |`. **Archive está correctamente señalizado; no requiere migración.**

**En `src/`**: cero referencias a infraestructura Escrivivir/Scriptorium. `src/` es overlay 1-1 del upstream Oasis (epsylon/oasis) --- limpio.

* * * * *

### 2.c - Enlaces al esquema nuevo `*-sdk.escrivivir.co`

**Total en el repo: 11 ocurrencias, todas de `o-sdk.escrivivir.co`, y NINGUNA dentro de `pub/site/`.**

| Fichero:línea | Contexto |
| --- | --- |
| `docs/public/CNAME:1` | `o-sdk.escrivivir.co` --- custom domain de Pages |
| `docs/.vitepress/config.mjs:6` | comentario sobre `base` |
| `docs/.vitepress/config.mjs:26` | `pages: 'https://o-sdk.escrivivir.co'` (objeto `BACK`) |
| `docs/proyecto.md:18` | «Pages. Este sitio, servido en `o-sdk.escrivivir.co`» |
| `.github/workflows/docs.yml:1` | comentario de cabecera |
| `README.md:10` | badge `web-o--sdk.escrivivir.co` |
| `README.md:18` | línea Web & docs |
| `README.md:77` | «Todo el portal FOSS vive en...» |
| `README.md:82` | tabla de documentación |
| `CHANGELOG.md:4` | cabecera |
| `CHANGELOG.md:38` | entrada Added |
| `BASE-2-SISTEMA.md:42` | «Dominio del mundo: `o-sdk.escrivivir.co` (Pages, custom domain → base `/`)» |

Referencia adicional al esquema nuevo desde una dependencia: `node_modules/@alephscript/skills-scriptorium/package.json:44` → `"homepage": "https://skills.s-sdk.escrivivir.co"` (confirma que el patrón `<x>-sdk.escrivivir.co` es la convención de familia: `o-sdk`, `s-sdk`, y por el pie del portal se menciona `Z_SDK/S_SDK`).

**Veredicto sobre la premisa**: `pub/site/hackeria/` **no** usa el dominio nuevo. Cero páginas de `pub/site/` lo usan.

* * * * *

### 2.d - Subdominios `*.escrivivir.co` usados en `pub/site/`

| Subdominio | Dónde aparece (fichero:línea) |
| --- | --- |
| `pub.escrivivir.co` | `index.html:156, 181, 304, 366`; `hackeria/catalog.json:15`; `scriptorium/catalog.json:15`; `scriptorium/README.md:94` |
| `scriptorium.escrivivir.co` | `index.html:308`; `scriptorium/index.html:409` (solo diagramas ASCII, no `<a href>`) |
| `admin.scriptorium.escrivivir.co` | `index.html:311`; `scriptorium/index.html:414` (diagramas) |
| `rooms.scriptorium.escrivivir.co` | `index.html:314`; `scriptorium/index.html:272, 293, 342, 351 (href real), 417, 506 (fetch JS real)` |
| `mcp.scriptorium.escrivivir.co` | `index.html:317`; `scriptorium/index.html:425` (diagramas) |
| `npm.scriptorium.escrivivir.co` | `index.html:320`; `scriptorium/index.html:431` (diagramas) |
| `escrivivir.co` (raíz) | `index.html:340`; `hackeria/index.html:264`; `scriptorium/index.html:521`; `parlament/index.html:623` (footers); contacto `secretaria at escrivivir.co` en `index.html:240` |

Solo **dos** son enlaces/llamadas ejecutables a `rooms.*` (`scriptorium/index.html:351` href, `:506` fetch); el resto de subdominios `*.scriptorium.*` son texto dentro de `<pre class="diagram">`.

* * * * *

### 2.e - Menciones socket.io / node-red / rooms / ROOMS_ / mesh / peercard (todo el repo)

**En `pub/site/` (superficie pública):**

| Fichero:línea | Contexto (1 línea) |
| --- | --- |
| `pub/site/index.html:315` | `wss://.../runtime (Socket.IO - shared-secret)` --- diagrama del vhost rooms |
| `pub/site/index.html:308, 311` | `scriptorium.escrivivir.co ──▶ scriptorium-nodered:1880` |
| `pub/site/scriptorium/index.html:260` | comentario HTML `<!-- PEER CARD --- fedérate al Pub.Rooms con tu Node-RED -->` |
| `pub/site/scriptorium/index.html:269-272` | bloque `SCRIPTORIUM - ROOMS` / `rooms.scriptorium.escrivivir.co - Node-RED mesh peer` |
| `pub/site/scriptorium/index.html:300-304` | campo `TOKEN (PUBLIC_ROOM)` con **un valor de 40 chars hardcodeado** ⚠️ (ver alerta abajo) |
| `pub/site/scriptorium/index.html:313` | comando bootstrap con `ROOMS_USER` / `ROOMS_ROOM` / `ROOMS_SECRET` (ver detalle) |
| `pub/site/scriptorium/index.html:330` | `~/.node-red/.env.rooms` (permisos 600) |
| `pub/site/scriptorium/index.html:335-336` | `source ~/.node-red/.env.rooms && node-red`, importar `flows_pub-room-client.json` |
| `pub/site/scriptorium/index.html:342` | `curl -I https://rooms.scriptorium.escrivivir.co/healthz` |
| `pub/site/scriptorium/index.html:417-423` | diagrama: `wss://.../runtime Socket.IO + shared-secret` - alias `scriptorium-rooms` - persistencia `/run/secrets/rooms` |
| `pub/site/scriptorium/index.html:436-437` | paquetes `node-red-contrib-alephscript-core@0.2.0`, `node-red-dashboard-2-alephscript-rooms@0.2.0` |
| `pub/site/scriptorium/index.html:481, 501-506` | JS: copy-to-clipboard de la peer card + healthz check de rooms |
| `pub/site/parlament/index.html:327` | `Usa MAKE_MASTER sobre Socket.IO mesh` |
| `pub/site/parlament/index.html:283, 326, 330, 379, 469, 556, 583-584` | Room / `MAKE_MASTER` / `ROOM_MESSAGE` / `CLIENT_REGISTER` / `CLIENT_SUSCRIBE` (conceptual) |
| `pub/site/hackeria/catalog.json:399, 402` (y gemelo en `scriptorium/`) | `Mesh de servidores MCP via Socket.IO (puerto 3010)` - tags `mesh`, `socket.io` |
| `pub/site/hackeria/catalog.json:297-323` (y gemelo) | 3 ítems `node-red` (Wire Editor, Escribiente, WiringApp) |
| `pub/site/parlament/README.md:11, 21` | `ScriptorioumRoom.md`; «arranca sesión: snapshot, room, inhabitants, BOE inicial» |
| `pub/site/admin/index.html:125` | `Control room local` (falso positivo, no es "rooms") |

**En infra:** `pub/caddy/Caddyfile:39, 56` (nodered), `:92-105` (rooms).

**En `CHANGELOG.md:30-31`**: *«Retirado un `ROOMS_SECRET` en claro de `pub/site/scriptorium/index.html` (página servida públicamente): rotar el secret en el servidor de rooms.»*

**En `archive/`**: `archive/session-backlog/README.md:111` (`arquitectura Zeus → mcp-model-sdk → mcp-mesh-sdk`), `archive/session-backlog/SCRIPTORIUM_INTEGRATION_OPPORTUNITIES.md:55, 153, 421` (`mcp-mesh-sdk (3003)`, `ai.mcpMeshUrl`, `"mcpMeshUrl": "http://mcp-mesh:3003"`).

**En `src/`**: solo falsos positivos --- `src/AI/routes_index.js:17, 33, 96, 97` («private rooms», «encrypted rooms» del módulo Tribes/Chats de Oasis), `src/models/logs_model.js:56` (`opened a chat room`). El regex `mesh` matcheó `ga**mesH**allOfFame` en 12 ficheros de traducción --- ruido. **`src/` no tiene integración rooms/mesh real.**

**En `.claude/skills/`** (espejo materializado): `operador-rooms/` completo (`reference/peercard.md`, `reference/acl.md`), `estacion-viva/` con `GAME_MCP` + peercard (`reference/GAME-MCP.md`, `scripts/reproduce-boot.sh:117-128`, `examples/fixture-tick-cero/peercard.json`).

#### ⚠️ Alerta de seguridad --- token todavía presente

`pub/site/scriptorium/index.html:303` contiene un **valor literal de 40 caracteres** en el campo `TOKEN (PUBLIC_ROOM)`, dentro de un `<code id="val-rooms-token">` con botón COPY. El `CHANGELOG.md:30` afirma que el `ROOMS_SECRET` fue retirado --- y en efecto en la línea **313** el comando bootstrap ya lleva el placeholder `ROOMS_SECRET="PIDE-EL-SECRET-AL-ADMIN"`. **Pero la línea 303 sigue con un valor real hardcodeado en una página que se sirve públicamente** (`/srv/site` vía `pub-web`, y desplegada por rsync con `devops/scripts/deploy-site.sh`). Revisar si es el mismo secreto o un token de sala distinto; el saneado de la 313 no cubrió la 303.

#### Bootstrap `bootstrap-mesh-client.sh` (referencia externa, no accedida)

Citado en `pub/site/scriptorium/index.html:313`. La URL documentada es:

```
raw.githubusercontent.com/escrivivir-co/scriptorium-vps
  /integration/beta/scriptorium/scripts/bootstrap-mesh-client.sh

```

Se invoca con `curl -fsSL ... | ROOMS_USER="TU-ALIAS" ROOMS_ROOM="PUBLIC_ROOM" ROOMS_SECRET="..." bash`.

Qué hace, **según la propia página** (`:326-343`, no verificado contra el script --- es externo y no se ha accedido a internet):

1.  **BOOTSTRAP** --- instala los *contribs* de Node-RED y escribe `~/.node-red/.env.rooms` con permisos 600.
2.  **ARRANCAR** --- `source ~/.node-red/.env.rooms && node-red`, importar el flow `flows_pub-room-client.json` y hacer Deploy.
3.  **VERIFICAR** --- el nodo pasa a verde `connected`; salud alternativa `curl -I https://rooms.scriptorium.escrivivir.co/healthz`.

Los contribs implicados están nombrados en el diagrama (`:436-437`): `node-red-contrib-alephscript-core@0.2.0` y `node-red-dashboard-2-alephscript-rooms@0.2.0`, publicados en `npm.scriptorium.escrivivir.co`.

**Deuda de migración**: es un `curl | bash` desde la **cuenta vieja** hacia una **rama vieja** (`integration/beta/scriptorium`), publicado en una página pública. Doble dependencia (repo `scriptorium-vps` + branch) que hay que reapuntar.

* * * * *

3 - Registry y dependencia de GitHub
------------------------------------

### 3.1 - `.npmrc` (raíz, 3 líneas)

`c:\S_LAB\o-sdk\.npmrc`:

-   `:1` → `@alephscript:registry=https://npm.scriptorium.escrivivir.co`
-   `:2` → `@zeus:registry=https://npm.scriptorium.escrivivir.co`
-   `:3` → `save-exact=true`

Dos scopes mapeados al Verdaccio propio. El scope `@zeus` está **declarado pero no usado**: cero paquetes `@zeus/*` instalados o referenciados en el repo. El futuro scope `z-sdk` no aparece en ninguna parte (0 coincidencias). Todo lo demás resuelve contra el registry por defecto de npm.

Confirmación de resolución efectiva: `package-lock.json:21` → `"resolved": "https://npm.scriptorium.escrivivir.co/@alephscript/skills-scriptorium/-/skills-scriptorium-0.11.0.tgz"`.

### 3.2 - `docs/.vitepress/config.mjs` --- objeto `BACK` (fuente única, líneas 22-30)

| Clave | Línea | Valor |
| --- | --- | --- |
| `repo` | `:23` | `https://github.com/alephscriptorium-eng/O_SDK` |
| `registry` | `:24` | `https://npm.scriptorium.escrivivir.co` |
| `actions` | `:25` | `https://github.com/alephscriptorium-eng/O_SDK/actions` |
| `pages` | `:26` | `https://o-sdk.escrivivir.co` |
| `changelog` | `:27-28` | `https://github.com/alephscriptorium-eng/O_SDK/blob/main/CHANGELOG.md` |
| `issues` | `:29` | `https://github.com/alephscriptorium-eng/O_SDK/issues` |

Consumido en: `backLinks` (`:32-38`, expone Repositorio/Registry/CI/Pages/Issues), `nav` (`:71`), `socialLinks` (`:89`), `footer.message` (`:95-105`, `v-html` con repo-registry-CI-proyecto). **`changelog` está definido pero no consumido** en ningún `backLinks`/nav/footer --- dato muerto.

**Buena noticia para migrar**: 5 de las 6 URLs de GitHub del portal salen de este único objeto. Cambiar la org = editar `config.mjs:23-29`.

### 3.3 - `README.md` raíz --- badges y enlaces a github.com

| Línea | Elemento |
| --- | --- |
| `:10` | badge shields.io `web-o--sdk.escrivivir.co` → enlaza a `https://o-sdk.escrivivir.co` (no a GitHub) |
| `:11` | badge `oasis-0.8.8` → `https://solarnethub.com/` |
| `:12` | badge `docker-compose` → ancla interna `#-quickstart` |
| `:13` | badge `protocol-SSB` → `https://scuttlebutt.nz` |
| `:14` | badge `status-WIP` → ancla interna |
| `:15` | badge `PRs-welcome` → **`https://github.com/alephscriptorium-eng/O_SDK/issues`** |
| `:16` | badge `license-AIPLv1` → `LICENSE` (relativo) |
| `:18` | **`https://github.com/alephscriptorium-eng/O_SDK`** (línea Web & docs) |
| `:31` | `https://github.com/epsylon/oasis` (upstream, correcto) |
| `:59` | `git clone https://github.com/alephscriptorium-eng/O_SDK.git` |
| `:146` | `github.com/epsylon/oasis` (créditos upstream) |

Total: **3 enlaces a la org nueva** + 2 al upstream ajeno. Ningún `escrivivir-co` en README (confirmado: 0 coincidencias). Los badges usan `img.shields.io` --- dependencia de terceros para renderizado, no de GitHub.

Duplicados de estas mismas URLs fuera del README: `CHANGELOG.md:4`, `CHANGELOG.md:49`, `docs/index.md:34` (clone) y `docs/index.md:41-42` (enlace FOSS) --- estos **no** salen de `BACK`, están hardcodeados.

### 3.4 - `.github/workflows/docs.yml` --- qué depende de GitHub

Único workflow del repo (63 líneas, `.github/` no tiene nada más).

| Elemento | Línea | Dependencia GitHub |
| --- | --- | --- |
| triggers `push` (`main`, `wp/**`), `pull_request`, `workflow_dispatch` | `:6-17` | **GitHub Actions** (motor de CI) |
| `actions/checkout@v4` | `:28` | action del marketplace |
| `actions/setup-node@v4` (node 22, `cache: npm`) | `:29-32` | action + **caché de Actions** |
| `npm ci` | `:34` | resuelve `@alephscript/*` contra Verdaccio (no GitHub) --- pero necesita **credenciales/acceso al registry desde el runner** |
| `npm run skills:sync` | `:38` | materializa `.claude/skills/` desde `node_modules` (script local `scripts/sync-claude-skills.mjs`) |
| `npm run docs:build` | `:40` | VitePress |
| gate `verificar-sitio.mjs --dist docs/.vitepress/dist --base /` | `:42` | script que viene **del paquete del registry**, no de GitHub |
| `actions/upload-pages-artifact@v3` | `:39-47` | **GitHub Pages (artifact)** |
| job `deploy` + `permissions: pages:write, id-token:write` + `environment: github-pages` + `actions/deploy-pages@v4` | `:49-62` | **GitHub Pages (deploy OIDC)** |

Nota de fragilidad: `:35-36` documenta que `.claude/skills/` **no está versionado** (confirmado en `.gitignore:72-76`, que ignora `.claude/skills/`, `.cursor/skills/`, `.openai/skills/`) → **el CI no puede construir si el registry privado está caído o inaccesible desde el runner**. Es un acoplamiento CI↔Verdaccio de un solo punto de fallo.

### 3.5 - Tabla --- dependencias de GitHub hoy

| Servicio GitHub | ¿Se usa? | Evidencia | Qué habría que tocar para migrar |
| --- | --- | --- | --- |
| **Hosting git (remoto)** | **Sí** | `README.md:18,59`; `docs/index.md:34,41`; `config.mjs:23`; `CHANGELOG.md:4,49` | `git remote set-url` + 8 URLs hardcodeadas. Las 5 del portal salen de `config.mjs:23-29` (1 edición); las de `README.md`, `docs/index.md` y `CHANGELOG.md` son manuales |
| **GitHub Pages** | **Sí (crítico)** | `docs.yml:44-47, 49-62`; `docs/public/CNAME:1`; `docs/proyecto.md:18` | Es la dependencia **más difícil de sustituir**: hay que reemplazar el hosting estático + el CNAME + la validación de dominio. Alternativa natural: servir `docs/.vitepress/dist` desde el propio Caddy de `pub/` con un vhost `o-sdk.escrivivir.co` (la infra ya existe) |
| **GitHub Actions** | **Sí (crítico)** | `docs.yml` completo; `config.mjs:25` (`actions:` back-link) | Sustituir por un runner propio (Forgejo/Woodpecker/cron en el VPS). Hay 3 actions de terceros (`checkout`, `setup-node`, `upload-pages-artifact`/`deploy-pages`) --- las dos últimas son **específicas de Pages** y no tienen equivalente directo |
| **Issues** | **Declarado, uso indirecto** | `README.md:15` (badge PRs-welcome); `config.mjs:29` + `backLinks:37` | 2 URLs. Pero ver §4: el skill `swarm-orquestacion` trae `proyectar-backlog.mjs`, que **proyecta el backlog local a GitHub Issues vía `gh` CLI** --- si se activa, la dependencia pasa a ser funcional |
| **Releases** | **NO** | 0 coincidencias de `releases`/`gh release` en workflows o scripts | Nada que migrar |
| **GitHub Packages / registry npm** | **NO** | `.npmrc` apunta a Verdaccio propio; `package-lock.json:21` confirma | Ya migrado ✅ |
| **raw.githubusercontent.com** | **Sí (superficie pública)** | `pub/site/scriptorium/index.html:313` (`curl | bash`) | Reapuntar a un host propio o al repo nuevo. Ver §2.e |
| **`escrivivir-co.github.io` (Pages de la org vieja)** | **Sí (enlaces salientes)** | 6 páginas de `pub/site/` + `docs/public/legacy.html` | Depende de si esos sitios se migran o se congelan |
| **shields.io** | Sí (terceros, no GitHub) | `README.md:10-16` | Solo si se quiere autonomía total de badges |

* * * * *

4 - Paquetes `@alephscript` / skills
------------------------------------

### 4.1 - `node_modules/@alephscript/skills-scriptorium`

`node_modules/@alephscript/skills-scriptorium/package.json`:

| Campo | Línea | Valor |
| --- | --- | --- |
| `name` | `:2` | `@alephscript/skills-scriptorium` |
| `version` | `:3` | **`0.11.0`** |
| `private` | `:4` | `false` |
| `bin` | `:10-12` | `alephscript-skills-sync` |
| `author` / `maintainers` | `:32-38` | `alephscriptorium-eng` / `ops@escrivivir.co` |
| `license` | `:39` | `UNLICENSED` |
| `repository` | `:40-43` | `github.com/alephscriptorium-eng/S_SDK-skills-library` |
| `homepage` | `:44` | `https://skills.s-sdk.escrivivir.co` |
| `publishConfig` | `:45-48` | `access: public`, `registry: https://npm.scriptorium.escrivivir.co` |

**Scope**: `@alephscript` (viejo por nomenclatura, pero **publicado y mantenido por la org nueva** `alephscriptorium-eng` en el registry nuevo). Es un caso híbrido: el *scope* es legado, la *infraestructura* es nueva. Si el plan es `z-sdk`, este es el paquete a re-scopear.

Declarado en `package.json:83` como `"@alephscript/skills-scriptorium": "0.x"` (devDependency) --- nota: `save-exact=true` en `.npmrc` pero el rango es `0.x`, inconsistencia menor; el lock fija 0.11.0.

### 4.2 - Carpeta `skills/` del paquete (7 skills + 1 plantilla)

| Skill | Descripción (frontmatter, resumida) |
| --- | --- |
| `_plantilla` | `plantilla-skill` --- plantilla vacía para crear skills marco-agnósticos |
| `estacion-viva` | Boot de estación viva: regenerar estado desde bitácora, watcher con whitelist, pulso, **conexión al juego (GAME_MCP + peercard firmada + kit del registry)**, salida dual PO/scrum. Params `WORLD_ROOT`, `GAME_MCP`, `OUT_DIR` |
| `holarquia` | Cadena de holones: dos leyes (ceguera ascendente, acceso descendente), crecimiento por junturas, DS-5, acuerdo de agente |
| `intake-prueba-de-dos` | Convertir un intake en skill materializable con contrato mínimo + ejemplo sintético |
| `operador-rooms` | Operar **rooms con peercard, ACL y salud** sin depender de memoria de sesión |
| `site-web` | Copy + protocolo de publicación web (VitePress, Pages, piel declarada) |
| `swarm-orquestacion` | Protocolo de swarm: roles, ciclo prep→worker→revisión→merge, BRIEF, 5 ejes de CA por tipo de WP |
| `vigilancia` | Vigilancia read-only del swarm: pulso de worktrees/locks/CI, multi-carril, C8, addenda dos caras, watcher fail-closed |

### 4.3 - ¿Existe `proyeccion-backlog`?

**No como skill.** No hay ninguna carpeta `proyeccion-backlog` (ni variante) en `skills/`. **Pero la funcionalidad existe, embebida en `swarm-orquestacion`**:

-   `skills/swarm-orquestacion/scripts/proyectar-backlog.mjs` (herramienta)
-   `skills/swarm-orquestacion/reference/proyeccion-issues.md` (método)
-   Declarado en `skills/swarm-orquestacion/SKILL.md:205`

**Resumen en 5 líneas:**

1.  Proyecta el backlog markdown local (`plan/BACKLOG.md`) a un tracker de issues externo; **no es sync bidireccional** --- el markdown es fuente de verdad única y los issues son artefacto desechable regenerable.
2.  `export` local→remoto es idempotente (mapa `plan/.sync-map.json` WP-ID→nº issue + marcador oculto `<!-- proyeccion:ID -->` en el body); mapeo `✅`→closed, `⬜`/`🔶`→open, sin labels; auto-cierra issues cuyo WP salió del conjunto.
3.  `import` trae lo remoto a `plan/INBOX-GH.md` --- **jamás escribe el BACKLOG**; la reconciliación la hace a mano el orquestador.
4.  **Qué necesita**: Node ≥18 + **`gh` CLI autenticado** (adaptador GitHub) → **sí depende de GitHub Issues y del CLI**, aunque el diseño es marco-agnóstico (adaptador sustituible). No usa GitHub Actions.
5.  **Fail-safes**: modo por defecto **LOCAL-ONLY** (`DC-15`) --- el export real rehúsa sin `--habilitar-github` / `PROYECCION_GITHUB=1`; y **gate de ceguera** (`DC-12`) que valida el contenido contra `CEGUERA_PATTERN` (regex por env, nunca almacenada en el skill) antes de exportar a un tracker público --- sin patrón, rehúsa. Además falla ruidosamente si el backlog parsea a 0 WPs.

> Conexión con §2.a: el `CEGUERA_PATTERN` que este repo declararía es el de `BASE-3-MECANISMO.md:21`, que incluye `escrivivir-co\/` --- o sea, **si hoy se intentara proyectar el backlog a issues públicos, el gate de ceguera bloquearía cualquier contenido que mencione la cuenta vieja**. Coherente con el objetivo de migración.

### 4.4 - `.claude/skills/` instalados

`.claude/skills/README.md` (generado, no editar a mano) declara: procedencia `@alephscript/skills-scriptorium@0.11.0`, origen `node_modules/.../skills/`, generador `alephscript-skills-sync --runtime claude`. **7 skills** (el paquete trae 8 carpetas; `_plantilla` no se materializa).

| Skill instalado | Descripción (1 línea) | rooms / peercard / Ciudad / juego / GAME_MCP |
| --- | --- | --- |
| `estacion-viva` | Boot de estación viva: bitácora→estado, watcher, pulso, conexión al juego, salida dual PO/scrum | ✅ **peercard**, ✅ **juego**, ✅ **GAME_MCP** |
| `holarquia` | Cadena de holones: ceguera ascendente / acceso descendente, junturas, DS-5 | --- |
| `intake-prueba-de-dos` | Intake → skill materializable con contrato mínimo y ejemplo sintético | --- |
| `operador-rooms` | Operar rooms con peercard, ACL y salud sin memoria de sesión | ✅ **rooms**, ✅ **peercard** |
| `site-web` | Copy + protocolo de publicación web (VitePress, Pages, piel declarada) | --- |
| `swarm-orquestacion` | Protocolo de swarm: roles, ciclo, BRIEF, CA por tipo de WP | --- |
| `vigilancia` | Vigilancia read-only del swarm: pulso, C8, addenda dos caras, watcher fail-closed | --- |

**Ninguno menciona "Ciudad"** (0 coincidencias en `.claude/`).

Ficheros concretos con `peercard` / `GAME_MCP` / `juego`:

-   `.claude/skills/estacion-viva/SKILL.md:6-8, 26, 35, 51, 58, 65, 76`
-   `.claude/skills/estacion-viva/reference/GAME-MCP.md:1, 3-4, 8-13, 32, 36-45, 54-55` (fase 5 del boot; `GAME_MCP` obligatorio; peercard firmada con `id`+`sig`; `features` incluye `juego`)
-   `.claude/skills/estacion-viva/reference/BOOT.md:4, 18, 57-61, 81`
-   `.claude/skills/estacion-viva/scripts/reproduce-boot.sh:15, 21, 117-128, 139-140, 159, 173`
-   `.claude/skills/estacion-viva/examples/fixture-tick-cero/peercard.json:5` (`"features": ["juego","peercard"]`)
-   `.claude/skills/estacion-viva/examples/fixture-tick-cero/bitacora/linea.mdl:4` (`juego.listo | endpoint=mcp://fixture-tick-cero`)
-   `.claude/skills/estacion-viva/reference/SALIDA-DUAL.md:20`
-   `.claude/skills/operador-rooms/reference/peercard.md:1, 7`
-   `.claude/skills/operador-rooms/reference/acl.md:3`

Hay un **segundo espejo idéntico** en `.cursor/skills/` (mismas 7 skills), también ignorado por git (`.gitignore:75`). El script generador local es `scripts/sync-claude-skills.mjs` (`package.json:74`) --- nota: **no** usa el `bin` del paquete (`alephscript-skills-sync`), sino un script propio del repo.

### 4.5 - Otros `@alephscript` / menciones a `npm.scriptorium`

| Fichero:línea | Qué |
| --- | --- |
| `pub/blobstore-sidecar/package.json:2` | **`"name": "@alephscript/blobstore-sidecar"`** --- segundo paquete con scope viejo, este **fuente propia dentro del repo** (código en `pub/blobstore-sidecar/src/`, tests en `test/`). Candidato directo a re-scopear a `z-sdk`/nuevo |
| `.npmrc:1-2` | mapeo de scopes `@alephscript` y `@zeus` |
| `package.json:83` | devDependency `@alephscript/skills-scriptorium: 0.x` |
| `package-lock.json:15, 19, 21` | resolución vía `npm.scriptorium.escrivivir.co` |
| `docs/.vitepress/config.mjs:24` | `registry:` back-link |
| `docs/proyecto.md:12` | «skills de agente (`@alephscript/skills-scriptorium`) se instalan desde el registry privado» |
| `.github/workflows/docs.yml:36` | comentario sobre el paquete |
| `CHANGELOG.md:42` | entrada Added |
| `.gitignore:72` | comentario del espejo |
| `pub/caddy/Caddyfile:75-89` | vhost del registry |
| `pub/site/index.html:320-321` | diagrama: `npm.scriptorium.escrivivir.co ─▶ scriptorium-verdaccio:4873` - `@alephscript/*` |
| `pub/site/scriptorium/index.html:431-437` | diagrama con paquetes publicados: `@alephscript/mcp-core-sdk@1.4.0`, `node-red-contrib-alephscript-core@0.2.0`, `node-red-dashboard-2-alephscript-rooms@0.2.0` |

**Inventario de scopes**: `@alephscript` (2 usos: 1 dependencia instalada + 1 paquete propio en `pub/blobstore-sidecar/`), `@zeus` (declarado en `.npmrc:2`, **0 usos**), `z-sdk` (**0 coincidencias en todo el repo**).