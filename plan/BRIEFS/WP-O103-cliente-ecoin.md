# BRIEF · WP-O103 · ECOin en la app cliente

Rama `wp/O103-cliente-ecoin` · Dep: WP-O102 (imagen `ecoin/` endurecida; feed de bot-2) · Relación: WP-O98.
Asiento: D-O19. Doc hermana: `docs/PUB/ECOIN-PROTOCOL.md`.

## Qué resuelve

La app cliente (`docker-compose.yml` raíz, servicio `oasis-client`) necesita ECOin **independiente del VPS**.
Dos niveles, documentados como modos:

- **(i) Solo dirección** — aparecer, recibir y reclamar RBU. El claim es un mensaje SSB (`ubiClaim`); paga el
  `ecoind` del banco (bot-2). Basta una dirección publicada (`type: wallet`) **de una `wallet.dat` propia**.
- **(ii) Cartera propia** — saldo, envíos e historial exigen un `ecoind` propio corriendo (`/wallet/*` usa RPC).

El cliente **nunca** apunta al `ecoind` del VPS (RPC en HTTP plano, monedero único sin cuentas).
Banco del cliente: `walletPub.pubId` = `@NYAqUzX7OACl+Fs866J8aVeKcqPxbbXccV/phcKx9UU=.ed25519` (bot-2).

## Hechos del código (1.1.2) que gobiernan el diseño

1. Oasis lee la cartera **solo** de `src/configs/oasis-config.json` (`wallet.{url,user,pass,fee}`,
   `walletPub.pubId`). Las `ECOIN_RPC_*` de `docker-compose.yml:47-49` están muertas: nadie las lee.
2. **Abrir la GUI publica la dirección**: `GET /` → `/activity` → `ensureSelfAddressPublished()`
   (`src/backend/backend.js:4455`; también `GET /banking`, `:7267`) en cuanto `wallet.url` responde RPC.
   En 1.1.2 ese camino automático falla en silencio (ReferenceError de `services`, `banking_model.js:107`),
   pero **sí llama a `getnewaddress`** y guarda el mapa; una 1.1.3 puede arreglarlo y publicar de verdad.
   Por eso el valor por defecto del cliente pasa a ser `wallet.url = ""` (skip limpio en
   `banking_model.js:98-99`, sin los 6 RPC de 1500 ms).
3. `POST /banking/addresses` publica el `wallet` **sin RPC** y **no es idempotente** (cada POST publica otro).
4. El estado bancario (`wallet-addresses.json`, `banking-*.json`) vive en la capa efímera de la imagen salvo
   `OASIS_BANKING_DIR` (`banking_model.js:23`). Sin persistirlo, cada recreate genera otra dirección.
5. Hay **dos mapas** de direcciones: `banking_model.js:26` usa `$OASIS_BANKING_DIR/wallet-addresses.json`;
   `backend.js:48` tiene fija `src/configs/wallet-addresses.json` (rutas `/wallet*`). Se unifican con un symlink.
6. `saveConfig` reescribe `oasis-config.json` entero (`src/configs/config-manager.js:115-120`) desde 11 rutas de
   la GUI (tema, idioma, módulos…): un bind `:ro` rompería la GUI. `src/configs/` contiene código y guards:
   no se puede persistir el directorio entero.
7. La GUI no puede vaciar `wallet.url` (`backend.js:11567`: `if (b.wallet_url)`): el `""` solo lo pone el entrypoint.
8. `docker-entrypoint.sh` raíz: `su -m` preserva el entorno (`:27`); `setup_oasis_config` usa `sed -i`
   (`:259-276`), que rompe un symlink; se salta en modo `server` o con `OASIS_SKIP_AI_MODEL=true` (`:488-492`).
9. Este `ecoind` no entiende CIDR en `rpcallowip` (ya corregido en `ecoin/ecoin.conf` con comodines).
10. BDB sobre un bind de Windows (virtiofs) es frágil y lento: `wallet.dat` va a un **volumen nombrado**.

## Entregables

### A. `docker-entrypoint.sh` raíz (zona *wholesale*; `src/` sigue con 4 guards)

Todo condicionado a `OASIS_CLIENT_STATE_DIR` definido y modo ≠ `server`. **Pub, HUB y bot-2 no lo definen → sin regresión.**

- Bloque root (`:17-28`): crear y `chown` `$OASIS_CLIENT_STATE_DIR` y `$OASIS_BANKING_DIR`.
- `persist_client_state()`: si `src/configs/oasis-config.json` es fichero regular (contenedor nuevo) → es el default
  de la imagen; deep-merge con `$OASIS_CLIENT_STATE_DIR/oasis-config.json` si existe (gana lo persistido; las
  claves nuevas de upstream entran por el default); escribir el resultado en el state dir y `ln -sfn` desde
  `src/configs/oasis-config.json`. Symlink `src/configs/wallet-addresses.json` → `$OASIS_BANKING_DIR/wallet-addresses.json`
  (sembrado con `{}`).
