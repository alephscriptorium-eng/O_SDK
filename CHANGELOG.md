# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es/1.0.0/).
Web &amp; docs: <https://o-sdk.escrivivir.co> · Código: <https://github.com/alephscriptorium-eng/O_SDK>

## [Unreleased]

### Added — Protocolo para agentes (WP-O104, 2026-09-19)

Asientos D-O20, D-O21, D-O22, D-O23. Solo documentación.

- **`AGENTS.md`** (raíz) y **`docs/AGENTES.md`**: entrada única para quien opera el repo — árbol
  intención → protocolo, reglas universales, **tabla de acciones irreversibles** con su puerta,
  **trampas conocidas** agregadas (estaban repartidas en ~15 ficheros) y convención de nombres.
- **Método genérico, datos aparte**: `docs/PUB/INSTANCIA-SCRIPTORIUM.md` es la ficha de la casa
  (registro de bots, `about` literales, rutas) y la plantilla para otro pub con su lore.
- **Nombres de bots (D-O20)**: forma libre, se prefiere corta, máximos de UI medidos. La casa pasa a
  `clearnet.escrivivir.co` y `ecoin.escrivivir.co`; la cadena tipo → piel → pub va en la descripción.
- **`HUB-PROTOCOL.md` §11-§12**: la serie de bots pasa a ser genérica y gana el **procedimiento de
  renombrado** (ventana no pública, un POST, contar antes y después).
- **`plan/PRACTICAS.md`**: el método del carril (WP, commits pedagógicos, gates, GO, cierre).
- README y `docs/proyecto.md` listan los 8 protocolos; portal con las dos páginas nuevas.

### Added — ECOin en la app cliente (WP-O103, 2026-09-18)

Estado: **en `main`; gate G1 y drill con identidad desechable pasados** (montaje, publicación única,
recreate, rebuild, `down -v`, backup y restore, arranque sin perfil, guarda anti-remoto). Es el
protocolo para que cualquier habitante se saque su cartera; no se ha aplicado a ninguna identidad
real (el custodio lo hará con su cliente cuando salga Oasis 1.1.3). Reporte
`plan/REPORTES/WP-O103-cliente-ecoin.md`. BRIEF `plan/BRIEFS/WP-O103-cliente-ecoin.md`; doc viva `docs/CLIENT-PROTOCOL.md` §8; asiento D-O19.

- **Dos niveles, independientes del VPS**: (i) *solo dirección* (aparecer, recibir y reclamar RBU
  con una dirección de una `wallet.dat` propia) y (ii) *cartera propia* (`ecoind` propio para saldo,
  envíos e historial). Por defecto `wallet.url = ""`: ningún RPC saliente y `/banking` sin latencia.
- **`docker-entrypoint.sh`** (zona *wholesale*; delta en `src/` = cero, siguen exactamente 4 guards):
  `persist_client_state` (config de la GUI y mapa de direcciones persistidos por symlink),
  `wire_wallet_config` (`ECOIN_RPC_URL|USER|PASS`, `OASIS_WALLET_FEE`, `OASIS_WALLET_PUB_ID` →
  `oasis-config.json`; **env manda**, escape `OASIS_WALLET_WIRING=manual`; **guarda anti-remoto**
  salvo `ECOIN_RPC_ALLOW_REMOTE=i-know`; nunca imprime credenciales) y `setup_oasis_config` reescrito
  en node. Solo actúan con `OASIS_CLIENT_STATE_DIR` y modo distinto de `server`: pub, HUB y bot-2 sin regresión.
- **`docker-compose.yml` raíz**: `ecoin-wallet` **sin `ports`** (RPC 7474 y P2P 7408 solo en la red
  del compose; el 12000 desaparece), credenciales del `.env` raíz con `ECOIN_REQUIRE_CREDS=1`,
  healthcheck, `mem_limit` (`ECOIN_MEM_LIMIT`, 512m), `logging`, `stop_grace_period 2m`;
  `wallet.dat` en el **volumen externo `o-sdk-client-ecoin-data`** (sustituye a
  `volumes-dev/ecoin-data`; `down -v` no lo borra). `oasis-client`: bind
  `./volumes-dev/client-state` → `/app/state`, `OASIS_BANKING_DIR=/app/state/banking`,
  `depends_on` opcional. `.env.example` raíz con los dos modos.
