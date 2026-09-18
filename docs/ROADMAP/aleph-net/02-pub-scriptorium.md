# 02 — El pub scriptorium (`o-sdk`) y su modelo de datos

Leyenda: [V] leído · [E] reportado por exploración, sin cotejo · [NV] · `<pendiente>`. Ver `00-indice.md`.

Estado de o-sdk hoy: Oasis 1.1.2 desplegado 2026-09-17 (WP-O97); cliente
fresco + importación de identidad (WP-O98); HUB clearnet activo desde
2026-09-13 (WP-O46). `git log` [V]: `7adb5e2`, `54581be`, `b748b0f`,
`780f5ce`, `67b1ead`, `e16c455`, `b19dd1f`, `d5b5618`, `c839246`, `f6f4fbb`,
`e545d21`, `588950c`, `b6ec5b2`, `17db665`, `d1047c0`.

## Doctrina de capas (la que manda en la casa)

| Enunciado | Dónde |
| :-- | :-- |
| «**L1 = el pub** (pub.escrivivir.co): identidad por clave, gossip, persistencia append-only. Capa que no se apaga.» | `scriptorium/plan/VISION.md:10` [E] |
| «**L2 = las ciudades**: estado de juego volátil-persistente anclado a L1 vía artefactos firmados (partes, actas, peercards).» | `VISION.md:12` [E] |
| «**G3** («el parte viaja por el pub») = checkpoint L2→L1. Federación doctrinal vía pub, no compartiendo rooms.» | `VISION.md:14` [E] |
| «**o-sdk**: infraestructura del puente L2→L1. Fresh-start, cero arqueología (§F3a).» | `VISION.md:16`; `MAPA-TALLER.md:25` [E] |
| «El puente L2→L1 es obra del mundo o-sdk (el puerto)»; «Ningún jugador privilegiado»: humano con credencial federada, agente por MCP con la misma tarjeta firmada, residente autómata | `scriptorium/docs/ciudad.md:5-19, 21-28` [E] |
| «Lo que hay hoy (layer 1 + layer 2 con secreto compartido)»; «el invite SSB reparte acceso a *layer 1* (el pub), y la **peercard** gobierna *layer 2* (rooms/Ciudad)» | `o-sdk\MAPA.md:114, 136-139` [E] |
| «La identidad de capa 2 (peercard/ACL, `operador-rooms`) es transversal y tiene su propia etapa» · **E8 — Capa 2: rooms con peercard/ACL + Ciudad**; gate: dos peers con peercards distintas, revocar una no rompe la otra; invite (L1) y peercard (L2) se emiten por caminos separados | `o-sdk\PLAN.md:40, 226-247` [E] |
| **«L1 = ∞, L2 = sesión»**: nada de la sala escribe directo al pub; el retorno es por **cristalización explícita** | `o-sdk\plan\BACKLOG.md:36-37, 409-416` (WP-O41); `ARCHIVO\DISCO\oasis-clearweb\v2.md:122` [E] |
| **WP-O51 · Cristalización L2→L1 como rito**: «un solo verbo de entrada a L1; nada cristaliza por efecto colateral» | `plan\BACKLOG.md:552-557` [E] |
| «barrio y ciudad son **pubs L2** de encuentro, relay, reconciliación y reenganche — no padres obligatorios» | `plan\BACKLOG.md:126-128` (WP-O10) [E] |
| Lane «L2 · Playground · molde local» (7 WPs: env único, compose del lab, arranque sin red, emulación del edge) | `plan\BACKLOG.md:225-290` [E] |
| **D-O11**: transporte base (room L2, anónima) ≠ capacidad WebRTC (opt-in) | `plan\DECISIONES.md:85-92` [E] |
| «Layer2 implementado como **LARP**»; «Parlament — gobernanza layer2»; «salas layer2 del PUB» | `s-sdk/docs/autoridades/02-scriptorium.md:10,14,19` [E] |
| «Ciudad» no aparece en o-sdk (0 coincidencias); el esquema vive en **g-sdk** (`packages/ciudad`) | `MAPA.md:141`, `PLAN.md:50,239-241` [E] |

## Servicios del pub — activos (`pub\docker-compose.pub.yml` [E])