- `wire_wallet_config()` en `node -e` (sin `sed`): si `ECOIN_RPC_URL` está **definida** (aunque vacía) asigna
  `wallet.url/user/pass`; `OASIS_WALLET_FEE` opcional. **Guarda anti-remoto**: host ∈ {`ecoin-wallet`, `localhost`,
  `127.0.0.1`, `host.docker.internal`}; si no, error en log y `url=""`, salvo `ECOIN_RPC_ALLOW_REMOTE=i-know`.
  `OASIS_WALLET_PUB_ID`: si casa `^@[A-Za-z0-9+/]{43}=\.ed25519$` → `walletPub.pubId`; vacía → no toca; inválida → aviso.
  **Env manda** (lo tecleado en `/settings/wallet` se pisa al arrancar); escape: `OASIS_WALLET_WIRING=manual`.
  Nunca imprimir user/pass.
- `setup_oasis_config`: reescrito en node (misma semántica de `aiMod`), para no romper el symlink.
- Orden: `persist_client_state` → `wire_wallet_config` → `setup_oasis_config`. El cableado depende de
  `OASIS_CLIENT_STATE_DIR`, **no** de `OASIS_SKIP_AI_MODEL`.

### B. `docker-compose.yml` raíz, `.env.example` raíz, `package.json`

- `ecoin-wallet`: **sin `ports`** (RPC y P2P solo en `oasis-network`; P2P solo saliente; override documentado
  `7408:7408` para quien quiera entrante; el 12000 desaparece). `RPC_USER/RPC_PASS` desde `.env` raíz,
  `ECOIN_REQUIRE_CREDS: "1"`, healthcheck con `$$RPC_USER:$$RPC_PASS` y `-o /dev/null`, `mem_limit ${ECOIN_MEM_LIMIT:-512m}`,
  `logging 10m×3`, `stop_grace_period 2m`. Volumen **`external`**: `ecoin-data` → `name: o-sdk-client-ecoin-data`
  (sustituye a `ecoin-data-dev`; `down -v` no borra volúmenes externos).
- `oasis-client`: `ECOIN_RPC_URL=${ECOIN_RPC_URL-}` (vacía por defecto), `ECOIN_RPC_USER`, `ECOIN_RPC_PASS`,
  `OASIS_WALLET_PUB_ID`, `OASIS_WALLET_FEE`, `OASIS_BANKING_DIR=/app/state/banking`, `OASIS_CLIENT_STATE_DIR=/app/state`;
  volumen bind `./volumes-dev/client-state:/app/state`; `depends_on: ecoin-wallet: {condition: service_started, required: false}`.
  Verificar que el cliente arranca **sin** el perfil `ecoin` y sin que exista el volumen externo; si Compose
  falla, plan B documentado (`:-` en vez de `:?`, crear el volumen en `setup.sh`).
- `.env.example` raíz (versionado; `.gitignore` ya lo admite): `ECOIN_RPC_USER=`, `ECOIN_RPC_PASS=`, `ECOIN_RPC_URL=`,
  `OASIS_WALLET_PUB_ID=`, `COMPOSE_PROFILES=`, con comentarios de los dos modos.
- `package.json`: `ecoin:info|balance|address` sin credenciales en la línea (`ecoind` las lee de su conf);
  `ecoin:system` arreglado y **sin** volcar `rpcpassword`; `ecoin:build` antepone `ecoin:fetch-deb`
  (`bash ./ecoin/fetch-deb.sh`); `ecoin:up` = `ecoin-init.sh --ensure` + `up -d --wait ecoin-wallet`;
  nuevos `client:ecoin:init`, `client:wallet:backup`, `client:wallet:restore`, `client:ecoin:verify`;
  `downDELETEVOLS` y `cleanDELETEVOLS` pasan antes por `guard-destroy.sh`. Nombres existentes estables.

### C. `client/scripts/`

- `ecoin-init.sh` (idempotente; nunca pisa credenciales): genera `.env` raíz (user `oasis-<hex8>`, pass hex48),
  `docker volume create o-sdk-client-ecoin-data` con etiqueta `o-sdk.role=client-wallet`, `--mode address|own`
  (address: `COMPOSE_PROFILES=` y `ECOIN_RPC_URL=`; own: `COMPOSE_PROFILES=ecoin` y `ECOIN_RPC_URL=http://ecoin-wallet:7474`),
  `--ensure`, `--pub-id <feed>`.