- **`client/scripts/`**: `ecoin-init.sh` (credenciales generadas, volumen, `--mode address|own`,
  `--pub-id`, `--ensure`), `backup-wallet.sh` (caliente, `--cold`, `--restore` que nunca sobrescribe;
  sha256; `devops/backups/client-wallet/<TS>/`), `guard-destroy.sh` (exige `BORRAR` y backup de menos
  de 24 h), `ecoin-verify.sh`; `setup.sh` e `import-identity.sh` dejan de tocar `ecoin-data`;
  `client/docker-compose.drill.yml` (proyecto `o-sdk-drill`, identidad desechable, 3100/8108).
- **npm**: `client:ecoin:init`, `client:wallet:backup`, `client:wallet:restore`,
  `client:ecoin:verify`; `ecoin:info|balance|address` sin credenciales en la línea de comandos,
  `ecoin:system` sin volcar `rpcpassword`, `ecoin:build` antepone `ecoin:fetch-deb`, `ecoin:up` espera
  a `healthy`; `downDELETEVOLS` y `cleanDELETEVOLS` pasan por la guarda.
- Docs y gobierno: `docs/CLIENT-PROTOCOL.md` §8 «ECOin en el cliente» (procedimientos, tabla
  variable → entrypoint → config, backup/restore, banco = bot-2, avisos, drill) y corrección de
  puertos y `volumes-dev/`; `client/README.md`; `UPGRADE-PROTOCOL.md` §3; referencia cruzada en
  `docs/PUB/ECOIN-PROTOCOL.md`; WP-O103 🔶 en `plan/BACKLOG.md`.

### Added — hub-wallet del pub: `ecoind` + `azofaifo-scriptorium-wallet-bot-2` (WP-O102, 2026-09-18)

Estado: **desplegado el 2026-09-18 (18:06 UTC)** con el motor de RBU APAGADO: bot-2 =
`@NYAqUzX7OACl+Fs866J8aVeKcqPxbbXccV/phcKx9UU=.ed25519`, cartera `EYdruXgDVQGhBpSsns83VA1BmDfAKBP4Lc`,
`ecoind` sincronizado, el pub sin reiniciar. Reporte `plan/REPORTES/WP-O102-hub-wallet.md`. Asiento D-O19; doc viva `docs/PUB/ECOIN-PROTOCOL.md`.

- **Imagen `ecoin/` endurecida** (compartida con el cliente): sha256 del
  `.deb` versionado (`ecoin_0.0.4-1_amd64.deb.sha256`) y `fetch-deb.sh`; el
  build **falla** si el binario no casa; conf completa de respaldo fuera del
  datadir; `port=7408` explícito; sin credenciales reales en git y arranque
  fail-closed (`ECOIN_REQUIRE_CREDS=1` rechaza vacío y `ecoinrpc`).
- **Dos servicios nuevos** en `pub/docker-compose.pub.yml`, perfil `wallet`
  (ni `pub:local:up` ni `deploy.sh` los arrastran), **sin `ports`** y sin ruta
  en Caddy: `ecoin` (`oasis-pub-ecoin`; 512m, `cpus 0.75`,
  `stop_grace_period 60s`) y `oasis-wallet-bot` (`oasis-pub-wallet-bot`; misma
  imagen que el pub, `command: ["backend"]`, hops 3, `OASIS_BANKING_DIR`
  persistente). El RPC no sale de `oasis_pub_net`.
- `pub/config/wallet-bot/` (`ssb-config`, `oasis-config.json.tpl`) y
  `pub/scripts/render-wallet-bot-config.sh`: la config con credenciales se
  renderiza **fuera de git**. **Motor de RBU armado y apagado**: el interruptor
  es `OASIS_WALLET_BOT_PUB_ID`, vacío hasta la dote.
- Herramientas: `devops/scripts/backup-ecoin.sh` (`backupwallet`, `--cold`,
  `--verify`; nunca borra `wallet.dat`), `devops/scripts/ecoin-disk.sh`
  (`status`/`check`/`--json`), línea en `deploy-status.sh`, rutas nuevas en
  `common.sh` y `verify-debian13-base.sh`, bloques `OASIS_ECOIN_*` /
  `OASIS_WALLET_BOT_*` en los tres `pub/.env*.example`, scripts npm
  `pub:ecoin:fetch-deb`, `pub:local:ecoin:up|info`, `pub:local:wallet-bot:up`,
  `pub:wallet-bot:render`, `devops:ecoin-disk`, `devops:backup:ecoin`.