| Servicio | Qué es | Puerto / endpoint | Estado | Dónde |
| :-- | :-- | :-- | :-- | :-- |
| `oasis-pub` | Nodo Oasis/SSB en modo `server`: solo replica, sin GUI. L1 permanente. **hops 3** | SSB `${OASIS_PUB_SSB_PORT:-8008}` (local 8009) | vivo en VPS | `compose.pub.yml:4-24` (`command: ["server"]` :10); `pub\config\ssb\config:12` |
| `pub-panel-api` | API de control/monitorización (Node `node:http`) | `127.0.0.1:${PUB_PANEL_PORT:-8787}` | activo; endurecimiento en backlog (WP-O52) | `compose.pub.yml:34-52`; `MAPA.md:199-215` |
| `pub-web` (Caddy) | Edge TLS compartido; estático `pub/site/` + 6 vhosts | 80/443 | activo; **punto único de fallo TLS de 5 servicios externos** | `compose.pub.yml:58-74`; `MAPA.md:33-48` |
| `oasis-hub` | **HUB clearnet solo lectura**: segunda cuenta SSB (`backend.js --public`), misma imagen, hops 3 | sin `ports`; se alcanza por `/c` | activo 2026-09-13; 1.1.2 desde 2026-09-17 | `compose.pub.yml:80-100`; `docs\PUB\HUB-PROTOCOL.md:1-30`; `pub\config\hub\ssb-config:6` |
| `hub-cache` | nginx con caché en disco delante del HUB; 405 a no-GET; caché negativa | interno `:80` | activo | `compose.pub.yml:114-124` |
| Teatro (Sala 03) | Obras estáticas montadas read-only en Caddy desde `/srv/oasis/teatro/` + zip certificado (SHA-256 + ed25519). Invariantes: cero JS, cero recursos externos, texto verbatim citado por id | `https://pub.escrivivir.co/teatro/` | activo (Obra Nº 1 «Aleph Cero», 2026-08-26) | `docs\PUB\TEATRO-PROTOCOL.md:1-27, 69-110` [V parcial] |
| Invites | `invite.create` vía `docker exec`; invite público de 1000 usos servido por `/public/status` | — | activo, **bug**: sin caché negativa, cada GET anónimo dispara un `docker exec` | `MAPA.md:217-220`; `pub\panel-api\src\server.mjs:167-173` |
| Sitio estático / salas | Landing, Sala 01 Scriptorium, Hackería, Sala 02 Parlament, Sala 03 Teatro, Sala 04 HUB, `/admin/` | `/`, `/scriptorium/`, `/teatro/`, `/c`, `/admin/`, `/public/status` | activo | `pub\site\index.html:229-234` |

## Servicios externos que el edge enruta (código fuera de o-sdk, en `escrivivir-co/scriptorium-vps`)

| Vhost | Upstream | Dónde |
| :-- | :-- | :-- |
| `pub.escrivivir.co` | `pub-panel-api:8787` + `hub-cache:80` + estático | `pub\caddy\Caddyfile:1-33` [E] |
| `scriptorium.escrivivir.co` / `admin.scriptorium…` | `scriptorium-nodered:1880` | `Caddyfile:39-70` [E] |
| `mcp.scriptorium.escrivivir.co` | `scriptorium-mcp-devops:3003` | `Caddyfile:72-86` [E] |
| `npm.scriptorium.escrivivir.co` | `scriptorium-verdaccio:4873` (registry npm privado) — **la única integración real de m-sdk y n-sdk con el pub** (sus `.npmrc`) | `Caddyfile:88-103` [E] |
| `rooms.scriptorium.escrivivir.co` | `scriptorium-rooms:3010` (Socket.IO, **shared-secret**) — el rooms server **no está en la suite local**; inventario `<pendiente>` | `Caddyfile:105-119`; `MAPA.md:39-43`; `PLAN.md:55,230-232` [E] |

## Servicios planificados / huérfanos / muertos