- `backup-wallet.sh`: caliente (`backupwallet` → `docker cp` → sha256 contenedor == host → manifiesto con
  `getinfo.blocks` y direcciones) a `devops/backups/client-wallet/<TS>/`; `--cold`; `--restore <dir>` (aparta la
  actual a `wallet.dat.pre-restore-<TS>`, nunca sobrescribe); avisos: sin cifrar, material de claves, keypool.
  Parámetro `ECOIN_CONTAINER` (default `ecoin-wallet`) para el drill.
- `guard-destroy.sh`: lista qué sobrevive, exige escribir `BORRAR`, rehúsa si hay `wallet.dat` sin backup < 24 h.
- `ecoin-verify.sh`: comprueba los CA (RPC por DNS de servicio y no desde el host, credenciales ≠ por defecto,
  config cableada, exactamente 1 mensaje `wallet`, symlinks).
- `setup.sh` (`:8,13,20`) e `import-identity.sh` (`:113`): dejan de tocar `ecoin-data`; `setup.sh` crea
  `client-state/banking`; `import-identity.sh --force` aparta `client-state/banking/wallet-addresses.json`
  (el mapa va por feed). `backup-keys.sh`: aviso final si existe el volumen de la cartera.
- `client/docker-compose.drill.yml` (+ excepción en `client/.gitignore` si hace falta): proyecto `o-sdk-drill`,
  contenedores `oasis-client-drill` / `ecoin-wallet-drill`, puertos `3100:3000` y `8108:8008`, volúmenes en
  `./volumes-dev/drill/*`, volumen externo `o-sdk-drill-ecoin-data`, sin GPU, `OASIS_SKIP_AI_MODEL=true`.
  Identidad **desechable**, `gossip.json` vacío, sin invite: no ensucia la red.

### D. Docs y gobierno

`docs/CLIENT-PROTOCOL.md` (sección «ECOin en el cliente»: dos niveles, tabla env → entrypoint → config,
«env manda», estado persistente, backup/restore, avisos: publicación al abrir `/`, mensajes irreversibles,
nunca el ecoind del VPS, prohibido `prune --volumes`; corregir puertos `:33-44` y `volumes-dev/` `:55`),
`client/README.md`, `CHANGELOG.md`, `docs/PUB/UPGRADE-PROTOCOL.md` §3 (una línea: funciones nuevas del
entrypoint; `src/` sigue con 4 guards), estado de WP-O103 en `plan/BACKLOG.md`.

## Verificación (drill D con identidad desechable; R = identidad real)

1. `ecoin:fetch-deb` OK; build.  2. D: `docker port` vacío; host no alcanza 7474/7408/12000; RPC 200 por DNS de
servicio desde `oasis-client-drill`; `ecoinrpc` → 401.  3. D: config cableada y symlinks.  4. D: `/wallet` saldo 0
y dirección; publicar **una vez**; 1 mensaje `wallet`.  5. D: `--force-recreate` y rebuild → sobreviven tema,
wallet cfg, mapa; sigue 1 mensaje.  6. D: `down -v` con guard → `wallet.dat` intacta.  7. D: backup → volumen
nuevo (otra dirección) → restore → `ismine: true`.  8. D: sin perfil → arranca, `/banking` sin latencia, `skipped`.
9. D: guarda anti-remoto.  **10. PUERTA: confirmación expresa del custodio** antes de R (elige: dirección manual
o automática).  11. R: backup de claves → init → `ecoin:up` → **backup de cartera antes de publicar** → publicar →
1 mensaje `wallet` en el feed scriptorium y replicado al pub.  12. R: `OASIS_WALLET_PUB_ID` = bot-2 → botón de
claim visible; el claim real es otra confirmación (mensaje irreversible).

## CA

RPC por DNS de servicio e inaccesible desde el host · credenciales generadas ≠ `ecoinrpc`, en `.env` ignorado ·
`ECOIN_RPC_*` vivas tras recreate · exactamente 1 `wallet` tras N recreates · config GUI y banking sobreviven a
recreate/rebuild · backup sha256 y restore `ismine:true` · el cliente arranca sin perfil · `src/` sin diff ·
pub/HUB/bot-2 sin regresión (no definen `OASIS_CLIENT_STATE_DIR`).

**Hostil-omite**: URL remota → `url=""` · `RPC_PASS` vacío o `ecoinrpc` → ecoind no arranca · `down -v` → cartera
intacta · `downDELETEVOLS` sin backup reciente → rechazo · `import-identity --force` no toca la cartera ·
sin perfil → ningún RPC saliente.

## Riesgos

1.1.3 (autodetección en clientes, `publishActivity` definida, esquema de config) · tamaño/tiempo de sync en
portátil (medido en VPS: ~50 MB, 13 min) · volumen nombrado en WSL2 se pierde con factory reset → backup al
host obligatorio · semántica de `required:false` + volumen externo con el perfil apagado (verificar) ·
`.env` raíz compartido (el pub usa `--env-file` propio).