- Docs y gobierno: `docs/PUB/ECOIN-PROTOCOL.md` (invariantes, activación,
  preflight de upgrades, tabla de contingencia 1.1.3, cartera, interruptor del
  motor, hallazgos de upstream), `HUB-PROTOCOL.md` §11 fila 2 y §5.2
  (lockstep de `caps.shs`), D-O19, WP-O102 y WP-O103 en el backlog. Delta en
  `src/` = cero; el pub, el HUB y Caddy no cambian.

### Added — Roadmap futuro: los dosieres de trabajo (WP-O101, 2026-09-18)

- `docs/ROADMAP/`: seis dosieres (aleph-net, relacional, colectivizaciones,
  res-publica, oasis-faircoin, publicidad-rrss) con página índice; anexos
  (previews HTML, figuras, PDF, banners) en `docs/public/dosieres/`. Sección
  «Roadmap» en menú, barra lateral, portada y README.
- `scripts/roadmap-import.py <carpeta>`: importa los dosieres como copia
  saneada e idempotente (rutas locales, Google Fonts, artifacts privados y
  datos de conexión del pub).
- `ARCHIVO/README.md`: declara los territorios (`DISCO`, `LORE`) y la
  diferencia con `archive/`; fila en README y MAPA.

### Added — Teatro: puerta semántica, «El sistema» y «El cantar» (WP-O100, 2026-09-18)

- **Capa editorial declarativa** en el sidecar (`lib/editorial.py`): lee
  `ARCHIVO/LORE/<fuente>/<obra>/editorial/obra-semantica.json` (territorios →
  constructos, álbum, concepto, portada). Opcional: sin ella la obra se
  construye como antes. Subcomandos `editorial-init | editorial-check |
  editorial-delta` y scripts `teatro:editorial:*`; esqueleto en
  `editorial.example/`.
- Puertas curadas: `sistema/` (índice + una página por constructo: prosa,
  «Nace en», posts que lo explican, hilos, enlaces y, aparte, «También lo
  mencionan (búsqueda mecánica)») y `cantar/` (tracklist + corte: vídeo
  enlazado, letra, constructos que recapitula). Chips «curado en» en cada
  permalink; `indexes/sistema.md` e `indexes/cantar.md` en el segundo cerebro.
- Portada: **SVG inline** de la obra, texto de concepto y puertas en dos
  grupos, «Leer la obra» / «Recorrer el archivo».
- Puertas mecánicas nuevas: **Conversaciones** (shares de agentes por agente)
  e **Interlocutores** (réplicas, menciones y RT por cuenta;
  `indexes/interlocutores.md`). El registro normalizado gana `mentions[]`.
- Convención de cita verificable en los `.md` editoriales: `«…» [[id]]` debe
  ser literal en ese post; si no, el build se detiene.
- `docs/PUB/TEATRO-CURADURIA-PROTOCOL.md`: crear, revisar, actualizar tras un
  export nuevo, subir de versión y reglas para agentes.
- Aleph Cero, propuesta v1 (en el lore, fuera de git): 5 territorios, 21
  constructos, 13 cortes, 143 citas verificadas, sigilo de portada.

- Revisión del custodio: `album.lyrics` (letra de la obra entera, repartida por los cortes),
  `voice_notes` (descripción del custodio como `alt` de la media de una voz ajena),
  `obra.json → imprint` (cabecera y colofón con sello y licencia en todas las páginas) y
  `link-mark --waived-by` (dispensa expresa para dejar un share de agente como enlace).
  Aleph Cero: constructo «Sacar la cabeza» (22 constructos, 151 citas verificadas).

### Changed

- `lib/guards.py`: barre también `*.svg` y los `<svg>` inline (sin script,
  eventos, `<image>`, `<foreignObject>` ni `href` externos).
- `AGENTS.md` (plantilla): distingue índices mecánicos de capa curada.

### Added — Teatro: sidecar de RRSS con fuente en exports de x.com (WP-O99, 2026-09-18)