| Servicio | Estado | Dónde |
| :-- | :-- | :-- |
| `blobstore-sidecar` (chunking 5 MB + manifiesto content-addressed sobre `ssb-blobs`; API `/x/blobstore/v0/{salud,objetos,estado,deseos}`) | **huérfano**: código + 18 tests verdes, fuera de todo compose vivo a propósito; 4 condiciones antes del GO | `MAPA.md:28,169-196`; `pub\blobstore-sidecar\README.md:1-39`; WP-O50 `BACKLOG.md:542-550` [E] |
| `pub-frontend` (Angular 21) | superficie muerta: `./frontend` no existe | `MAPA.md:29`; WP-O45 [E] |
| `ecoin-wallet` | opcional, desacoplado; RPC 7474, P2P 12000 | `docker-compose.yml:78-100` [E] |
| `oasis-client` (rol cliente) | funcional: GUI `:3000`, SSB `:8008` | `docker-compose.yml:17-24`; `docs\CLIENT-PROTOCOL.md` [E] |
| Maint-UI del pub | herramienta bajo demanda | `pub\README.md:109-130` [E] |
| Radicle seed web | no existe; «solo seed web» (D-O3) | `MAPA.md:12`; `DECISIONES.md:21-26` [E] |
| IPFS/kubo, forja Forgejo | planificados (E5, D-d) | `PLAN.md:166-224` [E] |
| `sincronia/` | buzón/timbre documental entre carriles, **no servicio de red**; watchers parados | `sincronia\{BUZON,TIMBRE,ESTACION}.md` [E] |
| Endpoint HTTP de invites | «existe `getInvite()`, falta la ruta» | `MAPA.md:222-224` [E] |

Scripts como «servicios de comando» (`package.json:6-95` [E]): `pub:*`
(`deploy|down|status|logs|whoami|invite|profile|announce|join|…`),
`client:*` (`import-identity|sync-only|backup-keys|inspect-log`), `ecoin:*`,
`devops:*` (`status|preflight|backup|federation|invite|hub-disk|pub-feed-seq`),
`docs:*`, `skills:sync`.

## Modelo de datos relacional de Oasis/SSB (lo que el código publica y lee) [E]