- `pub/rrss-sidecar/twitter_x/`: el generador de obras del Teatro, en git y
  parametrizado por obra (Python ≥ 3.10, solo stdlib). `sidecar.py`
  (`lore-import | init | ingest | fetch-voices | fetch-links | browser-* |
  build | check | manifest | pack`), `lib/` (obra, ytd multi-parte, store
  aditivo multi-generación, **normalize = la costura**, voices, links,
  html2md, guards), builders sobre el corpus normalizado, parche multi-vídeo
  del visor como JSON declarativo con sha256 verificado, tests sobre export
  sintético. `CORPUS-SCHEMA.md`: contrato para un futuro adaptador B.O.E.
- `ARCHIVO/LORE/`: casa del lore del usuario **dentro del repo y fuera de
  git** (deny-by-default; excluido de la imagen Docker). El protocolo es
  autocontenido; el lore del custodio se copió verificado (3 generaciones).
- Protocolo (a) voces ajenas a 1-2 niveles, incluidas las **citas** (el
  export no trae `quoted_status`); protocolo (b) enlaces externos a Markdown
  íntegro, con cola de navegador y **regla PARAR**. Puerta nueva «Enlaces».
- `docs/PUB/RRSS-SIDECAR-PROTOCOL.md` (nuevo) y `TEATRO-PROTOCOL.md`
  reescrito; scripts npm `teatro:*` y `devops:teatro:*`; asiento D-O16.

### Changed — Teatro: deploy por obra e higiene del VPS (WP-O99)

- `devops/scripts/deploy-teatro.sh`: `TEATRO_OBRA` obligatorio (adiós a
  `aleph-cero` hardcodeado), origen `volumes-dev/teatro`, pre-vuelo de
  invariantes + `MANIFEST.sha256`, `rsync --chmod=D755,F644` acotado a la
  obra, **dos zips** (completo como descarga principal; ligero para
  inspección), tres firmas ed25519 y **verificación post-deploy automática**
  (incl. `data/ip-audit.js` → 404). Nuevos `teatro-wsl.sh` y
  `backup-teatro.sh` (`--verify`; backup de firmas y stores del lore).
- `pub/caddy/Caddyfile`: bloque `@teatro` — 404 real (sin fallback a la
  landing), whitelist de `data/*.js`, CSP estricta para páginas y propia para
  el visor, caché larga de media.
- `verify-debian13-base.sh` comprueba `/srv/oasis/teatro` (volumen de datos,
  nada world-writable); `hub-disk.sh status` lo mide;
  `OASIS_PUB_TEATRO_DIR` en `pub/.env.example` y `.env.local.example`.

### Security — (WP-O99)

- `.dockerignore` no excluía `ARCHIVO/`: añadidos `ARCHIVO/LORE/**` y
  `pub/rrss-sidecar/**` (un lore de varios GB con datos personales habría
  entrado en el contexto de build). Guardas de publicación como única fuente
  de verdad (`lib/guards.py`): denylist de nombres sensibles en árbol y zips,
  email/teléfono del export, recursos externos, `<script>` fuera del visor.

### Added — Protocolo del cliente: alta fresca e importación de identidad (WP-O98, 2026-09-17)

- `docs/CLIENT-PROTOCOL.md` (nuevo): estado y convivencia con el pub local, alta fresca,
  importación de identidad sin bifurcar el feed, sincronización con sbot puro, upgrade,
  healthcheck, rollback y retirada de instalaciones antiguas.
- `client/scripts/import-identity.sh` (secret + `flume/log.offset` + `gossip.json` + `keys/`
  [+ blobs]; verificación por frames, backup verificado en `devops/backups/client/`, flag
  `oasis-first-contact` con `welcome=done`), `client/scripts/sync-only.sh`
  (`start|status|invite|stop`, gate de identidad, veredictos SYNC-OK/AHEAD/BEHIND/PUB-UNKNOWN),
  `client/scripts/lib/inspect-log-offset.js`, `pub/tools/ssb-probe.js` (sonda por stdin, sin
  rebuild) y `devops/scripts/pub-feed-seq.sh`. Scripts npm `client:import-identity`,
  `client:sync-only[:status]`, `client:inspect-log`, `devops:pub-feed-seq`.
- Correcciones: `setup.sh` crea `ecoin-data` y no `configs` (muerto); `test-ai-service.sh`
  prueba `POST /ai` dentro del contenedor (no había `/health` ni `:4001` publicado); Quickstart
  con `npm run setup`; `.gitignore` cubre `.env.*` (antes `pub/.env.prod` era commiteable);
  `UPGRADE-PROTOCOL.md` cliente (rollback = imagen anterior), `RECOVERY-PROTOCOL.md` §4
  (en 1.1.2 el vector de fork es el PM de bienvenida), `pub/README.md` HUB activo.

### Changed — Upgrade Oasis 1.0.8 → 1.1.2 con el HUB activo (WP-O97, 2026-09-17)

- Rama `upgrade/oasis-1.1.2`: overlay limpio de `src/` desde upstream
  `3c9bf9a` (releases 1.0.9–1.1.2), 4 fork guards repuestos
  (`git diff oasis-upstream/main --stat -- src/` = guards +
  `blockchain-cycle.json`), `docs/PUB/clearnet.md` actualizado con la nota
  del fork. Ciclo de red sin cambios (cap `H5EC+V5B…`, ciclo 6).
- HUB (`HUB-PROTOCOL.md` §5.5): el visor pasa a `/c/assets/*` → nueva
  `location` cacheada en `pub/config/hub/nginx.conf.template`; cuatro rutas
  de detalle nuevas (market, feed, wiki, bookmarks) → Sala 04 pasa de 12 a
  16 tipos; `/c/qr/:feedId` entra por `/c/*` sin caché (`no-store`).
  `ssb-*`, `oasis-config.json`, `server-config.json` y cabeceras del backend
  sin cambios upstream.
- `UPGRADE-PROTOCOL.md`: guards por fichero (checkout de HEAD solo si
  upstream no lo tocó), aviso CRLF en Windows, chequeos post-upgrade del HUB.

### Added — HUB clearnet como nodo de soporte, implementación (WP-O46, 2026-09-13)

- Rama `wp/O46-hub-nodo-soporte`. `pub/docker-compose.pub.yml`: servicios
  `oasis-hub` (misma imagen, `command: ["backend"]`, identidad propia, sin
  puertos) y `hub-cache` (nginx, caché en disco acotada); `oasis-pub` intacto.
  `pub/config/hub/{ssb-config,oasis-config.json,nginx.conf.template}`;
  bloque `@hub` en `pub/caddy/Caddyfile`; variables `OASIS_HUB_*` en
  `pub/.env*.example` y `pub/scripts/common.sh`; `pub/tools/hub-conn-fix.js`
  (normaliza `conn.json` tras el invite: ssb-invite deja la dirección con
  seed y sin `key`); `devops/scripts/hub-disk.sh` (`status`/`check`/
  `prune-blobs`/`prune-cache`/`--json`, npm `devops:hub-disk`) y línea de
  `check` en `deploy-status.sh`; layout `/srv/oasis/oasis-hub/*` en
  `verify-debian13-base.sh`; Sala 04 `pub/site/hub/` + puerta en el
  vestíbulo y en Accesos. Gates locales G1-G7 pasados (hallazgos en
  `ARCHIVO/DISCO/oasis-clearweb/v2.md`).
- **Desplegado en `pub.escrivivir.co` el 2026-09-13 (19:55 UTC)**: `/c` servido por
  la cuenta de soporte `azofaifo-scriptorium-skin-bot-1`
  (`@KM+ZBipR18VSyjNTFjAOnsmz6EiobGYHb3ZCZ4ZxQYI=.ed25519`), Sala 04 en `/hub/`,
  el pub sin reiniciar. Tres paradas durante el deploy, corregidas en la
  rama: ruta de `ssb-admin.js` en la imagen viva, `seeds` retirado del
  `ssb-config` (bloqueaba el invite con `alreadyFederated`) y filtro de
  `hub-conn-fix.js` por host. Reporte: `plan/REPORTES/WP-O46-hub-nodo-soporte.md`.
- HUB a **hops 3** (D-O15): con 2 el HUB solo alcanzaba los 3 seguidos
  directos del pub y `/c` quedaba vacío.

### Docs — HUB clearnet como nodo de soporte (2026-09-13)