| Tipo / estructura | Semántica | Dónde |
| :-- | :-- | :-- |
| `post` + `root`, `branch`, `recps` | hilos, blog, PM; herencia de `recps` del padre | `src\models\main_models.js:1317-1318, 2033-2089`; `blog_model.js:86,124`; `pm_model.js:29,47,79` |
| `about` (nombre, descripción, imagen, `visibilityPrefs`, GPG) | perfil e **opt-in de visibilidad** | `main_models.js:176,444,1920,1974-1977`; lectura `:300-308`; publicación `:1915-1920` |
| `contact` (`following` / `blocking`, exclusión mutua) | grafo social | `main_models.js:580-637` (`setRelationship`, `:581`, `:593`); `tribes_model.js:885` |
| `vote` | likes | `main_models.js:1354,1675,2180`; `forum_model.js:327` |
| `tribe` (`create/update`, `rootId`, `replaces`, `members`, `isAnonymous`) | grupos con cifrado propio (`tribe_crypto.js`); anidamiento (`:341`) | `tribes_model.js:316,351,521` |
| `pub`, `oasisVersion` | anuncio de pub y versión | `docs\PUB\HUB-PROTOCOL.md:63-68` |
| `recps` | expansión de destinatarios privados | `main_models.js:1167-1168,2167,2186` |
| blobs | `ssb-blobs`, `blobs.max = 50 MB` forzado por el fork | `src\server\ssb_config.js:37-45`; `MAPA.md:171,239` |
| **Grafo de follows** | `ssb.friends.graph()` → `{feedId: val}`: `val >= 0` following, `val === -1` blocking (`socialFilter`); `isFollowing({source,dest})` bidireccional | `main_models.js:993-1008, 642,654`; `backend.js:3958,5056` |
| **hops** | default upstream 2 (`src\configs\server-config.json:12`); pub 3; HUB 3; UI lee `friends.hops` con fallback 2 (`settings_view.js:29`); entrypoint imprime desde `config.conn?.hops ?? config.friends?.hops ?? 2` (`ssb_metadata.js:94,109`). **D-O15**: HUB a hops 3 porque con 2 solo alcanzaba 5 autores y `/c` listaba 0 habitantes | `plan\DECISIONES.md:136-146` |
| `typed_log.js` | caché por **tipo** (`messagesByType`) y por **ventana** (`createLogStream`), `WeakMap` por sbot; el índice relacional de facto de las vistas | `src\models\typed_log.js:1-118` |
| `data_model.js` `KINDS` | 30+ *kinds* con su `type` SSB y `href` (`inhabitants→curriculum`, `tribes→tribe`, `votes→poll`, `forum`, `school→schoolCourse`, `wiki→wikiPage`, `campaigns`, `logistics`…) — el inventario más cercano a un esquema de entidades | `src\models\data_model.js:11-41+` |
| `tombstone_validator.js` (41 l.), `viewer_filters.js` (130 l.) | borrados validados; filtros | `src\models\` |
| **Vista de grafo existente** | `graphos_view.js`: SVG de nodos/aristas con `kind`, `?center=`; ruta `/graphos` («graphos, network map, visualization, relationship graph»); `graphosMod` | `src\views\graphos_view.js`; `src\AI\routes_index.js:112`; `src\configs\oasis-config.json:62` |
| Módulos | Agenda · IA · Audios · **Banking** (ECOin + RBU) · Bookmarks · Calendars · Chats · Cipher · **Courts** · Documents · Events · Feed · Forums · Games · Governance · Images · Invites · Jobs · Legacy · Maps · Market · Multiverse · Opinions · Pads · **Parliament** · Pixelia · Projects · Reports · Shops · Tags · Tasks · Torrents · Transfers · Tribes · Videos · Wallet. 75 modelos, 70 vistas. Catálogo de features **pendiente** | `README.md:110-117`; `BASE-3-MECANISMO.md:43` |

## Opt-in de visibilidad y anti-autoridad

| Enunciado | Dónde |
| :-- | :-- |
| Opt-in **por habitante**, viaja con el feed: Profile → Edit → bloque Clearnet | `docs\PUB\clearnet.md:20-36` [E] |
| Claves `visibilityPrefs.clearnetShops\|clearnetSchool\|clearnetJobs\|clearnetEvents\|clearnetProjects\|clearnetPosts\|clearnetAudios\|…` + `activity\|device\|karma\|ubi\|wallet` | `src\views\main_views.js:2436-2449` [E] |
| Reglas por tipo de contenido: owner / members / assignees / `visibility: HIDDEN\|CLOSED\|INVITE`, `tribeId` | `src\models\content_visibility.js:9-27` [E] |
| **D-O6 · `CA-ANTI-AUTORIDAD`**: «el grafo NO declara jerarquía de autoridad — declara **ámbitos**; el riesgo real es que una implementación convierta ámbitos en control obligatorio, y eso se verifica, no se sospecha». Gate ejecutable de 5 puntos (WP-O11) | `plan\DECISIONES.md:41-46`; `BACKLOG.md:136-145` [E] |
| **D-O7**: apertura anónima base + peercard opt-in; «el permiso no gobierna el transporte»: fail-closed en capacidades, fail-open en topología | `plan\DECISIONES.md:48-53` [E] |
| HUB: «el opt-in viaja con el feed del habitante; el HUB no decide quién aparece y **no se lista a sí mismo**» | `docs\PUB\HUB-PROTOCOL.md:71-73` [E] |
| **WP-O14 · Zonas como ámbito de suscripción**: «zona = alcance, no ubicación; solapables, cruzando niveles… ningún permiso se deriva de la zona» — la pieza más cercana a un hipergrafo de ámbitos | `plan\BACKLOG.md:169-175` [E] |
| WP-O12 «Entrada real al grafo — arista A2 (O→Z)»: «la puerta del grafo es `rooms`/`socket-server`» | `plan\BACKLOG.md:147-155` [E] |
| Socket.IO Admin UI de los nodos room (WP-O43): «leer no habilita actuar»; node-red como editor (WP-O42) | `BACKLOG.md:418-430`; `DECISIONES.md:17-18` (D-O2) [E] |

## API consumible por un cliente externo (layer 2 / UI) [E]

| Superficie | Endpoints | Auth | Dónde |
| :-- | :-- | :-- | :-- |
| Panel público | `GET /health` · `GET /public/status` · `GET /public/network` | ninguna | `pub\panel-api\src\server.mjs:238,243,274` |
| Panel privado | `GET /api/pub/status` · `GET /api/pub/logs?tail=N` · `POST /api/pub/restart` | Bearer `PUB_PANEL_TOKEN` (`:291`) | `server.mjs:291-313`; `pub\README.md:65-71` |
| **HUB clearnet (solo lectura, HTML)** | `/c` · `/c/inhabitant/<feedId>` · `/c/{audios,blog,documents,events,feed,images,jobs,market,podcasts,projects,school,shops,torrents,videos,wiki}/<id>` · `/c/blob/<blobId>` · `/c/assets/*`. 16 tipos desde 1.1.2 (12 en 1.0.8). Todo no-GET → 403/405 | anónimo | `docs\PUB\clearnet.md:15-18`; `HUB-PROTOCOL.md:19-20,56-58`; `Caddyfile:18` |
| muxrpc / ssb-client | socket unix `~noauth` con fallback TCP loopback `net:127.0.0.1:8008~shs:<pubKey>`; manifest de `manifest.json`. Envueltos: `whoami`, `invite.create [uses]`, `publish-about`, `announce-pub`, `follow <feedId>`, `publish-json`. Sonda read-only `SSB_ACTION=seq\|peers\|invite-accept` | claves propias = master | `pub\tools\ssb-probe.js:1-58`; `pub\tools\ssb-admin.js:13-77`; `hub-conn-fix.js` |
| Invites | `pub/scripts/invite.sh <n>`, `npm run pub:invite`, `devops/scripts/generate-invite.sh`, `join-info.sh` | — | `pub\README.md:87,105-108` |
| Rutas de la app **no expuestas** por el vhost | `/graphos`, `/settings`, `/profile`, `/publish`, `/json/x`, `/qr/x` | — | `plan\BACKLOG.md:473-476` |

**No hay API REST/JSON del grafo social** (`friends.graph`, follows, hops,
`about`/`visibilityPrefs`) para un cliente externo. Lo único consumible desde
fuera es HTML del HUB, `/public/status`, `/public/network` y, si se despliega,
el blobstore. **No hay** `docs/PUB/` con spec de muxrpc ni esquema formal de
mensajes SSB (JSON-Schema o tabla de tipos): el modelo está disperso en
`src\models\*.js`. [E]

## Menciones cruzadas en o-sdk [E]

- `m-sdk` → 0 · `n-sdk` → 0 · `modelador` → 0 · `hipergrafo` / `relacional` →
  0 en ficheros de texto (solo en binarios del volumen del cliente:
  `volumes-dev\ssb-data\flume\log.offset` y un blob `sha256/8a/db18…` —
  contenido SSB replicado, no código; coincide con el sha del PDF fuente).
- `s-sdk` → `PLAN.md:203-204` (check F5c del blobstore); convención
  `<x>-sdk.escrivivir.co` (`pub\site\scriptorium\estado.md:139`).
- `HyperGraph Editor` (`PLG-LOG-05`, beta, tags `grafo/hipervínculos/wiki`,
  `WiringAppHypergraphEditor/`) y `WiringApp` («flujos de juego sobre grafos
  de artículos») en `pub\site\scriptorium\catalog.json:276-284,321-325`
  (duplicado byte a byte en `pub\site\hackeria\catalog.json`; huérfano a
  borrar, `MAPA.md:62`, WP-O45).
- `Novelist MCP` como ficha de catálogo `PLG-AUT-01` («Puerto 3066»,
  `agent: @novelist`, links al monorepo histórico `NovelistEditor/`,
  `ARCHIVO/PLUGINS/NOVELIST/`), `catalog.json:95-103`. Ficha de un mundo
  viejo, no servicio conectado.
- `o-sdk` figura como **read-only duro** para el swarm Z·V
  (`scriptorium/plan/GOBIERNO-LORE-HM.md:39,73`).
- Deuda de gobierno en o-sdk: `plan\BRIEFS\` no existe (WP-O01 lo exige,
  `BACKLOG.md:56-58`); sin `MAPA-RAIZ/REPO/TALLER` propios (WP-O02,
  `BACKLOG.md:80-86`); remote `oasis-upstream` no existe (`MAPA.md:250-258`).

## Vías de ingesta documental ya existentes (para un nodo/obra nuevos) [V]

- `docs\PUB\TEATRO-PROTOCOL.md:23-27`: «texto verbatim, citado por id; nada se
  resume en lugar de la fuente». Invariante que `01-relacional.md` respeta.
- `ARCHIVO\DISCO\oasis-clearweb\dosier\README.md:11-12`: leyenda [V]/[NV]/[VPS].
- `src\backend\pdf.js` (escritor) y `pdf*.mjs` (visor): generan y muestran,
  no extraen.