- Nuevo `docs/PUB/HUB-PROTOCOL.md`: activar, operar, mantener en disco y llevar
  a través de los upgrades el HUB web `/c`. Diseño v2: **segundo nodo SSB con
  identidad propia** (`oasis-hub`, misma imagen, `command: ["backend"]`, sbot
  embebido, hops 2), caché nginx en disco (`hub-cache`, `max_size`) y todo el
  estado en el volumen de datos (`/srv/oasis/oasis-hub/*`). El pub no cambia.
  Estado: **planificado, no desplegado** (WP-O46; plan y dosier en
  `ARCHIVO/DISCO/oasis-clearweb/`).
- `UPGRADE-PROTOCOL.md`: §4 pasa a «tres modos» (`server`/`backend`/`full`);
  pasos del HUB en §0, §2 (invariantes upstream que verifica), §4, §5, §6;
  §8 retira la receta v0 (entrypoint `server-hub`, proxy al backend del pub,
  `/qr/*`) y apunta al protocolo del HUB.
- `clearnet.md` (upstream) lleva nota del fork; `devops/README.md` §9 (disco
  del HUB, `hub-disk.sh`); `pub/README.md` (servicios planificados); portal
  VitePress (nav/sidebar); `plan/DECISIONES.md` D-O13 y D-O14 (serie de
  bots de soporte `<nombre>-<tipo>-bot-<cardinal>`; el HUB es
  `azofaifo-scriptorium-skin-bot-1`); `plan/BACKLOG.md` WP-O46 y WP-O47
  (tope duro de disco + `mem_limit` del pub).

### Changed — refactor de estructura (2026-07-25)

- **Una carpeta por responsabilidad**: `OASIS_PUB/`→`pub/`,
  `GANDI_DEVOPS_FOLDER/`→`devops/`, `OASIS_CLIENT_dEV/`+`docker-scripts/`→
  `client/`, `ECOIN_DOCKERIZE/`→`ecoin/`; histórico y transcripts →
  `archive/`. Migración del VPS: `devops/MIGRATION-2026-07.md`.
- **Generalización cliente+pub**: datos de instancia fuera de los scripts —
  `devops/hosts/<instancia>/host.env` (IP, clave, cap, dominio; instancia por
  defecto `scriptorium`) y `client/identity/identity.env` (identidad GPG del
  usuario). Los scripts de `devops/` cargan la instancia vía `lib-host.sh`.
- Servicio del compose raíz renombrado `oasis-dev`→`oasis-client`; el wallet
  ECOin pasa a profile opcional (`npm run ecoin:up`). Scripts npm
  reorganizados en espacios `client:` / `pub:` / `devops:`.
- CI de docs: el gate materializa las skills (`npm run skills:sync`) en vez de
  depender de un espejo commiteado.

### Security

- `.dockerignore` reescrito: `devops/` (claves SSH), `client/` (GPG),
  `archive/` y demás superficies ya **no entran en la imagen Docker** (antes
  la clave privada del VPS se horneaba en `oasis-pub-scriptorium:latest`).
  Requiere rebuild + rotación de la clave SSH si la imagen se compartió.
- Retirado un `ROOMS_SECRET` en claro de `pub/site/scriptorium/index.html`
  (página servida públicamente): rotar el secret en el servidor de rooms.
- `pub/.env.example` regenerado (estaba corrupto por el incidente NVMe — 1153
  bytes NUL) — el flujo genérico de `deploy.sh` vuelve a funcionar.

### Added

- Portal de documentación FOSS (VitePress) publicado en
  <https://o-sdk.escrivivir.co> vía GitHub Pages (skill `site-web`): portada,
  Proyecto/DevOps y los protocolos de operación.
- `docs/PUB/RECOVERY-PROTOCOL.md` — protocolo de recuperación (repo, imagen e
  identidad SSB), gemelo del de upgrade.
- Tooling de skills de agente: `@alephscript/skills-scriptorium` +
  `.claude/skills/` (espejo materializado con `npm run skills:sync`).
- Enlaces FOSS de fuente única (repo, registry, CI, issues) en el pie del portal.

### Changed

- Migración del fork a **Oasis 0.8.8** (cliente + pub dockerizados).
- Repositorio movido a `alephscriptorium-eng/O_SDK` (rama por defecto `main`);
  referencias a `escrivivir-co` retiradas de README y portal.

### Fixed

- Recuperación tras corrupción de disco: contenido restaurado por procedencia
  (commits locales legibles + rama del equipo), purgado de daño NUL; working
  tree, imagen Docker e identidad SSB (feed continuo) restaurados y verificados.
